<?php

namespace App\Controllers\Admin;

use App\Controllers\BaseController;

/** Serves the HTML of each admin section (app/Views/admin/modules/*.php). Admin-only (see routes). */
class Modules extends BaseController
{
    private const ALLOWED = ['dashboard', 'employees', 'attendance', 'products', 'applicants', 'salary', 'reports'];

    public function show(string $name = '')
    {
        if (! in_array($name, self::ALLOWED, true)) {
            throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound();
        }

        return $this->response
            ->setHeader('Cache-Control', 'no-store')
            ->setBody(view('admin/modules/' . $name));
    }
}
