<?php

namespace App\Models;

use CodeIgniter\Model;

/** Read queries for payroll, pay requests, advances, adjustments, rules and holidays. */
class PayrollModel extends Model
{
    protected $table      = 'payroll_transactions';
    protected $primaryKey = 'transaction_id';
    protected $returnType = 'array';

    public function records(int $limit = 300): array
    {
        return $this->db->query('SELECT d.transaction_id, d.employee_id, e.employee_code, CONCAT(e.first_name," ",e.last_name) employee_name, d.period_start, d.period_end, d.days_worked, d.daily_rate, d.basic_pay, d.overtime_pay, d.holiday_pay, d.gross_pay, d.adjustments_total, d.advance_deduction, d.net_pay, d.payment_status, d.released_at FROM v_payroll_detail d JOIN employees e ON e.employee_id = d.employee_id ORDER BY d.period_end DESC, e.last_name LIMIT ' . (int) $limit)->getResultArray();
    }

    public function decidedRequests(int $limit = 10): array
    {
        return $this->db->query("SELECT r.request_id, CONCAT(e.first_name,' ',e.last_name) employee_name, r.request_type, r.amount, r.reason, r.request_status, r.requested_at, r.decided_at, r.admin_remarks FROM v_pay_request_detail r JOIN employees e ON e.employee_id = r.employee_id WHERE r.request_status <> 'Pending' ORDER BY r.decided_at DESC LIMIT " . (int) $limit)->getResultArray();
    }

    public function outstandingAdvances(): array
    {
        return $this->db->query("SELECT o.employee_id, CONCAT(e.first_name,' ',e.last_name) employee_name, o.outstanding_amount, o.no_of_requests FROM v_outstanding_advances o JOIN employees e ON e.employee_id = o.employee_id")->getResultArray();
    }

    public function adjustments(): array
    {
        return $this->db->table('v_adjustment_list')->get()->getResultArray();
    }

    public function settings(): array
    {
        return $this->db->table('payroll_settings')->select('setting_key, setting_value, description')->orderBy('setting_key')->get()->getResultArray();
    }

    /** key => float, used for estimates. */
    public function settingsMap(): array
    {
        $map = [];
        foreach ($this->db->table('payroll_settings')->get()->getResultArray() as $s) {
            $map[$s['setting_key']] = (float) $s['setting_value'];
        }

        return $map;
    }

    public function holidays(): array
    {
        return $this->db->table('holidays')->orderBy('holiday_date')->get()->getResultArray();
    }

    /** How many salary records exist for exactly this period (used to detect "nothing new was computed"). */
    public function countForPeriod(string $start, string $end): int
    {
        return (int) $this->where(['period_start' => $start, 'period_end' => $end])->countAllResults();
    }

    /** Current-month totals for the dashboard donut chart. */
    public function monthBreakdown(): array
    {
        return $this->db->query(
            "SELECT IFNULL(SUM(basic_pay),0) basic, IFNULL(SUM(overtime_pay),0) overtime,
                    IFNULL(SUM(holiday_pay + adjustments_total),0) other, IFNULL(SUM(advance_deduction),0) deductions
               FROM v_payroll_detail WHERE YEAR(period_end)=YEAR(CURDATE()) AND MONTH(period_end)=MONTH(CURDATE())"
        )->getRowArray() ?: [];
    }

    public function recentTransactions(int $limit = 6): array
    {
        return $this->db->query(
            "SELECT t.txn_type, t.txn_date, t.amount, t.txn_status, CONCAT(e.first_name,' ',e.last_name) employee_name
               FROM v_transaction_history t JOIN employees e ON e.employee_id = t.employee_id
              ORDER BY t.txn_date DESC, t.ref_id DESC LIMIT " . (int) $limit
        )->getResultArray();
    }

    /* ---- staff side ---- */

    public function requestsFor(int $employeeId, int $limit = 20): array
    {
        return $this->db->query('SELECT request_id, request_type, payroll_transaction_id, amount, reason, request_status, requested_at, decided_at, admin_remarks FROM v_pay_request_detail WHERE employee_id = ? ORDER BY requested_at DESC, request_id DESC LIMIT ' . (int) $limit, [$employeeId])->getResultArray();
    }

    public function outstandingAdvanceFor(int $employeeId): float
    {
        return (float) ($this->db->query('SELECT IFNULL(SUM(outstanding_amount),0) a FROM v_outstanding_advances WHERE employee_id = ?', [$employeeId])->getRow()->a ?? 0);
    }
}
