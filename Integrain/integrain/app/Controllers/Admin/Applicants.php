<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\ApplicantModel;

class Applicants extends ApiController
{
    public function index()
    {
        return $this->guard(function () {
            $applicants = model(ApplicantModel::class);

            return ['applicants' => $applicants->listWithMessages(), 'openings' => $applicants->openings()];
        });
    }

    /** POST api/admin/applicants/{id}/decision {decision, daily_rate?, remarks?} */
    public function decide(int $id)
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'applicantDecision')) {
            return $r;
        }
        if ($in['decision'] === 'Approved' && (float) ($in['daily_rate'] ?? 0) <= 0) {
            return $this->bad('Enter the daily rate for the new employee.', 422);
        }

        return $this->guard(fn () => $this->proc->one('sp_decide_applicant', [
            $id, $this->user()['id'], $in['decision'], $in['decision'] === 'Approved' ? (float) $in['daily_rate'] : null, $this->text($in['remarks'] ?? null),
        ]));
    }

    /** POST api/admin/job-openings {id?, description, slots, is_open} */
    public function saveOpening()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'jobOpening')) {
            return $r;
        }

        return $this->guard(fn () => $this->ok($this->proc->one('sp_save_job_opening', [
            isset($in['id']) && $in['id'] !== '' ? (int) $in['id'] : null, trim($in['description']),
            isset($in['slots']) && $in['slots'] !== '' ? (int) $in['slots'] : null,
            isset($in['is_open']) ? ((int) filter_var($in['is_open'], FILTER_VALIDATE_BOOLEAN)) : null, $this->user()['id'],
        ])));
    }
}
