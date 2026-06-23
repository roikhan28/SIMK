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
    $router->post('/users', fn ($req) => UserController::store($req));
    $router->put('/users/{id}', fn ($req, $params) => UserController::update($req, $params));
    $router->get('/customers', fn ($req) => CustomerController::index($req));
    $router->post('/customers', fn ($req) => CustomerController::store($req));
    $router->put('/customers/{id}', fn ($req, $params) => CustomerController::update($req, $params));
    $router->get('/orders', fn ($req) => OrderController::index($req));
    $router->post('/orders', fn ($req) => OrderController::store($req));
    $router->get('/recipe-categories', fn ($req) => RecipeController::categories($req));
    $router->post('/recipe-categories', fn ($req) => RecipeController::storeCategory($req));
    $router->put('/recipe-categories/{id}', fn ($req, $params) => RecipeController::updateCategory($req, $params));
    $router->get('/recipes', fn ($req) => RecipeController::index($req));
    $router->get('/recipes/{id}', fn ($req, $params) => RecipeController::show($req, $params));
    $router->post('/recipes', fn ($req) => RecipeController::store($req));
    $router->put('/recipes/{id}', fn ($req, $params) => RecipeController::update($req, $params));
    $router->get('/ingredients', fn ($req) => IngredientController::index($req));
    $router->post('/ingredients/{id}/restock', fn ($req, $params) => IngredientController::restock($req, $params));
    $router->get('/production', fn ($req) => ProductionController::index($req));
    $router->put('/production/{id}', fn ($req, $params) => ProductionController::update($req, $params));
    $router->get('/payments', fn ($req) => PaymentController::index($req));
    $router->post('/payments', fn ($req) => PaymentController::store($req));
    $router->get('/reports/{type}', fn ($req, $params) => ReportController::show($req, $params));
};
