<?php

namespace App\Controllers\Staff;

use App\Controllers\ApiController;
use App\Models\PayrollModel;

/** Staff transactions, payslips and requests (advance / salary release). */
class Salary extends ApiController
{
    public function transactions()
    {
        return $this->guard(fn () => ['transactions' => $this->proc->rows('sp_get_transaction_history', [$this->emp()])]);
    }

    /** GET api/staff/salary : payslips, requests, advance balance */
    public function index()
    {
        return $this->guard(function () {
            $emp     = $this->emp();
            $payroll = model(PayrollModel::class);

            return [
                'payslips'            => $this->proc->rows('sp_get_salary_detail', [$emp]),
                'requests'            => $payroll->requestsFor($emp),
                'outstanding_advance' => $payroll->outstandingAdvanceFor($emp),
            ];
        });
    }

    /** POST api/staff/requests {type: 'Paycheck Advance'|'Salary Request', amount?, transaction_id?, reason} */
    public function request()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'staffRequest')) {
            return $r;
        }
        if ($in['type'] === 'Paycheck Advance' && empty($in['amount'])) {
            return $this->bad('Enter the amount you need.', 422);
        }
        if ($in['type'] === 'Salary Request' && empty($in['transaction_id'])) {
            return $this->bad('Choose which salary record to release.', 422);
        }

        return $this->guard(fn () => $this->ok($this->proc->one('sp_record_pay_request', [
            $this->emp(), $in['type'], $in['type'] === 'Paycheck Advance' ? (float) $in['amount'] : null,
            trim($in['reason']), $in['type'] === 'Salary Request' ? (int) $in['transaction_id'] : null,
        ]), 201));
    }

    /** The employee is ALWAYS taken from the session, never from the request. */
    private function emp(): int
    {
        return (int) $this->user()['employee_id'];
    }
}
