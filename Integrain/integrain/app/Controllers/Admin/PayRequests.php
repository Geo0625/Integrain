<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;

/** Approve or reject staff requests (paycheck advance / salary release). */
class PayRequests extends ApiController
{
    /** POST api/admin/requests/{id}/decision {decision: Approved|Rejected, remarks?} */
    public function decide(int $id)
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'payRequestDecision')) {
            return $r;
        }

        return $this->guard(fn () => $this->proc->one('sp_review_pay_request', [$id, $this->user()['id'], $in['decision'], $this->text($in['remarks'] ?? null)]));
    }
}
