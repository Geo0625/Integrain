/* ================= Attendance ================= */
async function initAttendance(root) {
  const dateInput = root.querySelector('#att-date'), list = root.querySelector('#att-list'), form = root.querySelector('#att-form'), message = root.querySelector('#att-message');
  let records = [], editing = null;
  dateInput.value = todayKey();

  async function load() {
    const data = await api(`admin/attendance?date=${dateInput.value}`);
    records = data.records;
    root.querySelector('#att-stats').innerHTML = [
      ['green', '&#10003;', 'Present', data.present, 'Present, late or half-day'],
      ['orange', '&#10005;', 'Absent / no record', data.absent, 'Not yet marked present'],
      ['blue', '%', 'Attendance rate', data.rate + '%', `${data.total} active employee(s)`]
    ].map(([c, i, l, v, n]) => `<article class="stat-card"><div class="stat-icon ${c}">${i}</div><div><small>${l}</small><strong>${v}</strong><em>${n}</em></div></article>`).join('');
    list.innerHTML = records.length ? records.map(r => `<tr data-id="${r.employee_id}"><td>${fmt.esc(r.employee_name)}<div class="table-note">${fmt.esc(r.employee_code)}</div></td>
      <td>${r.status ? pill(r.status, statusKind(r.status)) : pill('No record', 'muted')}</td><td>${fmt.time(r.time_in)}</td><td>${fmt.time(r.time_out)}</td>
      <td>${r.hours_worked ? fmt.hours(r.hours_worked) : '—'}</td><td>${r.overtime_hours ? r.overtime_hours + 'h' : '—'}</td><td>${fmt.esc(r.remarks || '')}</td>
      <td>${r.locked ? '<span class="table-note" title="Salary for this date was already computed">&#128274; Payroll computed</span>' : '<button class="btn-small" type="button" data-edit>' + (r.status ? 'Edit' : 'Add') + '</button>'}</td></tr>`).join('') : emptyRow(8, 'No active employees were hired on or before this date.');
  }
  const closeForm = () => { form.hidden = true; editing = null; };
  dateInput.addEventListener('change', () => { closeForm(); run(null, load); });
  root.querySelector('#att-today').addEventListener('click', () => { dateInput.value = todayKey(); closeForm(); run(null, load); });
  root.querySelector('#att-cancel').addEventListener('click', closeForm);
  list.addEventListener('click', e => {
    const row = e.target.closest('tr[data-id]'); if (!row || !e.target.closest('[data-edit]')) return;
    editing = records.find(r => r.employee_id === Number(row.dataset.id));
    root.querySelector('#att-form-title').textContent = `${editing.employee_name} — ${fmt.date(dateInput.value)}`;
    form.status.value = editing.status || 'Present'; form.time_in.value = editing.time_in || ''; form.time_out.value = editing.time_out || '';
    form.overtime_hours.value = editing.overtime_hours || 0; form.remarks.value = editing.remarks || ''; message.textContent = '';
    form.hidden = false; form.scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
  form.addEventListener('submit', async e => {
    e.preventDefault();
    const body = { employee_id: editing.employee_id, date: dateInput.value, ...Object.fromEntries(new FormData(form).entries()) };
    await run(form.querySelector('[type=submit]'), async () => {
      try { await api('admin/attendance', { method: 'POST', body }); toast('Attendance saved.'); closeForm(); await load(); } catch (error) { message.textContent = error.message; }
    });
  });
  root.querySelector('#att-mark-all').addEventListener('click', async e => {
    if (!await confirmAdminAction(`Mark every active employee without a record as present on ${fmt.date(dateInput.value)}?`)) return;
    await run(e.currentTarget, async () => { const r = await api('admin/attendance/mark-present', { method: 'POST', body: { date: dateInput.value } }); toast(`${r.employees_marked_present} employee(s) marked present.`); await load(); });
  });
  await load();
}
