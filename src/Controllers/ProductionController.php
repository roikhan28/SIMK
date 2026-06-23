<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class ProductionController
{
    private const ALLOWED = ['scheduled', 'in_progress', 'completed', 'cancelled'];

    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'production');

        $rows = Database::pdo()->query(
            'SELECT ps.*, o.order_number FROM production_schedules ps
             JOIN orders o ON o.id = ps.order_id
             ORDER BY ps.scheduled_date DESC'
        )->fetchAll();

        Response::success(array_map(fn ($r) => self::format($r), $rows));
    }

    public static function update(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'production', 'update');

        $id = (int) ($params['id'] ?? 0);
        $status = (string) ($req->body['status'] ?? '');

        if ($id <= 0) {
            Response::error('ID jadwal produksi tidak valid', 422);
        }
        if (!in_array($status, self::ALLOWED, true)) {
            Response::error('Status produksi tidak valid', 422);
        }

        $pdo = Database::pdo();
        $stmt = $pdo->prepare(
            'SELECT ps.*, o.order_number FROM production_schedules ps
             JOIN orders o ON o.id = ps.order_id
             WHERE ps.id = ?'
        );
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        if (!$row) {
            Response::error('Jadwal produksi tidak ditemukan', 404);
        }

        $pdo->prepare('UPDATE production_schedules SET status = ? WHERE id = ?')
            ->execute([$status, $id]);

        self::syncOrderStatus($pdo, (int) $row['order_id']);

        $stmt->execute([$id]);
        Response::success(self::format($stmt->fetch()));
    }

    private static function syncOrderStatus(\PDO $pdo, int $orderId): void
    {
        $rows = $pdo->prepare(
            'SELECT status FROM production_schedules WHERE order_id = ? AND status <> ?'
        );
        $rows->execute([$orderId, 'cancelled']);
        $statuses = $rows->fetchAll(\PDO::FETCH_COLUMN);

        if ($statuses === []) {
            return;
        }

        $orderStatus = 'confirmed';
        if (in_array('in_progress', $statuses, true)) {
            $orderStatus = 'inProduction';
        } elseif (count(array_filter($statuses, fn ($s) => $s !== 'completed')) === 0) {
            $orderStatus = 'ready';
        }

        $pdo->prepare('UPDATE orders SET status = ? WHERE id = ?')->execute([$orderStatus, $orderId]);
    }

    private static function format(array $r): array
    {
        return [
            'id' => (int) $r['id'],
            'order_id' => (int) $r['order_id'],
            'order_number' => $r['order_number'],
            'recipe_name' => $r['recipe_name'],
            'portions' => (int) $r['portions'],
            'scheduled_date' => $r['scheduled_date'],
            'status' => $r['status'],
            'assigned_to' => $r['assigned_to'] ?? '',
        ];
    }
}
