<?php

namespace App\Models;

use CodeIgniter\Model;

/** Login accounts (table `users`). Sign-in itself goes through sp_get_login. */
class UserModel extends Model
{
    protected $table      = 'users';
    protected $primaryKey = 'user_id';
    protected $returnType = 'array';

    public function byUsername(string $username): ?array
    {
        return $this->where('username', $username)->first();
    }

    public function byEmployee(int $employeeId): ?array
    {
        return $this->where('employee_id', $employeeId)->first();
    }
}
