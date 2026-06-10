<?php

declare(strict_types=1);

use Simk\Core\Request;
use Simk\Core\Response;
use Simk\Core\Router;

header('Access-Control-Allow-Origin: ' . ($_ENV['CORS_ORIGIN'] ?? '*'));
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

try {
    $config = require dirname(__DIR__) . '/src/bootstrap.php';

    $router = new Router();
    $register = require dirname(__DIR__) . '/routes.php';
    $register($router, $config);

    $router->dispatch(Request::capture(), $config);
} catch (Throwable $e) {
    $debug = filter_var($_ENV['APP_DEBUG'] ?? true, FILTER_VALIDATE_BOOLEAN);
    Response::error(
        $debug ? $e->getMessage() : 'Terjadi kesalahan server',
        500
    );
}
