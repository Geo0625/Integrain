<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\EmployeeModel;
use App\Models\PayrollModel;

/** Payroll page data, computing salaries, releasing pay and payslips. */
class Payroll extends ApiController
{
    /** GET api/admin/payroll : everything the Payroll & Salary page shows */
    public function index()
    {
        return $this->guard(function () {
            $payroll = model(PayrollModel::class);

            return [
                'records'     => $payroll->records(),
                'requests'    => $this->proc->rows('sp_get_pending_requests'),
                'decided'     => $payroll->decidedRequests(),
                'advances'    => $payroll->outstandingAdvances(),
                'adjustments' => $payroll->adjustments(),
                'employees'   => model(EmployeeModel::class)->activeOptions(),
                'settings'    => $payroll->settings(),
                'holidays'    => $payroll->holidays(),
            ];
        });
    }

    /** POST api/admin/payroll/compute {start, end, employee_id?} */
    public function compute()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'payrollCompute')) {
            return $r;
        }
        if ($in['end'] < $in['start']) {
            return $this->bad('The end date must be on or after the start date.', 422);
        }

        return $this->guard(function () use ($in) {
            $admin   = $this->user()['id'];
            $payroll = model(PayrollModel::class);
            $before  = $payroll->countForPeriod($in['start'], $in['end']);
            if (! empty($in['employee_id'])) {
                $this->proc->sets('sp_compute_salary', [(int) $in['employee_id'], $in['start'], $in['end'], $admin]);
            } else {
                $this->proc->sets('sp_compute_salary_all', [$in['start'], $in['end'], $admin]);
            }
            $created = $payroll->countForPeriod($in['start'], $in['end']) - $before;
            if ($created === 0) {
                return $this->bad('Salary was already computed for every active employee in that period (or an overlapping one).', 422);
            }

            return $this->ok(['computed' => $created], 201);
        });
    }

    public function release(int $id)
    {
        return $this->guard(fn () => $this->proc->one('sp_release_salary', [$id, $this->user()['id']]));
    }

    public function payslip(int $id)
    {
        return $this->guard(function () use ($id) {
            $s = $this->proc->sets('sp_get_payslip', [$id]);
            if (empty($s[0])) {
                return $this->bad('Salary record not found.', 404);
            }

            return ['salary' => $s[0][0], 'advances' => $s[1] ?? [], 'adjustments' => $s[2] ?? []];
        });
    }
}
