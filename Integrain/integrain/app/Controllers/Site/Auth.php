<?php

namespace App\Controllers\Site;

use App\Controllers\ApiController;
use App\Models\EmployeeModel;
use App\Models\UserModel;

/** Sign in / sign out / who am I. */
class Auth extends ApiController
{
    /** bcrypt hash of a random string - used so unknown usernames cost the same time as real ones. */
    private const DUMMY_HASH = '$2y$10$xNosDmpGo8KyuG.uv4kFLu7hrLxiDvgBvW4tGVBbLIO8qBS2LuTG2';

    public function login()
    {
        $in       = $this->input();
        $username = trim((string) ($in['username'] ?? ''));
        $password = (string) ($in['password'] ?? '');
        if ($username === '' || $password === '' || mb_strlen($username) > 50 || strlen($password) > 200) {
            return $this->bad('Enter your username and password.', 422);
        }

        return $this->guard(function () use ($username, $password) {
            $row = $this->proc->one('sp_get_login', [$username]);
            $max = (int) (env('integrain.maxFailedLogins') ?: 5);

            if ($row && (int) $row['failed_attempts_15min'] >= $max) {
                return $this->bad('Too many failed attempts. Please wait about 15 minutes and try again.', 429);
            }

            $valid = password_verify($password, $row['password_hash'] ?? self::DUMMY_HASH) && $row;
            if (! $valid) {
                $this->proc->sets('sp_record_failed_login', [$username]);

                return $this->bad('Incorrect username or password.', 401);
            }
            if (! (int) $row['is_active']) {
                return $this->bad('This account has been deactivated. Please contact the administrator.', 403);
            }

            $this->proc->sets('sp_record_login', [$row['user_id']]);
            $session = session();
            $session->regenerate(true);
            $session->set('user', $this->buildUser($row));

            return $this->ok($this->publicUser($session->get('user')));
        });
    }

    public function logout()
    {
        session()->destroy();

        return $this->ok(['ok' => true]);
    }

    public function me()
    {
        $u = session('user');

        return is_array($u) ? $this->ok($this->publicUser($u)) : $this->bad('Not signed in.', 401);
    }

    private function buildUser(array $row): array
    {
        $name = 'Store Admin';
        $code = null;
        if ($row['employee_id']) {
            $e = model(EmployeeModel::class)->profile((int) $row['employee_id']);
            if ($e) {
                $name = trim($e['first_name'] . ' ' . $e['last_name']);
                $code = $e['employee_code'];
            }
        }

        return [
            'id'            => (int) $row['user_id'],
            'username'      => $row['username'],
            'role'          => strtolower($row['role']),
            'employee_id'   => $row['employee_id'] ? (int) $row['employee_id'] : null,
            'employee_code' => $code,
            'name'          => $name,
        ];
    }

    private function publicUser(array $u): array
    {
        return [
            'role' => $u['role'], 'username' => $u['username'], 'name' => $u['name'],
            'title' => $u['role'] === 'admin' ? 'Administrator' : 'Staff', 'employee_code' => $u['employee_code'],
            'csrf' => csrf_hash(),
        ];
    }
}
