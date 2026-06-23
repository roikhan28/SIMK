<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class CustomerController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'customers');

        $rows = Database::pdo()->query(
            'SELECT c.*, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
             FROM customers c ORDER BY c.id'
        )->fetchAll();

        Response::success(array_map(fn ($r) => self::format($r), $rows));
    }

    public static function store(Request $req): void
    {
        Rbac::authorize($req->user, 'customers', 'create');

        $name = trim((string) ($req->body['name'] ?? ''));
        $phone = trim((string) ($req->body['phone'] ?? ''));
        $email = trim((string) ($req->body['email'] ?? ''));
        $address = trim((string) ($req->body['address'] ?? ''));

        if ($name === '') {
            Response::error('Nama pelanggan wajib diisi', 422);
        }
        if ($phone === '') {
            Response::error('Nomor telepon wajib diisi', 422);
        }

        $pdo = Database::pdo();
        $pdo->prepare('INSERT INTO customers (name, phone, email, address) VALUES (?, ?, ?, ?)')
            ->execute([$name, $phone, $email !== '' ? $email : '', $address !== '' ? $address : null]);

        $id = (int) $pdo->lastInsertId();
        $stmt = $pdo->prepare(
            'SELECT c.*, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
             FROM customers c WHERE c.id = ?'
        );
        $stmt->execute([$id]);

        Response::success(self::format($stmt->fetch()), 201);
    }

    public static function update(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'customers', 'update');

        $id = (int) ($params['id'] ?? 0);
        if ($id <= 0) {
            Response::error('ID pelanggan tidak valid', 422);
        }

        $pdo = Database::pdo();
        $stmt = $pdo->prepare('SELECT * FROM customers WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        if (!$row) {
            Response::error('Pelanggan tidak ditemukan', 404);
        }

        $name = trim((string) ($req->body['name'] ?? $row['name']));
        $phone = trim((string) ($req->body['phone'] ?? $row['phone']));
        $email = trim((string) ($req->body['email'] ?? ($row['email'] ?? '')));
        $address = trim((string) ($req->body['address'] ?? ($row['address'] ?? '')));

        if ($name === '') {
            Response::error('Nama pelanggan wajib diisi', 422);
        }
        if ($phone === '') {
            Response::error('Nomor telepon wajib diisi', 422);
        }

        $pdo->prepare('UPDATE customers SET name = ?, phone = ?, email = ?, address = ? WHERE id = ?')
            ->execute([
                $name,
                $phone,
                $email !== '' ? $email : '',
                $address !== '' ? $address : null,
                $id,
            ]);

        $updated = $pdo->prepare(
            'SELECT c.*, (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.id) AS order_count
             FROM customers c WHERE c.id = ?'
        );
        $updated->execute([$id]);

        Response::success(self::format($updated->fetch()));
    }

    private static function format(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'phone' => $r['phone'],
            'email' => $r['email'] ?? '',
            'address' => $r['address'] ?? '',
            'order_count' => (int) ($r['order_count'] ?? 0),
        ];
    }
}
