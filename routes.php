<?php

declare(strict_types=1);

use Simk\Controllers\AuthController;
use Simk\Controllers\CustomerController;
use Simk\Controllers\DashboardController;
use Simk\Controllers\IngredientController;
use Simk\Controllers\OrderController;
use Simk\Controllers\PaymentController;
use Simk\Controllers\ProductionController;
use Simk\Controllers\RecipeController;
use Simk\Controllers\ReportController;
use Simk\Controllers\UserController;
use Simk\Core\Router;

return function (Router $router, array $config): void {
    $router->post('/auth/login', fn ($req) => AuthController::login($req, $config), false);
    $router->get('/auth/me', fn ($req) => AuthController::me($req));

    $router->get('/dashboard', fn ($req) => DashboardController::index($req));
    $router->get('/users', fn ($req) => UserController::index($req));
    $router->get('/customers', fn ($req) => CustomerController::index($req));
    $router->get('/orders', fn ($req) => OrderController::index($req));
    $router->get('/recipe-categories', fn ($req) => RecipeController::categories($req));
    $router->get('/recipes', fn ($req) => RecipeController::index($req));
    $router->get('/ingredients', fn ($req) => IngredientController::index($req));
    $router->get('/production', fn ($req) => ProductionController::index($req));
    $router->get('/payments', fn ($req) => PaymentController::index($req));
    $router->get('/reports/{type}', fn ($req, $params) => ReportController::show($req, $params));
};
