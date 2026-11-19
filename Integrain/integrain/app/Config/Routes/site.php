<?php

/** Public website + authentication.  URL prefix: /api  @var CodeIgniter\Router\RouteCollection $routes */

$routes->group('', ['namespace' => 'App\Controllers\Site'], static function ($routes) {
    $routes->get('store', 'Store::info');
    $routes->get('products', 'Store::products');
    $routes->get('categories', 'Store::categories');
    $routes->get('jobs', 'Store::jobs');

    $routes->post('applications', 'Applications::store', ['filter' => 'throttle:5,600']);
    $routes->post('chat/history', 'Chat::history', ['filter' => 'throttle:30,60']);
    $routes->post('chat/messages', 'Chat::send', ['filter' => 'throttle:20,60']);

    $routes->post('auth/login', 'Auth::login', ['filter' => 'throttle:15,60']);
    $routes->post('auth/logout', 'Auth::logout');
    $routes->get('auth/me', 'Auth::me');
});
