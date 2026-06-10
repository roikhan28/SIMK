<?php

declare(strict_types=1);

namespace Simk\Core;

class Auth
{
    public static function attempt(string $email, string $password): ?array
    {
        $stmt = Database::pdo()->prepare(
            'SELECT id, name, email, password, role, is_active FROM users WHERE email = ? LIMIT 1'
        );
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if (!$user || !(bool) $user['is_active']) {
            return null;
        }

        if (!password_verify($password, $user['password'])) {
            return null;
        }

        unset($user['password']);
        return $user;
    }

    public static function userFromToken(string $token, string $secret): ?array
    {
        $payload = Jwt::decode($token, $secret);
        if (!$payload || !isset($payload['sub'])) {
            return null;
        }

        $stmt = Database::pdo()->prepare(
            'SELECT id, name, email, role, is_active FROM users WHERE id = ? LIMIT 1'
        );
        $stmt->execute([(int) $payload['sub']]);
        $user = $stmt->fetch();

        if (!$user || !(bool) $user['is_active']) {
            return null;
        }

        return $user;
    }

    public static function issueTokens(array $user, array $config): array
    {
        $secret = $config['jwt_secret'];
        $token = Jwt::encode(['sub' => $user['id'], 'role' => $user['role']], $secret, $config['jwt_ttl']);
        $refresh = bin2hex(random_bytes(32));

        $stmt = Database::pdo()->prepare(
            'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL ? SECOND))'
        );
        $stmt->execute([
            $user['id'],
            hash('sha256', $refresh),
            $config['jwt_refresh_ttl'],
        ]);

        return ['token' => $token, 'refresh_token' => $refresh];
    }

    public static function formatUser(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'role' => $user['role'],
            'is_active' => (bool) $user['is_active'],
        ];
    }
}
