<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Auth;
use Simk\Core\Database;
use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Rbac;

class UserController
{
    public static function index(Request $req): void
    {
        Rbac::authorize($req->user, 'users');

        $rows = Database::pdo()->query(
            'SELECT id, name, email, role, is_active FROM users ORDER BY id'
        )->fetchAll();

        Response::success(array_map(fn ($u) => Auth::formatUser($u), $rows));
    }

    public static function store(Request $req): void
    {
        Rbac::authorize($req->user, 'users', 'create');

        $name = trim((string) ($req->body['name'] ?? ''));
        $email = strtolower(trim((string) ($req->body['email'] ?? '')));
        $password = (string) ($req->body['password'] ?? '');
        $role = (string) ($req->body['role'] ?? 'kasir');

        if ($name === '') {
            Response::error('Nama wajib diisi', 422);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Response::error('Email tidak valid', 422);
        }
        if (strlen($password) < 6) {
            Response::error('Password minimal 6 karakter', 422);
        }
        if (!in_array($role, ['admin', 'kasir', 'staff_produksi'], true)) {
            Response::error('Role tidak valid', 422);
        }

        $pdo = Database::pdo();
        $exists = $pdo->prepare('SELECT id FROM users WHERE email = ? LIMIT 1');
        $exists->execute([$email]);
        if ($exists->fetch()) {
            Response::error('Email sudah digunakan', 422);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO users (name, email, password, role, is_active) VALUES (?, ?, ?, ?, 1)'
        );
        $stmt->execute([$name, $email, password_hash($password, PASSWORD_DEFAULT), $role]);

        $id = (int) $pdo->lastInsertId();
        $rowStmt = $pdo->prepare('SELECT id, name, email, role, is_active FROM users WHERE id = ?');
        $rowStmt->execute([$id]);
        $row = $rowStmt->fetch();

        Response::success(Auth::formatUser($row), 201);
    }

    public static function update(Request $req, array $params): void
    {
        Rbac::authorize($req->user, 'users', 'update');

        $id = (int) ($params['id'] ?? 0);
        if ($id <= 0) {
            Response::error('ID pengguna tidak valid', 422);
        }

        $pdo = Database::pdo();
        $stmt = $pdo->prepare('SELECT id, name, email, role, is_active FROM users WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        if (!$row) {
            Response::error('Pengguna tidak ditemukan', 404);
        }

        $name = trim((string) ($req->body['name'] ?? $row['name']));
        $email = strtolower(trim((string) ($req->body['email'] ?? $row['email'])));
        $role = (string) ($req->body['role'] ?? $row['role']);
        $isActive = array_key_exists('is_active', $req->body)
            ? (bool) $req->body['is_active']
            : (bool) $row['is_active'];
        $password = (string) ($req->body['password'] ?? '');

        if ($name === '') {
            Response::error('Nama wajib diisi', 422);
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Response::error('Email tidak valid', 422);
        }
        if (!in_array($role, ['admin', 'kasir', 'staff_produksi'], true)) {
            Response::error('Role tidak valid', 422);
        }

        $exists = $pdo->prepare('SELECT id FROM users WHERE email = ? AND id <> ? LIMIT 1');
        $exists->execute([$email, $id]);
        if ($exists->fetch()) {
            Response::error('Email sudah digunakan', 422);
        }

        if ((int) $req->user['id'] === $id && !$isActive) {
            Response::error('Tidak dapat menonaktifkan akun sendiri', 422);
        }

        if ($password !== '') {
            if (strlen($password) < 6) {
                Response::error('Password minimal 6 karakter', 422);
            }
            $pdo->prepare(
                'UPDATE users SET name = ?, email = ?, role = ?, is_active = ?, password = ? WHERE id = ?'
            )->execute([
                $name,
                $email,
                $role,
                $isActive ? 1 : 0,
                password_hash($password, PASSWORD_DEFAULT),
                $id,
            ]);
        } else {
            $pdo->prepare(
                'UPDATE users SET name = ?, email = ?, role = ?, is_active = ? WHERE id = ?'
            )->execute([$name, $email, $role, $isActive ? 1 : 0, $id]);
        }

        $updated = $pdo->prepare('SELECT id, name, email, role, is_active FROM users WHERE id = ?');
        $updated->execute([$id]);
        Response::success(Auth::formatUser($updated->fetch()));
    }
}
