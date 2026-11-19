/* ================= Payroll & salary ================= */
async function initSalary(root) {
  const $ = s => root.querySelector(s);
  let data;
  const ruleLabels = { overtime_multiplier: 'Overtime multiplier (× hourly rate)', regular_holiday_multiplier: 'Regular holiday (× daily rate)', special_holiday_multiplier: 'Special holiday (× daily rate)', work_hours_per_day: 'Hours in a workday' };

  async function load() {
    data = await api('admin/payroll');
    const unreleased = data.records.filter(r => r.payment_status === 'Computed').reduce((a, r) => a + num(r.net_pay), 0);
    const advances = data.advances.reduce((a, r) => a + num(r.outstanding_amount), 0);
    $('#salary-admin-stats').innerHTML = [
      ['orange', '&#9633;', 'Pending requests', data.requests.length, 'Need your decision'],
      ['blue', '&#8369;', 'Unreleased salaries', fmt.moneyShort(unreleased), 'Computed, not yet paid'],
      ['violet', '&#8369;', 'Outstanding advances', fmt.moneyShort(advances), `${data.advances.length} employee(s)`]
    ].map(([c, i, l, v, n]) => `<article class="stat-card"><div class="stat-icon ${c}">${i}</div><div><small>${l}</small><strong>${v}</strong><em>${n}</em></div></article>`).join('');

    $('#salary-request-list').innerHTML = data.requests.map(r => `<tr data-request="${r.request_id}"><td>${fmt.esc(r.employee_name)}</td><td>${fmt.esc(r.request_type)}${r.payroll_transaction_id ? `<div class="table-note">Salary record #${r.payroll_transaction_id}</div>` : ''}</td><td>${fmt.date(r.requested_at)}</td><td>${r.amount === null ? '—' : fmt.money(r.amount)}</td><td>${fmt.esc(r.reason)}</td>
      <td><div class="salary-actions"><button class="salary-approve" data-decision="Approved" type="button">Approve</button><button class="salary-reject" data-decision="Rejected" type="button">Reject</button></div></td></tr>`).join('');
    $('#salary-request-empty').hidden = data.requests.length > 0;

    $('#salary-payroll-list').innerHTML = data.records.length ? data.records.map(r => `<tr data-tx="${r.transaction_id}"><td>${fmt.esc(r.employee_name)}<div class="table-note">${fmt.esc(r.employee_code)}</div></td><td>${fmt.date(r.period_start)} – ${fmt.date(r.period_end)}</td><td>${num(r.days_worked)}</td><td>${fmt.money(r.gross_pay)}</td><td>${num(r.adjustments_total) ? '+ ' + fmt.money(r.adjustments_total) : '—'}</td><td class="neg">${num(r.advance_deduction) ? '− ' + fmt.money(r.advance_deduction) : '—'}</td><td><b>${fmt.money(r.net_pay)}</b></td><td>${pill(r.payment_status, statusKind(r.payment_status))}</td>
      <td><div class="salary-actions"><button class="btn-small" data-payslip type="button">Payslip</button>${r.payment_status === 'Computed' ? '<button class="salary-pay" data-release type="button">Release</button>' : ''}</div></td></tr>`).join('') : emptyRow(9, 'No salary has been computed yet. Choose a period above.');

    const options = data.employees.map(e => `<option value="${e.employee_id}">${fmt.esc(e.name)} (${fmt.esc(e.employee_code)})</option>`).join('');
    $('#compute-form').employee_id.innerHTML = '<option value="">All active employees</option>' + options;
    $('#adjust-form').employee_id.innerHTML = options;
    $('#adjust-list').innerHTML = data.adjustments.length ? data.adjustments.map(a => `<tr data-adj="${a.adjustment_id}"><td>${fmt.esc(a.employee_name)}</td><td>${fmt.esc(a.adjustment_type)}</td><td>${fmt.money(a.amount)}</td><td>${fmt.esc(a.remarks || '')}</td><td>${pill(a.adjustment_status, statusKind(a.adjustment_status))}</td><td>${a.adjustment_status === 'Pending' ? '<button class="btn-small" data-cancel-adj type="button">Cancel</button>' : ''}</td></tr>`).join('') : emptyRow(6, 'No bonuses or 13th-month pay recorded.');

    $('#rules-list').innerHTML = data.settings.map(s => `<tr data-rule="${s.setting_key}"><td>${fmt.esc(ruleLabels[s.setting_key] || s.description || s.setting_key)}</td><td>${num(s.setting_value)}</td><td><button class="btn-small" data-edit-rule type="button">Change</button></td></tr>`).join('');
    $('#holiday-list').innerHTML = data.holidays.length ? data.holidays.map(h => `<tr data-date="${h.holiday_date}"><td>${fmt.date(h.holiday_date)}</td><td>${fmt.esc(h.holiday_name)}</td><td>${fmt.esc(h.holiday_type)}</td><td><button class="btn-small" data-remove-holiday type="button">Remove</button></td></tr>`).join('') : emptyRow(4, 'No holidays added.');
  }

  // default period = current half of the month
  const now = new Date(), y = now.getFullYear(), m = now.getMonth(), cf = $('#compute-form');
  const k = d => fmt.dateKey(d);
  if (now.getDate() <= 15) { cf.start.value = k(new Date(y, m, 1)); cf.end.value = k(new Date(y, m, 15)); }
  else { cf.start.value = k(new Date(y, m, 16)); cf.end.value = k(new Date(y, m + 1, 0)); }

  cf.addEventListener('submit', async e => {
    e.preventDefault();
    const body = { start: cf.start.value, end: cf.end.value, employee_id: cf.employee_id.value || undefined };
    if (!await confirmAdminAction(`Compute salary from ${fmt.date(body.start)} to ${fmt.date(body.end)}? Attendance in this period will be locked.`)) return;
    await run(cf.querySelector('[type=submit]'), async () => { const r = await api('admin/payroll/compute', { method: 'POST', body }); toast(`Salary computed for ${r.computed} employee(s).`); await load(); });
  });
  $('#salary-request-list').addEventListener('click', async e => {
    const btn = e.target.closest('[data-decision]'); if (!btn) return;
    const id = btn.closest('tr').dataset.request, decision = btn.dataset.decision;
    const v = await askAdmin({ message: `${decision === 'Approved' ? 'Approve' : 'Reject'} this request?`, fields: [{ name: 'remarks', label: 'Note for the employee (optional)', type: 'text', maxlength: 255 }], yes: decision === 'Approved' ? 'Approve' : 'Reject' });
    if (!v) return;
    await run(btn, async () => { await api(`admin/requests/${id}/decision`, { method: 'POST', body: { decision, remarks: v.remarks } }); toast(`Request ${decision.toLowerCase()}.`); await load(); });
  });
  $('#salary-payroll-list').addEventListener('click', async e => {
    const row = e.target.closest('tr[data-tx]'); if (!row) return;
    const id = row.dataset.tx;
    if (e.target.closest('[data-release]')) {
      const r = data.records.find(x => x.transaction_id === Number(id));
      if (!await confirmAdminAction(`Release ${fmt.money(r.net_pay)} to ${r.employee_name}? This marks the salary as paid.`)) return;
      await run(e.target, async () => { await api(`admin/payroll/${id}/release`, { method: 'POST' }); toast('Salary released.'); await load(); });
    }
    if (e.target.closest('[data-payslip]')) await run(e.target, async () => {
      const p = await api(`admin/payroll/${id}/payslip`), s = p.salary, line = (l, v, cls = '') => `<p style="display:flex;justify-content:space-between;margin:6px 0;font-size:13px" class="${cls}"><span>${l}</span><b>${v}</b></p>`;
      const html = `<div style="margin-top:12px"><p style="font-size:12px;color:var(--muted)">${fmt.esc(s.employee_name)} · ${fmt.esc(s.employee_code)} · ${fmt.date(s.period_start)} – ${fmt.date(s.period_end)}</p>
        ${line('Days worked × daily rate', `${num(s.days_worked)} × ${fmt.money(s.daily_rate)}`)}${line('Basic pay', fmt.money(s.basic_pay))}${line('Overtime pay', fmt.money(s.overtime_pay))}${line('Holiday pay', fmt.money(s.holiday_pay))}${line('Gross pay', fmt.money(s.gross_pay))}
        ${p.adjustments.map(a => line(`+ ${fmt.esc(a.adjustment_type)}`, fmt.money(a.amount))).join('')}${p.advances.map(a => line('− Advance: ' + fmt.esc(a.reason), fmt.money(a.deducted_amount), 'neg')).join('')}
        <hr>${line('Net pay', fmt.money(s.net_pay))}${line('Status', fmt.esc(s.payment_status) + (s.released_at ? ' · ' + fmt.date(s.released_at) : ''))}</div>`;
      await askAdmin({ message: 'Payslip', html, info: true });
    });
  });
  const af = $('#adjust-form'), hint = $('#adjust-hint');
  af.elements.type.addEventListener('change', () => { const thirteenth = af.elements.type.value === '13th Month Pay'; af.amount.required = !thirteenth; af.amount.disabled = thirteenth; hint.textContent = thirteenth ? '(calculated automatically)' : ''; if (thirteenth) af.amount.value = ''; });
  af.amount.required = true;
  af.addEventListener('submit', async e => {
    e.preventDefault();
    await run(af.querySelector('[type=submit]'), async () => { await api('admin/adjustments', { method: 'POST', body: { employee_id: af.employee_id.value, type: af.elements.type.value, amount: af.amount.value || undefined, remarks: af.remarks.value } }); af.amount.value = ''; af.remarks.value = ''; toast('Added. It will be included in the next salary computed.'); await load(); });
  });
  $('#adjust-list').addEventListener('click', async e => {
    const btn = e.target.closest('[data-cancel-adj]'); if (!btn) return;
    if (!await confirmAdminAction('Cancel this adjustment?')) return;
    await run(btn, async () => { await api(`admin/adjustments/${btn.closest('tr').dataset.adj}/cancel`, { method: 'POST' }); await load(); });
  });
  $('#rules-list').addEventListener('click', async e => {
    const btn = e.target.closest('[data-edit-rule]'); if (!btn) return;
    const key = btn.closest('tr').dataset.rule, current = data.settings.find(s => s.setting_key === key);
    const v = await askAdmin({ message: ruleLabels[key] || key, fields: [{ name: 'value', label: 'New value', type: 'number', min: 0.01, step: '0.01', value: num(current.setting_value), required: true }] });
    if (!v) return;
    await run(btn, async () => { await api('admin/payroll-settings', { method: 'POST', body: { key, value: v.value } }); toast('Rule updated.'); await load(); });
  });
  $('#holiday-form').addEventListener('submit', async e => {
    e.preventDefault(); const f = e.currentTarget;
    await run(f.querySelector('[type=submit]'), async () => { await api('admin/holidays', { method: 'POST', body: { date: f.date.value, name: f.elements.name.value, type: f.elements.type.value } }); f.reset(); toast('Holiday saved.'); await load(); });
  });
  $('#holiday-list').addEventListener('click', async e => {
    const btn = e.target.closest('[data-remove-holiday]'); if (!btn) return;
    if (!await confirmAdminAction('Remove this holiday?')) return;
    await run(btn, async () => { await api('admin/holidays/remove', { method: 'POST', body: { date: btn.closest('tr').dataset.date } }); await load(); });
  });
  await load();
}
