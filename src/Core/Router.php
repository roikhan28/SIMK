<?php

declare(strict_types=1);

namespace Simk\Core;

class Router
{
    /** @var array<int, array{method:string, pattern:string, handler:callable, auth:bool}> */
    private array $routes = [];

    public function get(string $pattern, callable $handler, bool $auth = true): void
    {
        $this->add('GET', $pattern, $handler, $auth);
    }

    public function post(string $pattern, callable $handler, bool $auth = true): void
    {
        $this->add('POST', $pattern, $handler, $auth);
    }

    public function put(string $pattern, callable $handler, bool $auth = true): void
    {
        $this->add('PUT', $pattern, $handler, $auth);
    }

    public function delete(string $pattern, callable $handler, bool $auth = true): void
    {
        $this->add('DELETE', $pattern, $handler, $auth);
    }

    private function add(string $method, string $pattern, callable $handler, bool $auth): void
    {
        $this->routes[] = compact('method', 'pattern', 'handler', 'auth');
    }

    public function dispatch(Request $request, array $config): void
    {
        foreach ($this->routes as $route) {
            if ($route['method'] !== $request->method) {
                continue;
            }

            $regex = '#^' . preg_replace('#\{([a-zA-Z_]+)\}#', '(?P<$1>[^/]+)', $route['pattern']) . '$#';
            if (!preg_match($regex, $request->path, $matches)) {
                continue;
            }

            $params = array_filter($matches, 'is_string', ARRAY_FILTER_USE_KEY);
            $req = $request;

            if ($route['auth']) {
                $token = $request->bearerToken();
                if (!$token) {
                    Response::error('Token tidak ditemukan', 401);
                }
                $user = Auth::userFromToken($token, $config['jwt_secret']);
                if (!$user) {
                    Response::error('Token tidak valid atau kedaluwarsa', 401);
                }
                $req = $request->withUser($user);
            }

            ($route['handler'])($req, $params);
            return;
        }

        Response::error('Endpoint tidak ditemukan', 404);
    }
}
