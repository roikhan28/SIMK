<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class IngredientController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'inventory');

        $rows = Database::pdo()->query(
            'SELECT id, name, unit, stock, min_stock, price FROM ingredients ORDER BY id'
        )->fetchAll();

        Response::success(array_map(fn ($r) => self::format($r), $rows));
    }

    public static function restock(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'inventory', 'update');

        $id = (int) ($params['id'] ?? 0);
        $quantity = (float) ($req->body['quantity'] ?? 0);
        $notes = trim((string) ($req->body['notes'] ?? ''));

        if ($id <= 0) {
            Response::error('ID bahan tidak valid', 422);
        }
        if ($quantity <= 0) {
            Response::error('Jumlah restock harus lebih dari 0', 422);
        }

        $pdo = Database::pdo();
        $stmt = $pdo->prepare('SELECT id, name, unit, stock, min_stock, price FROM ingredients WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        if (!$row) {
            Response::error('Bahan tidak ditemukan', 404);
        }

        $newStock = (float) $row['stock'] + $quantity;

        $pdo->beginTransaction();
        try {
            $pdo->prepare('UPDATE ingredients SET stock = ? WHERE id = ?')->execute([$newStock, $id]);
            $pdo->prepare(
                'INSERT INTO stock_logs (ingredient_id, change_qty, type, reference_type, notes, created_by)
                 VALUES (?, ?, ?, ?, ?, ?)'
            )->execute([
                $id,
                $quantity,
                'in',
                'restock',
                $notes !== '' ? $notes : null,
                $req->user['id'] ?? null,
            ]);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $row['stock'] = $newStock;
        Response::success(self::format($row));
    }

    private static function format(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'unit' => $r['unit'],
            'stock' => (float) $r['stock'],
            'min_stock' => (float) $r['min_stock'],
            'price' => (float) $r['price'],
        ];
    }
}
