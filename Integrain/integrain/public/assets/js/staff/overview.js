/* Staff overview page: today's status, estimated pay, recent transactions, calendar */
(function () {
  const { $, esc, money, dotFor, showError } = Staff;


  const overviewCalendar = Staff.makeCalendar({ grid: $('calendar'), label: $('month-label'), prev: $('prev-month'), next: $('next-month'),
    onSelect: (d, r) => Staff.dayDetail({ title: 'overview-selected-date', status: 'overview-status', in: 'overview-time-in', out: 'overview-time-out', hours: 'overview-hours' }, d, r) });

  async function loadDashboard() {
    Staff.dashboard = await api('staff/dashboard');
    const d = Staff.dashboard, first = d.profile.name.split(' ')[0], hour = new Date().getHours();
    $('staff-heading').innerHTML = `${hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening'}, ${esc(first)} <span>&#9728;</span>`;
    $('staff-today-status').textContent = d.today.status || 'No record';
    $('staff-today-time').textContent = d.today.time_in ? `In ${fmt.time(d.today.time_in)}${d.today.time_out ? ' · Out ' + fmt.time(d.today.time_out) : ''}` : 'No time entry today';
    $('staff-total-earned-pay').textContent = money(d.month.estimated);
    $('staff-pending').textContent = d.pending_requests;
    $('staff-detail-rate').textContent = money(d.profile.daily_rate);
    $('staff-detail-advance').textContent = money(d.outstanding_advance);
    $('staff-detail-net').textContent = d.latest.net_pay === null ? '—' : money(d.latest.net_pay);
    $('staff-recent-list').innerHTML = d.recent.length ? d.recent.map(t => `<tr><td><i class="row-dot ${dotFor(t.txn_type)}"></i> ${esc(t.txn_type)}</td><td>${money(t.amount)}</td><td>${fmt.date(t.txn_date)}</td></tr>`).join('') : '<tr><td colspan="3" class="attendance-empty">No transactions yet.</td></tr>';
    // salary page figures that come from the same call
    $('salary-stat-rate').textContent = money(d.profile.daily_rate);
    $('salary-stat-advance').textContent = money(d.outstanding_advance);
    $('staff-earned-pay').textContent = money(d.month.estimated);
    $('salary-days').textContent = d.month.payable_days;
    $('salary-daily-rate').textContent = money(d.profile.daily_rate);
    $('salary-earned-basic').textContent = money(d.month.basic_pay);
    $('salary-ot-hours').textContent = d.month.overtime_hours;
    $('salary-ot-pay').textContent = money(d.month.overtime_pay);
    $('salary-estimated-gross').textContent = money(d.month.estimated);
  }

  async function renderOverview() {
    try { await loadDashboard(); } catch (error) { showError(error); }
    overviewCalendar.render();
  }

  Staff.overviewCalendar = overviewCalendar;
  Staff.loadDashboard = loadDashboard;
  Staff.renderOverview = renderOverview;
})();
