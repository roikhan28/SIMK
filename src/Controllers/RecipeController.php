<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class RecipeController
{
    public static function categories(Request $req): void
    {
        Rbac::authorize($req->user, 'recipes');

        $rows = Database::pdo()->query(
            'SELECT id, name, description FROM recipe_categories ORDER BY id'
        )->fetchAll();

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'description' => $r['description'] ?? '',
        ], $rows));
    }

    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'recipes');

        $rows = Database::pdo()->query(
            'SELECT r.*, c.name AS category_name FROM recipes r
             JOIN recipe_categories c ON c.id = r.category_id
             ORDER BY r.id'
        )->fetchAll();

        Response::success(array_map(fn ($r) => [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'category_id' => (int) $r['category_id'],
            'category_name' => $r['category_name'],
            'price' => (float) $r['price'],
            'servings' => (int) $r['servings'],
            'description' => $r['description'] ?? '',
        ], $rows));
    }
}
