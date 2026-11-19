<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\ApplicantModel;

class Reports extends ApiController
{
    /** GET api/admin/reports?from=YYYY-MM-DD&to=YYYY-MM-DD  (defaults to the current month) */
    public function index()
    {
        $from = (string) ($this->request->getGet('from') ?: date('Y-m-01'));
        $to   = (string) ($this->request->getGet('to') ?: date('Y-m-t'));
        if ($r = $this->validated(['from' => $from, 'to' => $to], 'dateRange')) {
            return $r;
        }
        if ($to < $from) {
            return $this->bad('The end date must be on or after the start date.', 422);
        }

        return $this->guard(function () use ($from, $to) {
            $pay = $this->proc->sets('sp_payroll_report', [$from, $to]);
            $app = model(ApplicantModel::class)->countsByStatus($from, $to);

            return [
                'from' => $from, 'to' => $to,
                'attendance' => $this->proc->rows('sp_attendance_report', [$from, $to]),
                'payroll'    => $pay[0] ?? [],
                'totals'     => $pay[1][0] ?? [],
                'applicants' => $app,
                'logins'     => array_slice($this->proc->rows('sp_get_login_history', [$from, $to, null]), 0, 50),
            ];
        });
    }
}
