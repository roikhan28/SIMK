<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class ProductionController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'production');

        $rows = Database::pdo()->query(
            'SELECT ps.*, o.order_number FROM production_schedules ps
             JOIN orders o ON o.id = ps.order_id
             ORDER BY ps.scheduled_date DESC'
        )->fetchAll();

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'order_id' => (int) $r['order_id'],
            'order_number' => $r['order_number'],
            'recipe_name' => $r['recipe_name'],
            'portions' => (int) $r['portions'],
            'scheduled_date' => $r['scheduled_date'],
            'status' => $r['status'],
            'assigned_to' => $r['assigned_to'] ?? '',
        ], $rows));
    }
}
