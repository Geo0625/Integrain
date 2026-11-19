<?php

namespace App\Models;

use CodeIgniter\Model;

class EmployeeModel extends Model
{
    protected $table      = 'employees';
    protected $primaryKey = 'employee_id';
    protected $returnType = 'array';

    /** Every employee with login account and today's attendance (admin Employees page). */
    public function listWithAccounts(string $today): array
    {
        $rows = $this->db->query(
            "SELECT e.employee_id, e.employee_code, e.first_name, e.middle_name, e.last_name, e.contact_no, e.email,
                    e.address, e.date_hired, e.daily_rate, e.employment_status,
                    u.user_id, u.username, u.role AS user_role, u.is_active AS user_active,
                    ar.attendance_status AS today_status, ar.time_in AS today_time_in, ar.time_out AS today_time_out
               FROM employees e
               LEFT JOIN users u ON u.employee_id = e.employee_id
               LEFT JOIN attendance_records ar ON ar.employee_id = e.employee_id AND ar.attendance_date = ?
              ORDER BY FIELD(e.employment_status,'Active','Inactive','Resigned'), e.last_name, e.first_name",
            [$today]
        )->getResultArray();

        foreach ($rows as &$r) {
            $r['employee_id'] = (int) $r['employee_id'];
            $r['daily_rate']  = (float) $r['daily_rate'];
            $r['user_id']     = $r['user_id'] === null ? null : (int) $r['user_id'];
            $r['user_active'] = $r['user_active'] === null ? null : (bool) (int) $r['user_active'];
        }

        return $rows;
    }

    public function codeOf(int $id): ?string
    {
        return $this->select('employee_code')->find($id)['employee_code'] ?? null;
    }

    /** Next free code like EMP-0004. */
    public function nextCode(): string
    {
        $r = $this->db->query("SELECT IFNULL(MAX(CAST(SUBSTRING(employee_code,5) AS UNSIGNED)),0)+1 n FROM employees WHERE employee_code REGEXP '^EMP-[0-9]+$'")->getRowArray();

        return 'EMP-' . str_pad((string) $r['n'], 4, '0', STR_PAD_LEFT);
    }

    /** Active employees for drop-down lists. */
    public function activeOptions(): array
    {
        return $this->db->query("SELECT employee_id, employee_code, CONCAT(first_name,' ',last_name) name FROM employees WHERE employment_status='Active' ORDER BY last_name")->getResultArray();
    }

    /** Name / code / rate / hire date for the signed-in staff member. */
    public function profile(int $id): array
    {
        return $this->select('employee_code, first_name, last_name, daily_rate, date_hired')->find($id) ?? [];
    }

    public function dailyRate(int $id): float
    {
        return (float) ($this->select('daily_rate')->find($id)['daily_rate'] ?? 0);
    }
}
