<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;

/** Payroll multipliers and the holiday calendar used when salary is computed. */
class PayrollRules extends ApiController
{
    /** POST api/admin/payroll-settings {key, value} */
    public function saveSetting()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'payrollSetting')) {
            return $r;
        }

        return $this->guard(fn () => $this->proc->one('sp_save_payroll_setting', [$in['key'], (float) $in['value'], $this->user()['id']]));
    }

    /** POST api/admin/holidays {date, name, type} */
    public function saveHoliday()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'holidaySave')) {
            return $r;
        }

        return $this->guard(fn () => $this->ok($this->proc->one('sp_save_holiday', [$in['date'], trim($in['name']), $in['type']]), 201));
    }

    public function removeHoliday()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'dateOnly')) {
            return $r;
        }

        return $this->guard(function () use ($in) {
            $this->proc->sets('sp_remove_holiday', [$in['date']]);

            return ['ok' => true];
        });
    }
}
