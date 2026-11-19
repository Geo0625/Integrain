<?php

namespace App\Controllers\Staff;

use App\Controllers\ApiController;
use App\Models\AttendanceModel;
use App\Models\EmployeeModel;
use App\Models\PayrollModel;

/** Staff overview: today's status, month-to-date estimate, recent transactions. */
class Dashboard extends ApiController
{
    public function index()
    {
        return $this->guard(function () {
            $emp   = (int) $this->user()['employee_id'];
            $d     = $this->proc->one('sp_staff_dashboard', [$emp]) ?? [];
            $me    = model(EmployeeModel::class)->profile($emp);
            $set   = model(PayrollModel::class)->settingsMap();
            $ot    = model(AttendanceModel::class)->overtimeHours($emp, date('Y-m-01'), date('Y-m-t'));
            $rate  = (float) $me['daily_rate'];
            $hours = max(1.0, $set['work_hours_per_day'] ?? 8.0);
            $basic = round(($d['payable_days_this_month'] ?? 0) * $rate, 2);
            $otPay = round($ot * ($rate / $hours) * ($set['overtime_multiplier'] ?? 1.25), 2);

            return [
                'profile'  => ['code' => $me['employee_code'], 'name' => trim($me['first_name'] . ' ' . $me['last_name']), 'daily_rate' => $rate, 'date_hired' => $me['date_hired']],
                'today'    => ['status' => $d['today_status'] ?? null, 'time_in' => isset($d['today_time_in']) ? substr($d['today_time_in'], 0, 5) : null, 'time_out' => isset($d['today_time_out']) ? substr($d['today_time_out'], 0, 5) : null],
                'month'    => ['payable_days' => $d['payable_days_this_month'] ?? 0, 'overtime_hours' => $ot, 'basic_pay' => $basic, 'overtime_pay' => $otPay, 'estimated' => round($basic + $otPay, 2)],
                'latest'   => ['net_pay' => $d['latest_net_pay'] ?? null, 'status' => $d['latest_payment_status'] ?? null],
                'outstanding_advance' => $d['outstanding_advance'] ?? 0,
                'pending_requests'    => $d['pending_requests'] ?? 0,
                'recent'   => array_slice($this->proc->rows('sp_get_transaction_history', [$emp]), 0, 5),
            ];
        });
    }
}
