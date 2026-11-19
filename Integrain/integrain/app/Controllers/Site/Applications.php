<?php

namespace App\Controllers\Site;

use App\Controllers\ApiController;

/** Job application submitted from the website chat. */
class Applications extends ApiController
{
    public function store()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'application')) {
            return $r;
        }

        return $this->guard(function () use ($in) {
            $row = $this->proc->one('sp_submit_application', [
                $this->text($in['first_name'], 60), $this->text($in['last_name'], 60),
                $this->text($in['contact_no'], 20), $this->text($in['email'], 100), null,
                (int) $in['opening_id'], null, $this->text($in['message'] ?? null, 2000),
            ]);

            return $this->ok(['applicant_id' => $row['applicant_id'] ?? null], 201);
        });
    }
}
