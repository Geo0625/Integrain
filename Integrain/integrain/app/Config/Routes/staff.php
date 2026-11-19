<?php

/** Staff portal. URL prefix: /api/staff  (all routes need the Staff role).  @var CodeIgniter\Router\RouteCollection $routes */

$routes->group('staff', ['filter' => 'auth:staff', 'namespace' => 'App\Controllers\Staff'], static function ($routes) {
    $routes->get('dashboard', 'Dashboard::index');
    $routes->get('attendance', 'Attendance::index');
    $routes->get('transactions', 'Salary::transactions');
    $routes->get('salary', 'Salary::index');
    $routes->post('requests', 'Salary::request');
});
