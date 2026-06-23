<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class PaymentController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'payments');

        $rows = Database::pdo()->query(
            'SELECT p.*, o.order_number, c.name AS customer_name
             FROM payments p
             JOIN orders o ON o.id = p.order_id
             JOIN customers c ON c.id = o.customer_id
             ORDER BY p.paid_at DESC'
        )->fetchAll();

        Response::success(array_map(fn ($r) => self::format($r), $rows));
    }

    public static function store(Request $req): void
    {
        Rbac::authorize($req->user, 'payments', 'create');

        $orderId = (int) ($req->body['order_id'] ?? 0);
        $method = trim((string) ($req->body['method'] ?? 'Transfer Bank'));

        if ($orderId <= 0) {
            Response::error('Pesanan wajib dipilih', 422);
        }
        if ($method === '') {
            Response::error('Metode pembayaran wajib diisi', 422);
        }

        $pdo = Database::pdo();
        $orderStmt = $pdo->prepare(
            'SELECT id, total_amount, payment_status FROM orders WHERE id = ?'
        );
        $orderStmt->execute([$orderId]);
        $order = $orderStmt->fetch();

        if (!$order) {
            Response::error('Pesanan tidak ditemukan', 404);
        }
        if ($order['payment_status'] === 'paid') {
            Response::error('Pesanan sudah dibayar', 422);
        }

        $amount = array_key_exists('amount', $req->body)
            ? (float) $req->body['amount']
            : (float) $order['total_amount'];

        if ($amount <= 0) {
            Response::error('Jumlah pembayaran tidak valid', 422);
        }

        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'INSERT INTO payments (order_id, amount, method, status, created_by) VALUES (?, ?, ?, ?, ?)'
            )->execute([
                $orderId,
                $amount,
                $method,
                'confirmed',
                $req->user['id'] ?? null,
            ]);

            $paymentId = (int) $pdo->lastInsertId();
            $pdo->prepare("UPDATE orders SET payment_status = 'paid' WHERE id = ?")->execute([$orderId]);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $stmt = $pdo->prepare(
            'SELECT p.*, o.order_number, c.name AS customer_name
             FROM payments p
             JOIN orders o ON o.id = p.order_id
             JOIN customers c ON c.id = o.customer_id
             WHERE p.id = ?'
        );
        $stmt->execute([$paymentId]);

        Response::success(self::format($stmt->fetch()), 201);
    }

    private static function format(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'order_id' => (int) $r['order_id'],
            'order_number' => $r['order_number'],
            'customer_name' => $r['customer_name'],
            'amount' => (float) $r['amount'],
            'method' => $r['method'],
            'status' => $r['status'],
            'paid_at' => $r['paid_at'],
        ];
    }
}
