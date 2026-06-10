<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class DashboardController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'dashboard');

        $pdo = Database::pdo();

        $totalOrders = (int) $pdo->query('SELECT COUNT(*) FROM orders')->fetchColumn();
        $totalRevenue = (float) $pdo->query(
            "SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'confirmed'"
        )->fetchColumn();
        $lowStockCount = (int) $pdo->query(
            'SELECT COUNT(*) FROM ingredients WHERE stock <= min_stock'
        )->fetchColumn();
        $todayProduction = (int) $pdo->query(
            "SELECT COUNT(*) FROM production_schedules WHERE DATE(scheduled_date) = CURDATE()"
        )->fetchColumn();
        $activeOrders = (int) $pdo->query(
            "SELECT COUNT(*) FROM orders WHERE status IN ('confirmed','inProduction','ready')"
        )->fetchColumn();
        $pendingPayments = (int) $pdo->query(
            "SELECT COUNT(*) FROM orders WHERE payment_status = 'pending'"
        )->fetchColumn();
        $todayOrders = (int) $pdo->query(
            'SELECT COUNT(*) FROM orders WHERE DATE(order_date) = CURDATE()'
        )->fetchColumn();
        $processingOrders = (int) $pdo->query(
            "SELECT COUNT(*) FROM orders WHERE status = 'inProduction'"
        )->fetchColumn();

        $chartStmt = $pdo->query(
            "SELECT DATE_FORMAT(paid_at, '%Y-%m') AS month, COALESCE(SUM(amount), 0) AS total
             FROM payments WHERE status = 'confirmed'
             GROUP BY month ORDER BY month DESC LIMIT 6"
        );
        $chartRows = array_reverse($chartStmt->fetchAll());
        $revenueChart = array_map(fn ($r) => (float) $r['total'], $chartRows);

        Response::json([
            'total_orders' => $totalOrders,
            'total_revenue' => $totalRevenue,
            'low_stock_count' => $lowStockCount,
            'today_production' => $todayProduction,
            'active_orders' => $activeOrders,
            'pending_payments' => $pendingPayments,
            'today_orders' => $todayOrders,
            'processing_orders' => $processingOrders,
            'revenue_chart' => $revenueChart,
        ]);
    }
}
