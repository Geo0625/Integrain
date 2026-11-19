<?php

namespace App\Models;

use CodeIgniter\Model;

class AttendanceModel extends Model
{
    protected $table      = 'attendance_records';
    protected $primaryKey = 'attendance_id';
    protected $returnType = 'array';

    /** One row per active employee for the date (even when nothing was recorded). */
    public function forDate(string $date): array
    {
        return $this->db->query(
            "SELECT e.employee_id, e.employee_code, CONCAT(e.first_name,' ',e.last_name) AS employee_name,
                    ar.attendance_status AS status, ar.time_in, ar.time_out, ar.hours_worked, ar.overtime_hours, ar.remarks,
                    EXISTS (SELECT 1 FROM payroll_transactions p WHERE p.employee_id = e.employee_id
                             AND ? BETWEEN p.period_start AND p.period_end) AS locked
               FROM employees e
               LEFT JOIN attendance_records ar ON ar.employee_id = e.employee_id AND ar.attendance_date = ?
              WHERE e.employment_status = 'Active' AND e.date_hired <= ?
              ORDER BY e.last_name, e.first_name",
            [$date, $date, $date]
        )->getResultArray();
    }

    public function record(int $employeeId, string $date): ?array
    {
        return $this->where(['employee_id' => $employeeId, 'attendance_date' => $date])->first();
    }

    /** Present / absent counts per day between two dates (dashboard chart). */
    public function dailyCounts(string $from, string $to): array
    {
        return $this->db->query(
            "SELECT attendance_date d,
                    SUM(attendance_status IN ('Present','Late','Half-Day')) present,
                    SUM(attendance_status = 'Absent') absent
               FROM attendance_records WHERE attendance_date BETWEEN ? AND ? GROUP BY attendance_date",
            [$from, $to]
        )->getResultArray();
    }

    public function overtimeHours(int $employeeId, string $from, string $to): float
    {
        $row = $this->db->query("SELECT IFNULL(SUM(overtime_hours),0) h FROM attendance_records WHERE employee_id=? AND attendance_date BETWEEN ? AND ? AND attendance_status IN ('Present','Late','Half-Day')", [$employeeId, $from, $to])->getRow();

        return (float) ($row->h ?? 0);
    }
}
