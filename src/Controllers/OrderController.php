<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class OrderController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'orders');

        $pdo = Database::pdo();
        $orders = $pdo->query(
            'SELECT o.*, c.name AS customer_name FROM orders o
             JOIN customers c ON c.id = o.customer_id
             ORDER BY o.order_date DESC'
        )->fetchAll();

        Response::success(array_map(fn ($order) => self::formatOrder($pdo, $order), $orders));
    }

    public static function store(Request $req): void
    {
        Rbac::authorize($req->user, 'orders', 'create');

        $customerId = (int) ($req->body['customer_id'] ?? 0);
        $notes = trim((string) ($req->body['notes'] ?? ''));
        $items = $req->body['items'] ?? [];

        if ($customerId <= 0) {
            Response::error('Pelanggan wajib dipilih', 422);
        }
        if (!is_array($items) || $items === []) {
            Response::error('Minimal satu menu harus dipilih', 422);
        }

        $pdo = Database::pdo();
        $customer = $pdo->prepare('SELECT id FROM customers WHERE id = ?');
        $customer->execute([$customerId]);
        if (!$customer->fetch()) {
            Response::error('Pelanggan tidak ditemukan', 404);
        }

        $parsedItems = self::parseItems($pdo, $items);
        $totalAmount = array_sum(array_column($parsedItems, 'subtotal'));
        $orderNumber = self::generateOrderNumber($pdo);

        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'INSERT INTO orders (order_number, customer_id, status, total_amount, payment_status, notes, created_by)
                 VALUES (?, ?, ?, ?, ?, ?, ?)'
            )->execute([
                $orderNumber,
                $customerId,
                'confirmed',
                $totalAmount,
                'pending',
                $notes !== '' ? $notes : null,
                $req->user['id'] ?? null,
            ]);

            $orderId = (int) $pdo->lastInsertId();
            $itemStmt = $pdo->prepare(
                'INSERT INTO order_items (order_id, recipe_id, portions, price, subtotal) VALUES (?, ?, ?, ?, ?)'
            );
            $productionStmt = $pdo->prepare(
                'INSERT INTO production_schedules (order_id, recipe_name, portions, scheduled_date, status, assigned_to)
                 VALUES (?, ?, ?, NOW(), ?, ?)'
            );
            $assignedTo = (string) ($req->user['name'] ?? '');

            foreach ($parsedItems as $item) {
                $itemStmt->execute([
                    $orderId,
                    $item['recipe_id'],
                    $item['portions'],
                    $item['price'],
                    $item['subtotal'],
                ]);

                $productionStmt->execute([
                    $orderId,
                    $item['recipe_name'],
                    $item['portions'],
                    'scheduled',
                    $assignedTo,
                ]);

                self::deductStock($pdo, $item['recipe_id'], $item['portions'], $orderId, $req->user['id'] ?? null);
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $order = $pdo->prepare(
            'SELECT o.*, c.name AS customer_name FROM orders o
             JOIN customers c ON c.id = o.customer_id WHERE o.id = ?'
        );
        $order->execute([$orderId]);

        Response::success(self::formatOrder($pdo, $order->fetch()), 201);
    }

    private static function parseItems(\PDO $pdo, array $items): array
    {
        $parsed = [];

        foreach ($items as $item) {
            if (!is_array($item)) {
                Response::error('Format item pesanan tidak valid', 422);
            }

            $recipeId = (int) ($item['recipe_id'] ?? 0);
            $portions = (int) ($item['portions'] ?? 0);

            if ($recipeId <= 0 || $portions <= 0) {
                Response::error('Menu dan porsi harus valid', 422);
            }

            $recipeStmt = $pdo->prepare('SELECT id, name, price, servings FROM recipes WHERE id = ?');
            $recipeStmt->execute([$recipeId]);
            $recipe = $recipeStmt->fetch();

            if (!$recipe) {
                Response::error('Resep tidak ditemukan', 404);
            }

            $price = (float) $recipe['price'];
            $parsed[] = [
                'recipe_id' => $recipeId,
                'recipe_name' => $recipe['name'],
                'portions' => $portions,
                'price' => $price,
                'subtotal' => $price * $portions,
                'servings' => max((int) $recipe['servings'], 1),
            ];
        }

        self::validateStock($pdo, $parsed);

        return $parsed;
    }

    private static function validateStock(\PDO $pdo, array $items): void
    {
        $required = [];

        foreach ($items as $item) {
            $stmt = $pdo->prepare(
                'SELECT ri.ingredient_id, ri.quantity, i.name, i.stock, i.unit
                 FROM recipe_ingredients ri
                 JOIN ingredients i ON i.id = ri.ingredient_id
                 WHERE ri.recipe_id = ?'
            );
            $stmt->execute([$item['recipe_id']]);
            $ingredients = $stmt->fetchAll();

            foreach ($ingredients as $ing) {
                $need = (float) $ing['quantity'] * ($item['portions'] / $item['servings']);
                $id = (int) $ing['ingredient_id'];
                $required[$id]['need'] = ($required[$id]['need'] ?? 0) + $need;
                $required[$id]['name'] = $ing['name'];
                $required[$id]['stock'] = (float) $ing['stock'];
                $required[$id]['unit'] = $ing['unit'];
            }
        }

        foreach ($required as $data) {
            if ($data['need'] > $data['stock']) {
                Response::error(
                    sprintf(
                        'Stok %s tidak cukup (butuh %.2f %s, tersedia %.2f %s)',
                        $data['name'],
                        $data['need'],
                        $data['unit'],
                        $data['stock'],
                        $data['unit']
                    ),
                    422
                );
            }
        }
    }

    private static function deductStock(\PDO $pdo, int $recipeId, int $portions, int $orderId, ?int $userId): void
    {
        $recipe = $pdo->prepare('SELECT servings FROM recipes WHERE id = ?');
        $recipe->execute([$recipeId]);
        $servings = max((int) ($recipe->fetch()['servings'] ?? 1), 1);

        $stmt = $pdo->prepare(
            'SELECT ingredient_id, quantity FROM recipe_ingredients WHERE recipe_id = ?'
        );
        $stmt->execute([$recipeId]);
        $rows = $stmt->fetchAll();

        $updateStock = $pdo->prepare('UPDATE ingredients SET stock = stock - ? WHERE id = ?');
        $logStmt = $pdo->prepare(
            'INSERT INTO stock_logs (ingredient_id, change_qty, type, reference_type, reference_id, created_by)
             VALUES (?, ?, ?, ?, ?, ?)'
        );

        foreach ($rows as $row) {
            $qty = (float) $row['quantity'] * ($portions / $servings);
            if ($qty <= 0) {
                continue;
            }

            $updateStock->execute([$qty, $row['ingredient_id']]);
            $logStmt->execute([
                $row['ingredient_id'],
                -$qty,
                'out',
                'order',
                $orderId,
                $userId,
            ]);
        }
    }

    private static function generateOrderNumber(\PDO $pdo): string
    {
        $prefix = 'ORD-' . date('Ymd') . '-';
        $stmt = $pdo->prepare('SELECT COUNT(*) FROM orders WHERE order_number LIKE ?');
        $stmt->execute([$prefix . '%']);
        $count = (int) $stmt->fetchColumn();

        return $prefix . str_pad((string) ($count + 1), 3, '0', STR_PAD_LEFT);
    }

    private static function formatOrder(\PDO $pdo, array $order): array
    {
        $itemStmt = $pdo->prepare(
            'SELECT oi.*, r.name AS recipe_name FROM order_items oi
             JOIN recipes r ON r.id = oi.recipe_id
             WHERE oi.order_id = ?'
        );
        $itemStmt->execute([$order['id']]);
        $items = $itemStmt->fetchAll();

        return [
            'id' => (int) $order['id'],
            'order_number' => $order['order_number'],
            'customer_id' => (int) $order['customer_id'],
            'customer_name' => $order['customer_name'],
            'status' => $order['status'],
            'total_amount' => (float) $order['total_amount'],
            'payment_status' => $order['payment_status'],
            'order_date' => $order['order_date'],
            'notes' => $order['notes'] ?? '',
            'items' => array_map(fn ($i) => [
                'recipe_id' => (int) $i['recipe_id'],
                'recipe_name' => $i['recipe_name'],
                'portions' => (int) $i['portions'],
                'price' => (float) $i['price'],
            ], $items),
        ];
    }
}
