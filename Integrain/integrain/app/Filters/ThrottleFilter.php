<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/** Per-IP rate limit.  Usage: ['filter' => 'throttle:20,60'] = 20 requests per 60 seconds per route group. */
class ThrottleFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $limit  = (int) ($arguments[0] ?? 30);
        $window = (int) ($arguments[1] ?? 60);
        $key    = 'thr_' . md5($request->getIPAddress() . '|' . $request->getUri()->getPath());
        // Throttler refills `capacity` tokens over `seconds`; check() returns false when empty.
        if (! service('throttler')->check($key, $limit, $window)) {
            return service('response')->setStatusCode(429)->setJSON(['message' => 'Too many requests. Please slow down and try again shortly.']);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
    }
}
