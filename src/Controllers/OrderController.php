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

        $itemStmt = $pdo->prepare(
            'SELECT oi.*, r.name AS recipe_name FROM order_items oi
             JOIN recipes r ON r.id = oi.recipe_id
             WHERE oi.order_id = ?'
        );

        $result = [];
        foreach ($orders as $order) {
            $itemStmt->execute([$order['id']]);
            $items = $itemStmt->fetchAll();

            $result[] = [
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

        Response::success($result);
    }
}
