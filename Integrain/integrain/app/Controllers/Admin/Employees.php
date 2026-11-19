<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\EmployeeModel;
use App\Models\UserModel;

class Employees extends ApiController
{
    public function index()
    {
        return $this->guard(function () {
            $today = date('Y-m-d');

            return ['today' => $today, 'employees' => model(EmployeeModel::class)->listWithAccounts($today)];
        });
    }

    /** POST api/admin/employees  (create)  |  POST api/admin/employees/{id} (update) */
    public function save($id = null)
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'employeeSave')) {
            return $r;
        }

        return $this->guard(function () use ($in, $id) {
            $id        = $id === null ? null : (int) $id;
            $employees = model(EmployeeModel::class);
            $users     = model(UserModel::class);
            $role      = $in['account_role'] ?? 'Staff';

            // Check the login account FIRST so a bad username/password never leaves a half-saved employee behind.
            $username = $this->text($in['username'] ?? null, 50);
            $existing = $id ? $users->byEmployee($id) : null;
            if ($username !== null) {
                $taken = $users->byUsername($username);
                if ($taken && (! $existing || (int) $taken['user_id'] !== (int) $existing['user_id'])) {
                    return $this->bad('That username is already in use.', 409);
                }
                $active = ! isset($in['account_active']) || (int) $in['account_active'] === 1;
                if (! $existing && (string) ($in['password'] ?? '') === '') {
                    return $this->bad('Set a password (at least 8 characters) for the new login account.', 422);
                }
                if ($existing && (int) $existing['user_id'] === (int) $this->user()['id'] && ($role !== 'Admin' || ! $active)) {
                    return $this->bad('You cannot remove your own admin access or deactivate your own account.', 422);
                }
            }

            // Keep the existing code on edit; generate one for new employees when left blank.
            $code = $this->text($in['employee_code'] ?? null, 20) ?? ($id ? $employees->codeOf($id) : null) ?? $employees->nextCode();

            $row = $this->proc->one('sp_save_employee', [
                $id, $code, $this->text($in['first_name'], 60), $this->text($in['middle_name'] ?? null, 60),
                $this->text($in['last_name'], 60), $this->text($in['contact_no'] ?? null, 20),
                $this->text($in['email'] ?? null, 100), $this->text($in['address'] ?? null),
                $in['date_hired'], (float) $in['daily_rate'], $in['employment_status'] ?? null,
            ]);
            $empId = (int) $row['employee_id'];

            if ($username !== null) {
                $password = (string) ($in['password'] ?? '');
                $this->proc->sets('sp_save_user', [
                    $existing ? (int) $existing['user_id'] : null, $empId, $username,
                    $password === '' ? '' : password_hash($password, PASSWORD_DEFAULT), $role, $active ? 1 : 0,
                ]);
            }

            return $this->ok(['employee_id' => $empId, 'employee_code' => $code], $id === null ? 201 : 200);
        });
    }
}
