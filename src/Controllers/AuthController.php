<?php

declare(strict_types=1);

namespace Simk\Controllers;

use Simk\Core\Auth;
use Simk\Core\Request;
use Simk\Core\Response;

class AuthController
{
    public static function login(Request $req, array $config): void
    {
        $email = trim($req->body['email'] ?? '');
        $password = $req->body['password'] ?? '';

        if ($email === '' || $password === '') {
            Response::error('Email dan password wajib diisi', 422);
        }

        $user = Auth::attempt($email, $password);
        if (!$user) {
            Response::error('Email atau password salah', 401);
        }

        $tokens = Auth::issueTokens($user, $config);
        Response::success([
            'token' => $tokens['token'],
            'refresh_token' => $tokens['refresh_token'],
            'user' => Auth::formatUser($user),
        ]);
    }

    public static function me(Request $req): void
    {
        Response::success(Auth::formatUser($req->user));
    }
}
