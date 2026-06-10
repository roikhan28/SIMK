<?php

return [
    'name' => 'SIMK API',
    'env' => $_ENV['APP_ENV'] ?? 'local',
    'debug' => filter_var($_ENV['APP_DEBUG'] ?? true, FILTER_VALIDATE_BOOLEAN),
    'url' => $_ENV['APP_URL'] ?? 'http://localhost',
    'jwt_secret' => $_ENV['JWT_SECRET'] ?? 'simk-dev-secret-change-in-production',
    'jwt_ttl' => (int) ($_ENV['JWT_TTL'] ?? 3600),
    'jwt_refresh_ttl' => (int) ($_ENV['JWT_REFRESH_TTL'] ?? 604800),
    'cors_origin' => $_ENV['CORS_ORIGIN'] ?? '*',
];
