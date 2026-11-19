<?php

namespace App\Controllers\Staff;

use App\Controllers\ApiController;
use App\Models\EmployeeModel;

/** The signed-in staff member's own attendance for a month. */
class Attendance extends ApiController
{
    /** GET api/staff/attendance?month=YYYY-MM */
    public function index()
    {
        $month = (string) ($this->request->getGet('month') ?: date('Y-m'));
        if (! preg_match('/^\d{4}-(0[1-9]|1[0-2])$/', $month)) {
            return $this->bad('Invalid month.', 422);
        }

        return $this->guard(function () use ($month) {
            $emp  = (int) $this->user()['employee_id'];
            $from = $month . '-01';
            $to   = date('Y-m-t', strtotime($from));
            $rows = $this->proc->rows('sp_get_attendance_history', [$emp, $from, $to]);
            $days = $hours = $ot = 0.0;
            foreach ($rows as &$r) {
                $r['time_in']  = $r['time_in'] ? substr($r['time_in'], 0, 5) : null;
                $r['time_out'] = $r['time_out'] ? substr($r['time_out'], 0, 5) : null;
                $days  += ['Present' => 1, 'Late' => 1, 'Half-Day' => 0.5][$r['attendance_status']] ?? 0;
                $hours += (float) $r['hours_worked'];
                $ot    += (float) $r['overtime_hours'];
            }
            $rate = model(EmployeeModel::class)->dailyRate($emp);

            return ['month' => $month, 'records' => $rows, 'payable_days' => $days, 'hours' => round($hours, 2), 'overtime_hours' => $ot, 'daily_rate' => $rate, 'estimated_basic' => round($days * $rate, 2)];
        });
    }
}
