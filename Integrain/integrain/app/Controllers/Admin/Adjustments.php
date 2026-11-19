<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;

/** Bonuses and 13th-month pay waiting to be added to the next salary. */
class Adjustments extends ApiController
{
    /** POST api/admin/adjustments {employee_id, type, amount?, remarks?} */
    public function store()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'adjustmentAdd')) {
            return $r;
        }
        if ($in['type'] === 'Bonus' && empty($in['amount'])) {
            return $this->bad('Enter the bonus amount.', 422);
        }

        return $this->guard(fn () => $this->ok($this->proc->one('sp_add_adjustment', [
            (int) $in['employee_id'], $in['type'], isset($in['amount']) && $in['amount'] !== '' ? (float) $in['amount'] : null,
            $this->text($in['remarks'] ?? null), $this->user()['id'],
        ]), 201));
    }

    public function cancel(int $id)
    {
        return $this->guard(function () use ($id) {
            $this->proc->sets('sp_cancel_adjustment', [$id]);

            return ['ok' => true];
        });
    }
}
