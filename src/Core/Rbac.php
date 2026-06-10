<?php

declare(strict_types=1);

namespace Simk\Core;

class Rbac
{
    private const MATRIX = [
        'admin' => ['users', 'customers', 'orders', 'recipes', 'inventory', 'production', 'payments', 'reports', 'dashboard'],
        'kasir' => ['customers', 'orders', 'recipes', 'inventory', 'production', 'payments', 'dashboard'],
        'staff_produksi' => ['orders', 'recipes', 'inventory', 'production', 'dashboard'],
    ];

    public static function can(string $role, string $resource, string $action = 'read'): bool
    {
        $allowed = self::MATRIX[$role] ?? [];
        if (!in_array($resource, $allowed, true)) {
            return false;
        }

        if ($action === 'read') {
            return true;
        }

        return match ($role) {
            'admin' => true,
            'kasir' => in_array($resource, ['customers', 'orders', 'payments'], true),
            'staff_produksi' => $resource === 'production' && $action === 'update',
            default => false,
        };
    }

    public static function authorize(?array $user, string $resource, string $action = 'read'): void
    {
        if ($user === null) {
            Response::error('Unauthorized', 401);
        }
        if (!self::can($user['role'], $resource, $action)) {
            Response::error('Forbidden', 403);
        }
    }
}
