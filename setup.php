<?php

/**
 * Database setup script — run from CLI:
 *   php setup.php           # schema (skip if exists) + seed
 *   php setup.php --seed    # seed only
 *   php setup.php --fresh   # drop database and recreate (destructive)
 */

declare(strict_types=1);

$base = __DIR__;
$envFile = $base . '/.env';
$seedOnly = in_array('--seed', $argv ?? [], true);
$fresh = in_array('--fresh', $argv ?? [], true);

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

function connectPdo(string $host, string $port, string $user, string $pass, ?string $db = null): PDO
{
    $dsn = $db
        ? "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4"
        : "mysql:host=$host;port=$port;charset=utf8mb4";

    return new PDO($dsn, $user, $pass, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
}

function execStatements(PDO $pdo, string $sql, bool $ignoreExists = false): void
{
    foreach (array_filter(array_map('trim', explode(';', $sql))) as $stmt) {
        if ($stmt === '' || str_starts_with(strtoupper($stmt), 'USE ')) {
            continue;
        }
        try {
            $pdo->exec($stmt);
        } catch (PDOException $e) {
            $code = (string) $e->getCode();
            $msg = $e->getMessage();
            $skippable = $ignoreExists && (
                str_contains($msg, 'already exists')
                || $code === '42S01'
                || $code === '1007'
            );
            $duplicate = str_contains($msg, 'Duplicate');
            if (!$skippable && !$duplicate) {
                throw $e;
            }
            if ($skippable) {
                echo "Skipped (already exists): " . substr($stmt, 0, 60) . "...\n";
            }
        }
    }
}

try {
    $pdo = connectPdo($host, $port, $user, $pass);

    if ($fresh) {
        echo "Dropping database `$db`...\n";
        $pdo->exec("DROP DATABASE IF EXISTS `$db`");
    }

    if (!$seedOnly) {
        $schema = file_get_contents($base . '/database/schema.sql');
        execStatements($pdo, $schema, ignoreExists: true);
        echo "Schema applied.\n";
    }

    $pdo = connectPdo($host, $port, $user, $pass, $db);
    $seed = file_get_contents($base . '/database/seed.sql');
    execStatements($pdo, $seed, ignoreExists: true);
    echo "Seed data applied.\n";

    $count = (int) $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
    echo "Users in database: $count\n";
    echo "Done. Demo accounts: admin@simk.id / admin123\n";
} catch (PDOException $e) {
    fwrite(STDERR, 'Setup failed: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
