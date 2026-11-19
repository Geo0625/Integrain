<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\AttendanceModel;
use App\Models\PayrollModel;

class Dashboard extends ApiController
{
    /** Lightweight numbers (used for the sidebar badge). */
    public function summary()
    {
        return $this->guard(fn () => $this->proc->one('sp_admin_dashboard') ?? []);
    }

    public function index()
    {
        return $this->guard(function () {
            $payroll = model(PayrollModel::class);
            $stats   = $this->proc->one('sp_admin_dashboard') ?? [];

            // Attendance for the current week (Mon-Sun)
            $monday = new \DateTimeImmutable('monday this week');
            $days   = [];
            for ($i = 0; $i < 7; $i++) {
                $d = $monday->modify("+$i day");
                $days[$d->format('Y-m-d')] = ['date' => $d->format('Y-m-d'), 'label' => $d->format('D'), 'present' => 0, 'absent' => 0];
            }
            foreach (model(AttendanceModel::class)->dailyCounts(array_key_first($days), array_key_last($days)) as $r) {
                $days[$r['d']]['present'] = (int) $r['present'];
                $days[$r['d']]['absent']  = (int) $r['absent'];
            }

            return [
                'stats'   => $stats,
                'week'    => array_values($days),
                'payroll' => array_map('floatval', $payroll->monthBreakdown()),
                'recent'  => array_map(static fn ($r) => $r + ['amount' => (float) $r['amount']], $payroll->recentTransactions()),
            ];
        });
    }
}
