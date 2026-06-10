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

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'order_id' => (int) $r['order_id'],
            'order_number' => $r['order_number'],
            'customer_name' => $r['customer_name'],
            'amount' => (float) $r['amount'],
            'method' => $r['method'],
            'status' => $r['status'],
            'paid_at' => $r['paid_at'],
        ], $rows));
    }
}
