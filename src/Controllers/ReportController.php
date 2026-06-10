<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class ReportController
{
    public static function show(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'reports');

        $type = $params['type'] ?? 'revenue';
        $period = $req->query['period'] ?? 'month';

        match ($type) {
            'sales' => self::sales($period),
            'orders' => self::orders($period),
            'inventory' => self::inventory(),
            'ingredients' => self::ingredients($period),
            default => self::revenue($period),
        };
    }

    private static function sales(string $period): void
    {
        $pdo = Database::pdo();
        $rows = $pdo->query(
            "SELECT r.name AS menu, SUM(oi.portions) AS qty, SUM(oi.subtotal) AS revenue
             FROM order_items oi
             JOIN recipes r ON r.id = oi.recipe_id
             JOIN orders o ON o.id = oi.order_id
             WHERE o.status NOT IN ('draft','cancelled')
             GROUP BY r.id ORDER BY revenue DESC LIMIT 10"
        )->fetchAll();

        $total = array_sum(array_column($rows, 'revenue'));

        Response::json([
            'title' => 'Laporan Penjualan',
            'rows' => array_map(fn ($r) => [
                'menu' => $r['menu'],
                'qty' => (int) $r['qty'],
                'revenue' => (float) $r['revenue'],
            ], $rows),
            'total' => (float) $total,
        ]);
    }

    private static function orders(string $period): void
    {
        $pdo = Database::pdo();
        $rows = $pdo->query(
            "SELECT status, COUNT(*) AS count FROM orders GROUP BY status"
        )->fetchAll();

        $labels = [
            'delivered' => 'Selesai',
            'inProduction' => 'Produksi',
            'confirmed' => 'Dikonfirmasi',
            'cancelled' => 'Dibatalkan',
            'ready' => 'Siap',
            'draft' => 'Draft',
        ];

        $mapped = [];
        foreach ($rows as $r) {
            $mapped[] = [
                'status' => $labels[$r['status']] ?? $r['status'],
                'count' => (int) $r['count'],
            ];
        }

        Response::json([
            'title' => 'Laporan Pesanan',
            'rows' => $mapped,
            'total' => array_sum(array_column($mapped, 'count')),
        ]);
    }

    private static function inventory(): void
    {
        $rows = Database::pdo()->query(
            'SELECT name AS bahan, stock AS stok, unit, min_stock FROM ingredients ORDER BY name'
        )->fetchAll();

        Response::json([
            'title' => 'Laporan Inventori',
            'rows' => array_map(fn ($r) => [
                'bahan' => $r['bahan'],
                'stok' => (float) $r['stok'],
                'unit' => $r['unit'],
                'status' => (float) $r['stok'] <= (float) $r['min_stock'] ? 'Rendah' : 'Aman',
            ], $rows),
            'total' => 0,
        ]);
    }

    private static function ingredients(string $period): void
    {
        $rows = Database::pdo()->query(
            "SELECT i.name AS bahan, ABS(SUM(sl.change_qty)) AS used, i.unit,
                    ABS(SUM(sl.change_qty)) * i.price AS cost
             FROM stock_logs sl
             JOIN ingredients i ON i.id = sl.ingredient_id
             WHERE sl.type = 'out'
             GROUP BY i.id ORDER BY cost DESC LIMIT 10"
        )->fetchAll();

        Response::json([
            'title' => 'Laporan Penggunaan Bahan',
            'rows' => array_map(fn ($r) => [
                'bahan' => $r['bahan'],
                'used' => (float) $r['used'],
                'unit' => $r['unit'],
                'cost' => (float) $r['cost'],
            ], $rows),
            'total' => (float) array_sum(array_column($rows, 'cost')),
        ]);
    }

    private static function revenue(string $period): void
    {
        $rows = Database::pdo()->query(
            "SELECT DATE_FORMAT(paid_at, '%b') AS bulan, SUM(amount) AS pendapatan
             FROM payments WHERE status = 'confirmed'
             GROUP BY DATE_FORMAT(paid_at, '%Y-%m'), bulan
             ORDER BY DATE_FORMAT(paid_at, '%Y-%m') DESC LIMIT 6"
        )->fetchAll();

        $rows = array_reverse($rows);
        $total = array_sum(array_column($rows, 'pendapatan'));

        Response::json([
            'title' => 'Analisis Pendapatan',
            'rows' => array_map(fn ($r) => [
                'bulan' => $r['bulan'],
                'pendapatan' => (float) $r['pendapatan'],
            ], $rows),
            'total' => (float) $total,
        ]);
    }
}
