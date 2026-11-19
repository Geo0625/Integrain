<?php

namespace App\Models;

use CodeIgniter\Model;

class ApplicantModel extends Model
{
    protected $table      = 'applicants';
    protected $primaryKey = 'applicant_id';
    protected $returnType = 'array';

    public function listWithMessages(): array
    {
        return $this->db->query('SELECT v.*, a.message FROM v_applicant_list v JOIN applicants a ON a.applicant_id = v.applicant_id ORDER BY v.date_applied DESC')->getResultArray();
    }

    public function openings(): array
    {
        return $this->db->table('job_openings')->orderBy('opening_id')->get()->getResultArray();
    }

    /** Applications per status inside a date range (reports). */
    public function countsByStatus(string $from, string $to): array
    {
        return $this->db->query('SELECT application_status status, COUNT(*) n FROM applicants WHERE DATE(date_applied) BETWEEN ? AND ? GROUP BY application_status', [$from, $to])->getResultArray();
    }
}
