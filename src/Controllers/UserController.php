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
}
