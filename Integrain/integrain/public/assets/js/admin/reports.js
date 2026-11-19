/* ================= Reports ================= */
async function initReports(root) {
  const form = root.querySelector('#report-form'), now = new Date();
  form.from.value = fmt.dateKey(new Date(now.getFullYear(), now.getMonth(), 1));
  form.to.value = fmt.dateKey(new Date(now.getFullYear(), now.getMonth() + 1, 0));
  async function load() {
    const r = await api(`admin/reports?from=${form.from.value}&to=${form.to.value}`);
    const t = r.totals || {}, applicantTotal = r.applicants.reduce((a, x) => a + num(x.n), 0);
    root.querySelector('#report-stats').innerHTML = [
      ['green', '&#8369;', 'Net payroll', fmt.moneyShort(t.total_net), `${num(t.records)} salary record(s)`],
      ['blue', '&#8369;', 'Gross pay', fmt.moneyShort(t.total_gross), 'Before advances'],
      ['orange', '&#9993;', 'Applications', applicantTotal, r.applicants.map(a => `${a.n} ${a.status.toLowerCase()}`).join(' · ') || 'None in this period']
    ].map(([c, i, l, v, n]) => `<article class="stat-card"><div class="stat-icon ${c}">${i}</div><div><small>${l}</small><strong>${v}</strong><em>${fmt.esc(n)}</em></div></article>`).join('');
    root.querySelector('#report-attendance').innerHTML = r.attendance.length ? r.attendance.map(a => `<tr><td>${fmt.esc(a.employee_name)}<div class="table-note">${fmt.esc(a.employee_code)}</div></td><td>${a.present_days}</td><td>${a.late_days}</td><td>${a.half_days}</td><td>${a.absent_days}</td><td>${a.leave_days}</td><td>${num(a.total_hours)}h</td><td>${num(a.total_overtime)}h</td></tr>`).join('') : emptyRow(8, 'No attendance in this period.');
    root.querySelector('#report-payroll').innerHTML = r.payroll.length ? r.payroll.map(p => `<tr><td>${fmt.esc(p.employee_name)}</td><td>${fmt.date(p.period_start)} – ${fmt.date(p.period_end)}</td><td>${num(p.days_worked)}</td><td>${fmt.money(p.gross_pay)}</td><td>${fmt.money(p.adjustments_total)}</td><td class="neg">${fmt.money(p.advance_deduction)}</td><td><b>${fmt.money(p.net_pay)}</b></td><td>${pill(p.payment_status, statusKind(p.payment_status))}</td></tr>`).join('') : emptyRow(8, 'No salary records in this period.');
    root.querySelector('#report-logins').innerHTML = r.logins.length ? r.logins.map(l => `<tr><td>${fmt.esc(l.username)}</td><td>${fmt.esc(l.role || '—')}</td><td>${pill(l.login_status, statusKind(l.login_status))}</td><td>${fmt.date(l.attempted_at)} ${fmt.time(String(l.attempted_at).slice(11, 16))}</td></tr>`).join('') : emptyRow(4, 'No sign-in activity.');
  }
  form.addEventListener('submit', e => { e.preventDefault(); run(form.querySelector('[type=submit]'), load); });
  await load();
}
