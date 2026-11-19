<?php

namespace App\Controllers\Admin;

use App\Controllers\ApiController;
use App\Models\AttendanceModel;

class Attendance extends ApiController
{
    /** GET api/admin/attendance?date=YYYY-MM-DD  : one row per active employee for that day */
    public function index()
    {
        $date = (string) ($this->request->getGet('date') ?: date('Y-m-d'));
        if (! preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) || ! strtotime($date)) {
            return $this->bad('Invalid date.', 422);
        }

        return $this->guard(function () use ($date) {
            $rows = model(AttendanceModel::class)->forDate($date);

            $present = $absent = 0;
            foreach ($rows as &$r) {
                $r['employee_id'] = (int) $r['employee_id'];
                $r['locked']      = (bool) (int) $r['locked'];
                $r['hours_worked'] = $r['hours_worked'] === null ? null : (float) $r['hours_worked'];
                $r['overtime_hours'] = $r['overtime_hours'] === null ? null : (float) $r['overtime_hours'];
                $r['time_in']  = $r['time_in'] ? substr($r['time_in'], 0, 5) : null;
                $r['time_out'] = $r['time_out'] ? substr($r['time_out'], 0, 5) : null;
                if (in_array($r['status'], ['Present', 'Late', 'Half-Day'], true)) {
                    $present++;
                } elseif ($r['status'] === null || $r['status'] === 'Absent') {
                    $absent++;
                }
            }
            $total = count($rows);

            return ['date' => $date, 'records' => $rows, 'present' => $present, 'absent' => $absent,
                'rate' => $total ? round($present / $total * 100) : 0, 'total' => $total];
        });
    }

    /** POST api/admin/attendance  : add or edit one day for one employee */
    public function save()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'attendanceSave')) {
            return $r;
        }
        $in['time_in']  = $this->text($in['time_in'] ?? null);
        $in['time_out'] = $this->text($in['time_out'] ?? null);
        if ($in['time_in'] && $in['time_out'] && $in['time_out'] <= $in['time_in']) {
            return $this->bad('Time out must be later than time in.', 422);
        }

        return $this->guard(function () use ($in) {
            return $this->write((int) $in['employee_id'], $in['date'], $in['time_in'], $in['time_out'], $in['status'], (float) ($in['overtime_hours'] ?? 0), $this->text($in['remarks'] ?? null));
        });
    }

    /** POST api/admin/attendance/clock {employee_id, action: in|out} : stamps the current server time */
    public function clock()
    {
        $in = $this->input();
        if ($r = $this->validated($in, 'attendanceClock')) {
            return $r;
        }

        return $this->guard(function () use ($in) {
            $emp   = (int) $in['employee_id'];
            $today = date('Y-m-d');
            $now   = date('H:i:s');
            $cur   = model(AttendanceModel::class)->record($emp, $today);

            if ($in['action'] === 'in') {
                if ($cur && $cur['time_in']) {
                    return $this->bad('This employee already timed in today.', 422);
                }

                return $this->write($emp, $today, $now, null, 'Present', (float) ($cur['overtime_hours'] ?? 0), $cur['remarks'] ?? null);
            }
            if (! $cur || ! $cur['time_in']) {
                return $this->bad('This employee has not timed in yet.', 422);
            }
            if ($cur['time_out']) {
                return $this->bad('This employee already timed out today.', 422);
            }

            return $this->write($emp, $today, $cur['time_in'], $now, $cur['attendance_status'], (float) $cur['overtime_hours'], $cur['remarks']);
        });
    }

    /** POST api/admin/attendance/mark-present {date} */
    public function markAllPresent()
    {
        $in   = $this->input();
        $date = $in['date'] ?? date('Y-m-d');
        if ($r = $this->validated(['date' => $date], 'dateOnly')) {
            return $r;
        }

        return $this->guard(fn () => $this->proc->one('sp_mark_present_all', [$date, $this->user()['id']]));
    }

    private function write(int $emp, string $date, ?string $in, ?string $out, string $status, float $ot, ?string $remarks)
    {
        $row = $this->proc->one('sp_save_attendance', [$emp, $date, $in, $out, $status, $ot, $remarks, $this->user()['id']]);

        return $this->ok($row);
    }
}
