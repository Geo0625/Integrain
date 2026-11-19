<?php

use CodeIgniter\Router\RouteCollection;

/**
 * Routes are grouped by area, like routes/web.php in a Laravel project:
 *   Routes/site.php    website, login, chat, job applications
 *   Routes/admin.php   admin portal (role: Admin)
 *   Routes/staff.php   staff portal (role: Staff)
 *
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

// HTML of each admin section, loaded by the admin portal after sign-in (Admin role only).
$routes->get('admin/modules/(:segment)', 'Admin\\Modules::show/$1', ['filter' => 'auth:admin']);

$routes->group('api', static function (RouteCollection $routes) {
    require __DIR__ . '/Routes/site.php';
    require __DIR__ . '/Routes/admin.php';
    require __DIR__ . '/Routes/staff.php';
});
