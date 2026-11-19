/* ================= Dashboard ================= */
async function initDashboard(root) {
  const d = await api('admin/dashboard'), s = d.stats;
  const card = (color, icon, label, value, note) => `<article class="stat-card"><div class="stat-icon ${color}">${icon}</div><div><small>${label}</small><strong>${value}</strong><em>${note}</em></div></article>`;
  const rate = s.active_employees ? Math.round(s.present_today / s.active_employees * 100) : 0;
  root.querySelector('#dash-stats').innerHTML = [
    card('green', '&#128101;', 'Active employees', s.active_employees, 'On the payroll'),
    card('blue', '&#10003;', "Today's attendance", `${s.present_today} / ${s.active_employees}`, `${rate}% present`),
    card('orange', '&#9993;', 'Pending applicants', s.pending_applicants, 'Waiting for a decision'),
    card('violet', '&#8369;', 'Payroll this month', fmt.moneyShort(s.payroll_this_month), 'Net pay computed'),
    card('orange', '&#9633;', 'Pending pay requests', s.pending_requests, 'Salary and advances'),
    card('blue', '&#8369;', 'Unreleased salaries', fmt.moneyShort(s.unreleased_salaries), 'Computed, not yet paid'),
    card('violet', '&#8369;', 'Outstanding advances', fmt.moneyShort(s.outstanding_advances), 'Taken from next salary'),
    card('green', '&#9888;', 'Failed sign-ins today', s.failed_logins_today, `${s.unavailable_products} product(s) unavailable`)
  ].join('');

  const max = Math.max(1, s.active_employees, ...d.week.map(x => x.present + x.absent));
  root.querySelector('#dash-bars').innerHTML = d.week.map(day => `<div class="bar-column"><div class="bars"><i style="height:${Math.round(day.present / max * 100)}%" title="${day.present} present"></i><i class="absent-bar" style="height:${Math.round(day.absent / max * 100)}%" title="${day.absent} absent"></i></div><small>${day.label}</small></div>`).join('');

  const p = d.payroll, parts = [p.basic || 0, p.overtime || 0, p.deductions || 0, p.other || 0], total = parts.reduce((a, b) => a + b, 0);
  const pct = parts.map(v => total ? Math.round(v / total * 100) : 0);
  const colors = ['#087346', '#e8aa31', '#dd594c', '#2195af'];
  let at = 0;
  root.querySelector('#dash-donut').style.background = total ? `conic-gradient(${colors.map((c, i) => { const from = at; at += parts[i] / total * 100; return `${c} ${from}% ${at}%`; }).join(', ')})` : '#e8eee7';
  root.querySelector('#dash-donut-total').textContent = fmt.moneyShort(s.payroll_this_month);
  root.querySelector('#dash-payroll-month').textContent = new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const legend = ['Salaries', 'Overtime', 'Deductions', 'Others'];
  root.querySelector('#dash-legend').innerHTML = legend.map((l, i) => `<li><i class="c${i + 1}"></i>${l} <b>${pct[i]}%</b></li>`).join('');

  root.querySelector('#dash-recent').innerHTML = d.recent.length
    ? d.recent.map(t => `<tr><td>${fmt.esc(t.employee_name)}</td><td>${fmt.esc(t.txn_type)}</td><td>${fmt.money(t.amount)}</td><td>${pill(t.txn_status, statusKind(t.txn_status))}</td><td>${fmt.date(t.txn_date)}</td></tr>`).join('')
    : emptyRow(5, 'No transactions yet.');
}
