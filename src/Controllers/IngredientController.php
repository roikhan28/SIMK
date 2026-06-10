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

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'unit' => $r['unit'],
            'stock' => (float) $r['stock'],
            'min_stock' => (float) $r['min_stock'],
            'price' => (float) $r['price'],
        ], $rows));
    }
}
