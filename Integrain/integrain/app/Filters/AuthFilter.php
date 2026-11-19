<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * Usage in routes:  ['filter' => 'auth']          any signed-in user
 *                   ['filter' => 'auth:admin']    Admin only
 *                   ['filter' => 'auth:staff']    Staff only (must be linked to an employee)
 */
class AuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $user = session('user');
        if (! is_array($user)) {
            return service('response')->setStatusCode(401)->setJSON(['message' => 'Please sign in to continue.', 'code' => 'unauthenticated']);
        }
        $need = $arguments[0] ?? null;
        if ($need !== null && $user['role'] !== $need) {
            return service('response')->setStatusCode(403)->setJSON(['message' => 'You do not have access to this section.', 'code' => 'forbidden']);
        }
        if ($need === 'staff' && empty($user['employee_id'])) {
            return service('response')->setStatusCode(403)->setJSON(['message' => 'This account is not linked to an employee record.', 'code' => 'forbidden']);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
    }
}
