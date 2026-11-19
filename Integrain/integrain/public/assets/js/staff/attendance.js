/* Staff attendance page: calendar, monthly totals and the records table */
(function () {
  const { $, money, pillFor, showError, monthData } = Staff;


  const attendanceCalendar = Staff.makeCalendar({ grid: $('attendance-calendar'), label: $('attendance-month-label'), prev: $('attendance-prev-month'), next: $('attendance-next-month'),
    onSelect: (d, r) => Staff.dayDetail({ title: 'attendance-selected-date', status: 'attendance-selected-status', in: 'attendance-time-in', out: 'attendance-time-out', hours: 'attendance-selected-hours' }, d, r),
    onMonth: month => renderAttendanceSummary(month) });

  function renderStaffAttendance() {
    attendanceCalendar.render();
    return renderAttendanceSummary(attendanceCalendar.month());
  }
  async function renderAttendanceSummary(month) {
    try {
      const data = await monthData(month);
      $('attendance-present-count').textContent = `${data.payable_days} day${data.payable_days === 1 ? '' : 's'}`;
      $('attendance-hours-count').textContent = fmt.hours(data.hours);
      $('attendance-ot-note').textContent = data.overtime_hours ? `Includes ${data.overtime_hours}h overtime` : 'This month';
      $('attendance-earned-pay').textContent = money(data.estimated_basic);
      $('attendance-pay-note').textContent = `Basic pay estimate: ${data.payable_days} payable day(s) × ${money(data.daily_rate)} daily rate. Overtime, holiday pay and bonuses are added in your official payslip.`;
      $('staff-attendance-log').innerHTML = data.records.length ? data.records.map(r => `<tr><td>${fmt.date(r.attendance_date)}</td><td>${fmt.time(r.time_in)}</td><td>${fmt.time(r.time_out)}</td><td>${r.time_in && r.time_out ? fmt.hours(r.hours_worked) : '—'}</td><td>${r.overtime_hours ? r.overtime_hours + 'h' : '—'}</td><td><span class="status-pill ${['Present', 'Late', 'Half-Day'].includes(r.attendance_status) ? 'status-complete' : 'status-absent'}">${esc(r.attendance_status)}</span></td></tr>`).join('') : '<tr><td colspan="6" class="attendance-empty">No attendance recorded this month.</td></tr>';
    } catch (error) { showError(error); }
  }

  Staff.attendanceCalendar = attendanceCalendar;
  Staff.renderStaffAttendance = renderStaffAttendance;
})();
