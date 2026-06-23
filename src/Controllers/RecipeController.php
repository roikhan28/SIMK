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

        Response::success(array_map(fn ($r) => self::formatCategory($r), $rows));
    }

    public static function storeCategory(Request $req): void
    {
        Rbac::authorize($req->user, 'recipes', 'create');

        $name = trim((string) ($req->body['name'] ?? ''));
        $description = trim((string) ($req->body['description'] ?? ''));

        if ($name === '') {
            Response::error('Nama kategori wajib diisi', 422);
        }

        $pdo = Database::pdo();
        $pdo->prepare('INSERT INTO recipe_categories (name, description) VALUES (?, ?)')
            ->execute([$name, $description !== '' ? $description : null]);

        $id = (int) $pdo->lastInsertId();
        $stmt = $pdo->prepare('SELECT id, name, description FROM recipe_categories WHERE id = ?');
        $stmt->execute([$id]);

        Response::success(self::formatCategory($stmt->fetch()), 201);
    }

    public static function updateCategory(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'recipes', 'update');

        $id = (int) ($params['id'] ?? 0);
        if ($id <= 0) {
            Response::error('ID kategori tidak valid', 422);
        }

        $pdo = Database::pdo();
        $stmt = $pdo->prepare('SELECT id, name, description FROM recipe_categories WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        if (!$row) {
            Response::error('Kategori tidak ditemukan', 404);
        }

        $name = trim((string) ($req->body['name'] ?? $row['name']));
        $description = trim((string) ($req->body['description'] ?? ($row['description'] ?? '')));

        if ($name === '') {
            Response::error('Nama kategori wajib diisi', 422);
        }

        $pdo->prepare('UPDATE recipe_categories SET name = ?, description = ? WHERE id = ?')
            ->execute([$name, $description !== '' ? $description : null, $id]);

        $updated = $pdo->prepare('SELECT id, name, description FROM recipe_categories WHERE id = ?');
        $updated->execute([$id]);

        Response::success(self::formatCategory($updated->fetch()));
    }

    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'recipes');

        $rows = Database::pdo()->query(
            'SELECT r.*, c.name AS category_name FROM recipes r
             JOIN recipe_categories c ON c.id = r.category_id
             ORDER BY r.id'
        )->fetchAll();

        Response::success(array_map(fn ($r) => self::formatRecipe($r), $rows));
    }

    public static function show(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'recipes');

        $id = (int) ($params['id'] ?? 0);
        $row = self::findRecipe($id);
        if (!$row) {
            Response::error('Resep tidak ditemukan', 404);
        }

        Response::success(self::formatRecipeDetail($row));
    }

    public static function store(Request $req): void
    {
        Rbac::authorize($req->user, 'recipes', 'create');

        $payload = self::validateRecipePayload($req->body);
        $pdo = Database::pdo();

        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'INSERT INTO recipes (category_id, name, description, price, servings) VALUES (?, ?, ?, ?, ?)'
            )->execute([
                $payload['category_id'],
                $payload['name'],
                $payload['description'],
                $payload['price'],
                $payload['servings'],
            ]);

            $id = (int) $pdo->lastInsertId();
            self::syncIngredients($pdo, $id, $payload['ingredients']);
            self::syncSteps($pdo, $id, $payload['steps']);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $row = self::findRecipe($id);
        Response::success(self::formatRecipeDetail($row), 201);
    }

    public static function update(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'recipes', 'update');

        $id = (int) ($params['id'] ?? 0);
        if ($id <= 0) {
            Response::error('ID resep tidak valid', 422);
        }

        if (!self::findRecipe($id)) {
            Response::error('Resep tidak ditemukan', 404);
        }

        $payload = self::validateRecipePayload($req->body);
        $pdo = Database::pdo();

        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'UPDATE recipes SET category_id = ?, name = ?, description = ?, price = ?, servings = ? WHERE id = ?'
            )->execute([
                $payload['category_id'],
                $payload['name'],
                $payload['description'],
                $payload['price'],
                $payload['servings'],
                $id,
            ]);

            $pdo->prepare('DELETE FROM recipe_ingredients WHERE recipe_id = ?')->execute([$id]);
            $pdo->prepare('DELETE FROM recipe_steps WHERE recipe_id = ?')->execute([$id]);
            self::syncIngredients($pdo, $id, $payload['ingredients']);
            self::syncSteps($pdo, $id, $payload['steps']);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $row = self::findRecipe($id);
        Response::success(self::formatRecipeDetail($row));
    }

    private static function validateRecipePayload(array $body): array
    {
        $name = trim((string) ($body['name'] ?? ''));
        $categoryId = (int) ($body['category_id'] ?? 0);
        $price = (float) ($body['price'] ?? 0);
        $servings = (int) ($body['servings'] ?? 1);
        $description = trim((string) ($body['description'] ?? ''));

        if ($name === '') {
            Response::error('Nama resep wajib diisi', 422);
        }
        if ($categoryId <= 0) {
            Response::error('Kategori wajib dipilih', 422);
        }
        if ($price < 0) {
            Response::error('Harga tidak valid', 422);
        }
        if ($servings < 1) {
            Response::error('Jumlah porsi minimal 1', 422);
        }

        $pdo = Database::pdo();
        $cat = $pdo->prepare('SELECT id FROM recipe_categories WHERE id = ?');
        $cat->execute([$categoryId]);
        if (!$cat->fetch()) {
            Response::error('Kategori tidak ditemukan', 422);
        }

        $ingredients = [];
        foreach ($body['ingredients'] ?? [] as $item) {
            if (!is_array($item)) {
                continue;
            }
            $ingredientId = (int) ($item['ingredient_id'] ?? 0);
            $quantity = (float) ($item['quantity'] ?? 0);
            if ($ingredientId <= 0 || $quantity <= 0) {
                continue;
            }
            $ingredients[] = ['ingredient_id' => $ingredientId, 'quantity' => $quantity];
        }

        $steps = [];
        foreach ($body['steps'] ?? [] as $index => $step) {
            $instruction = trim(is_string($step) ? $step : (string) ($step['instruction'] ?? ''));
            if ($instruction !== '') {
                $steps[] = $instruction;
            }
        }

        return [
            'name' => $name,
            'category_id' => $categoryId,
            'price' => $price,
            'servings' => $servings,
            'description' => $description !== '' ? $description : null,
            'ingredients' => $ingredients,
            'steps' => $steps,
        ];
    }

    private static function syncIngredients(\PDO $pdo, int $recipeId, array $ingredients): void
    {
        if ($ingredients === []) {
            return;
        }

        $stmt = $pdo->prepare(
            'INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity) VALUES (?, ?, ?)'
        );
        foreach ($ingredients as $item) {
            $check = $pdo->prepare('SELECT id FROM ingredients WHERE id = ?');
            $check->execute([$item['ingredient_id']]);
            if (!$check->fetch()) {
                Response::error('Bahan tidak ditemukan', 422);
            }
            $stmt->execute([$recipeId, $item['ingredient_id'], $item['quantity']]);
        }
    }

    private static function syncSteps(\PDO $pdo, int $recipeId, array $steps): void
    {
        if ($steps === []) {
            return;
        }

        $stmt = $pdo->prepare(
            'INSERT INTO recipe_steps (recipe_id, step_number, instruction) VALUES (?, ?, ?)'
        );
        foreach ($steps as $index => $instruction) {
            $stmt->execute([$recipeId, $index + 1, $instruction]);
        }
    }

    private static function findRecipe(int $id): ?array
    {
        $stmt = Database::pdo()->prepare(
            'SELECT r.*, c.name AS category_name FROM recipes r
             JOIN recipe_categories c ON c.id = r.category_id
             WHERE r.id = ?'
        );
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return $row ?: null;
    }

    private static function formatCategory(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'description' => $r['description'] ?? '',
        ];
    }

    private static function formatRecipe(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'name' => $r['name'],
            'category_id' => (int) $r['category_id'],
            'category_name' => $r['category_name'] ?? '',
            'price' => (float) $r['price'],
            'servings' => (int) $r['servings'],
            'description' => $r['description'] ?? '',
        ];
    }

    private static function formatRecipeDetail(array $r): array
    {
        $pdo = Database::pdo();
        $id = (int) $r['id'];

        $ingStmt = $pdo->prepare(
            'SELECT ri.ingredient_id, ri.quantity, i.name AS ingredient_name, i.unit
             FROM recipe_ingredients ri
             JOIN ingredients i ON i.id = ri.ingredient_id
             WHERE ri.recipe_id = ?
             ORDER BY ri.id'
        );
        $ingStmt->execute([$id]);
        $ingredients = array_map(fn ($row) => [
            'ingredient_id' => (int) $row['ingredient_id'],
            'ingredient_name' => $row['ingredient_name'],
            'unit' => $row['unit'],
            'quantity' => (float) $row['quantity'],
        ], $ingStmt->fetchAll());

        $stepStmt = $pdo->prepare(
            'SELECT step_number, instruction FROM recipe_steps WHERE recipe_id = ? ORDER BY step_number'
        );
        $stepStmt->execute([$id]);
        $steps = array_map(fn ($row) => [
            'step_number' => (int) $row['step_number'],
            'instruction' => $row['instruction'],
        ], $stepStmt->fetchAll());

        return array_merge(self::formatRecipe($r), [
            'ingredients' => $ingredients,
            'steps' => $steps,
        ]);
    }
}
