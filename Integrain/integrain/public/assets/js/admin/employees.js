/* ================= Employees ================= */
async function initEmployees(root) {
  const form = root.querySelector('#employee-form'), list = root.querySelector('#employee-list'), message = root.querySelector('#employee-form-message');
  let employees = [], editing = null;

  const closeForm = () => { form.hidden = true; form.classList.remove('is-editing'); editing = null; };
  function openForm(emp) {
    editing = emp; form.reset(); message.textContent = '';
    form.classList.toggle('is-editing', Boolean(emp));
    form.querySelector('h3').textContent = emp ? `Edit ${emp.first_name} ${emp.last_name}` : 'Employee details';
    form.employee_code.readOnly = Boolean(emp);
    form.date_hired.value = emp ? emp.date_hired : todayKey();
    if (emp) {
      for (const k of ['first_name', 'middle_name', 'last_name', 'employee_code', 'contact_no', 'email', 'address', 'daily_rate', 'employment_status']) form[k].value = emp[k] ?? '';
      form.username.value = emp.username || '';
      form.account_role.value = emp.user_role || 'Staff';
      form.account_active.checked = emp.user_active !== false;
    }
    root.querySelector('#password-hint').textContent = emp && emp.username ? '(leave blank to keep the current one)' : '(min. 8 characters)';
    form.hidden = false; form.first_name.focus();
  }

  const clockCell = e => {
    if (e.employment_status !== 'Active') return '<span class="attendance-state">Not active</span>';
    if (!e.today_time_in) return '<button class="employee-time-button" data-clock="in" type="button">Time in</button>';
    if (!e.today_time_out) return '<div class="attendance-controls"><span class="attendance-state is-active">Working now</span><button class="employee-time-button" data-clock="out" type="button">Time out</button></div>';
    return '<span class="attendance-state is-complete">Completed</span>';
  };

  function render() {
    list.innerHTML = employees.length ? employees.map(e => `<tr data-id="${e.employee_id}">
      <td><div class="employee-name-cell"><span class="employee-thumbnail employee-placeholder">${fmt.esc((e.first_name[0] || '') + (e.last_name[0] || ''))}</span><div>${fmt.esc(e.first_name + ' ' + e.last_name)}<div class="table-note">${fmt.esc(e.employee_code)}</div></div></div></td>
      <td>${fmt.esc(e.contact_no || '—')}<div class="table-note">${fmt.esc(e.email || '')}</div></td>
      <td>${fmt.money(e.daily_rate)}</td>
      <td>${pill(e.employment_status, statusKind(e.employment_status))}</td>
      <td>${fmt.time(e.today_time_in)}</td><td>${fmt.time(e.today_time_out)}</td>
      <td>${clockCell(e)}</td>
      <td>${e.username ? `${fmt.esc(e.username)}<div class="table-note">${e.user_role}${e.user_active ? '' : ' · disabled'}</div>` : '<span class="table-note">No account</span>'}</td>
      <td><div class="employee-row-actions"><button class="employee-edit" type="button" data-edit>Edit</button></div></td></tr>`).join('') : emptyRow(9, 'No employees yet. Add your first employee above.');
  }

  async function load() {
    const data = await api('admin/employees');
    employees = data.employees; render();
  }

  root.querySelectorAll('[data-employee-form-toggle]').forEach(b => b.addEventListener('click', () => form.hidden ? openForm(null) : closeForm()));
  list.addEventListener('click', async e => {
    const row = e.target.closest('tr[data-id]'); if (!row) return;
    const emp = employees.find(x => x.employee_id === Number(row.dataset.id));
    if (e.target.closest('[data-edit]')) { openForm(emp); form.scrollIntoView({ behavior: 'smooth', block: 'center' }); return; }
    const clock = e.target.closest('[data-clock]');
    if (clock) await run(clock, async () => {
      await api('admin/attendance/clock', { method: 'POST', body: { employee_id: emp.employee_id, action: clock.dataset.clock } });
      toast(`${emp.first_name} timed ${clock.dataset.clock} at ${fmt.time(new Date().toTimeString().slice(0, 5))}.`);
      await load();
    });
  });
  form.addEventListener('submit', async e => {
    e.preventDefault(); message.textContent = '';
    const body = Object.fromEntries(new FormData(form).entries());
    body.account_active = form.account_active.checked ? 1 : 0;
    if (!body.username) { delete body.username; delete body.password; delete body.account_role; delete body.account_active; }
    if (!body.employee_code) delete body.employee_code;
    const submit = form.querySelector('[type=submit]');
    await run(submit, async () => {
      try {
        await api(editing ? `admin/employees/${editing.employee_id}` : 'admin/employees', { method: 'POST', body });
        toast(editing ? 'Employee updated.' : 'Employee added.'); closeForm(); await load();
      } catch (error) { message.textContent = error.message; }
    });
  });
  await load();
}
