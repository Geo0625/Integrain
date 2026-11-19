/* Staff salary page: estimate, payslips and advance / salary-release requests */
(function () {
  const { $, esc, money, pillFor, showError } = Staff;


  let payslips = [];
  async function renderStaffSalary() {
    try {
      if (!Staff.dashboard) await Staff.loadDashboard();
      const data = await api('staff/salary');
      payslips = data.payslips;
      $('salary-stat-advance').textContent = money(data.outstanding_advance);
      $('staff-payslip-list').innerHTML = payslips.length ? payslips.map(p => `<tr><td>${fmt.date(p.period_start)} – ${fmt.date(p.period_end)}</td><td>${p.days_worked}</td><td>${money(p.gross_pay)}</td><td>${money(p.adjustments_total)}</td><td class="${p.advance_deduction ? 'amount-negative' : ''}">${p.advance_deduction ? '− ' : ''}${money(p.advance_deduction)}</td><td><b>${money(p.net_pay)}</b></td><td><span class="status-pill ${pillFor(p.payment_status)}">${esc(p.payment_status)}</span></td></tr>`).join('') : '<tr><td colspan="7" class="attendance-empty">No payslips yet.</td></tr>';
      const releasable = payslips.filter(p => p.payment_status === 'Computed' && p.net_pay > 0);
      $('request-payslip').innerHTML = releasable.length ? releasable.map(p => `<option value="${p.transaction_id}">${fmt.date(p.period_start)} – ${fmt.date(p.period_end)} · ${money(p.net_pay)}</option>`).join('') : '<option value="">No salary waiting to be released</option>';
      $('staff-request-list').innerHTML = data.requests.length ? data.requests.map(r => `<tr><td>${esc(r.request_type)}</td><td>${r.amount === null ? '—' : money(r.amount)}</td><td>${esc(r.reason)}</td><td>${fmt.date(r.requested_at)}</td><td><span class="status-pill ${pillFor(r.request_status)}">${esc(r.request_status)}</span></td><td>${esc(r.admin_remarks || '—')}</td></tr>`).join('') : '<tr><td colspan="6" class="attendance-empty">No requests yet.</td></tr>';
      const latest = data.requests[0];
      $('staff-request-status').innerHTML = latest ? `<span>Latest request: <b>${esc(latest.request_type)}</b> — <span class="status-pill ${pillFor(latest.request_status)}">${esc(latest.request_status)}</span></span>` : '<span>No request yet.</span>';
    } catch (error) { showError(error); }
  }

  const typeSelect = $('request-type');
  typeSelect.addEventListener('change', () => {
    const salary = typeSelect.value === 'Salary Request';
    $('request-advance-fields').hidden = salary; $('request-salary-fields').hidden = !salary;
  });
  $('request-advance').addEventListener('click', async event => {
    const button = event.currentTarget, type = typeSelect.value, reason = $('advance-reason').value.trim();
    const body = { type, reason };
    if (type === 'Paycheck Advance') {
      body.amount = $('advance-amount').value;
      if (!(Number(body.amount) > 0)) { toast('Enter the amount you need.'); return; }
    } else {
      body.transaction_id = $('request-payslip').value;
      if (!body.transaction_id) { toast('There is no computed salary to release yet.'); return; }
    }
    if (!reason) { toast('Please enter a short reason.'); return; }
    button.disabled = true;
    try {
      await api('staff/requests', { method: 'POST', body });
      $('advance-amount').value = ''; $('advance-reason').value = '';
      toast('Request sent to the admin.');
      Staff.dashboard = null;
      await renderStaffSalary();
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  });

  Staff.renderStaffSalary = renderStaffSalary;
})();
