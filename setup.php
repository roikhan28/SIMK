<?php

/**
 * Database setup script — run once from CLI:
 *   php setup.php
 */

declare(strict_types=1);

$base = __DIR__;
$envFile = $base . '/.env';

if (!file_exists($envFile)) {
    copy($base . '/.env.example', $envFile);
    echo "Created .env from .env.example\n";
}

foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    $line = trim($line);
    if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
        continue;
    }
    [$key, $value] = explode('=', $line, 2);
    $_ENV[trim($key)] = trim($value, " \t\"'");
}

$host = $_ENV['DB_HOST'] ?? '127.0.0.1';
$port = $_ENV['DB_PORT'] ?? '3306';
$user = $_ENV['DB_USERNAME'] ?? 'root';
$pass = $_ENV['DB_PASSWORD'] ?? '';
$db = $_ENV['DB_DATABASE'] ?? 'simk';

try {
    $pdo = new PDO(
        "mysql:host=$host;port=$port;charset=utf8mb4",
        $user,
        $pass,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $schema = file_get_contents($base . '/database/schema.sql');
    foreach (array_filter(array_map('trim', explode(';', $schema))) as $stmt) {
        if ($stmt !== '') {
            $pdo->exec($stmt);
        }
    }
    echo "Schema applied.\n";

    $seed = file_get_contents($base . '/database/seed.sql');
    foreach (array_filter(array_map('trim', explode(';', $seed))) as $stmt) {
        if ($stmt !== '' && !str_starts_with(strtoupper($stmt), 'USE ')) {
            try {
                $pdo->exec($stmt);
            } catch (PDOException $e) {
                if (!str_contains($e->getMessage(), 'Duplicate')) {
                    throw $e;
                }
            }
        }
    }
    echo "Seed data applied.\n";
    echo "Done. Demo accounts: admin@simk.id / admin123\n";
} catch (PDOException $e) {
    fwrite(STDERR, 'Setup failed: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
