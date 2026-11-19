<?php

/** Admin portal. URL prefix: /api/admin  (all routes need the Admin role).  @var CodeIgniter\Router\RouteCollection $routes */

$routes->group('admin', ['filter' => 'auth:admin', 'namespace' => 'App\Controllers\Admin'], static function ($routes) {
    $routes->get('summary', 'Dashboard::summary');
    $routes->get('dashboard', 'Dashboard::index');

    $routes->get('employees', 'Employees::index');
    $routes->post('employees', 'Employees::save');
    $routes->post('employees/(:num)', 'Employees::save/$1');

    $routes->get('attendance', 'Attendance::index');
    $routes->post('attendance', 'Attendance::save');
    $routes->post('attendance/clock', 'Attendance::clock');
    $routes->post('attendance/mark-present', 'Attendance::markAllPresent');

    $routes->get('products', 'Products::index');
    $routes->post('products', 'Products::save');
    $routes->post('products/(:num)', 'Products::save/$1');
    $routes->post('products/(:num)/availability', 'Products::availability/$1');
    $routes->post('categories', 'Products::saveCategory');

    $routes->get('applicants', 'Applicants::index');
    $routes->post('applicants/(:num)/decision', 'Applicants::decide/$1');
    $routes->post('job-openings', 'Applicants::saveOpening');

    $routes->get('payroll', 'Payroll::index');
    $routes->post('payroll/compute', 'Payroll::compute');
    $routes->post('payroll/(:num)/release', 'Payroll::release/$1');
    $routes->get('payroll/(:num)/payslip', 'Payroll::payslip/$1');
    $routes->post('requests/(:num)/decision', 'PayRequests::decide/$1');
    $routes->post('adjustments', 'Adjustments::store');
    $routes->post('adjustments/(:num)/cancel', 'Adjustments::cancel/$1');
    $routes->post('payroll-settings', 'PayrollRules::saveSetting');
    $routes->post('holidays', 'PayrollRules::saveHoliday');
    $routes->post('holidays/remove', 'PayrollRules::removeHoliday');

    $routes->get('reports', 'Reports::index');
});
