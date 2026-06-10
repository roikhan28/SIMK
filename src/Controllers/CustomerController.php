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

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'phone' => $r['phone'],
            'email' => $r['email'] ?? '',
            'address' => $r['address'] ?? '',
            'order_count' => (int) $r['order_count'],
        ], $rows));
    }
}
