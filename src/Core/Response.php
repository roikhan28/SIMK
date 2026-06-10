<?php

declare(strict_types=1);

namespace Simk\Core;

class Response
{
    public static function json(mixed $data, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function success(mixed $data = null, int $status = 200): void
    {
        if ($data === null) {
            self::json(['success' => true], $status);
        }
        self::json(['data' => $data], $status);
    }

    public static function error(string $message, int $status = 400, ?string $error = null): void
    {
        self::json([
            'success' => false,
            'message' => $message,
            'error' => $error ?? $message,
        ], $status);
    }
}
