<?php

namespace App\Controllers;

/** The single-page website (app/Views/site/home.php) that also hosts the staff and admin portals. */
class Home extends BaseController
{
    public function index()
    {
        // The page carries the CSRF token, so it must never be cached.
        return $this->response
            ->setHeader('Cache-Control', 'no-store')
            ->setBody(view('site/home'));
    }
}
