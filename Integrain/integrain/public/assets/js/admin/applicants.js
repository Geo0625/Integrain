/* ================= Applicants ================= */
async function initApplicants(root) {
  const list = root.querySelector('#applicant-list'), openings = root.querySelector('#opening-list');
  let data = { applicants: [], openings: [] };
  async function load() {
    data = await api('admin/applicants');
    list.innerHTML = data.applicants.length ? data.applicants.map(a => `<tr data-id="${a.applicant_id}"><td><b>${fmt.esc(a.applicant_name)}</b><div class="table-note">${fmt.esc(a.email)}</div>${a.message ? `<div class="table-note">“${fmt.esc(a.message)}”</div>` : ''}</td>
      <td>${fmt.esc(a.applied_for)}</td><td>${fmt.esc(a.contact_no)}</td><td>${fmt.date(a.date_applied)}</td>
      <td>${pill(a.application_status, statusKind(a.application_status))}${a.admin_remarks ? `<div class="table-note">${fmt.esc(a.admin_remarks)}</div>` : ''}</td>
      <td>${['Pending', 'For Revision'].includes(a.application_status) ? '<div class="salary-actions"><button class="salary-approve" data-decide="Approved" type="button">Approve</button><button class="btn-small" data-decide="For Revision" type="button">Revise</button><button class="salary-reject" data-decide="Rejected" type="button">Reject</button></div>' : `<span class="table-note">${a.decided_by_admin ? 'by ' + fmt.esc(a.decided_by_admin) : ''}</span>`}</td></tr>`).join('') : emptyRow(6, 'No applications yet.');
    openings.innerHTML = data.openings.map(o => `<tr data-opening="${o.opening_id}"><td>${fmt.esc(o.description)}</td><td>${o.slots}</td><td>${o.is_open ? pill('Open', 'approved') : pill('Closed', 'muted')}</td><td><button class="btn-small" type="button" data-toggle-opening>${o.is_open ? 'Close hiring' : 'Reopen'}</button></td></tr>`).join('');
  }
  list.addEventListener('click', async e => {
    const btn = e.target.closest('[data-decide]'); if (!btn) return;
    const a = data.applicants.find(x => x.applicant_id === Number(btn.closest('tr').dataset.id)), decision = btn.dataset.decide;
    const fields = decision === 'Approved'
      ? [{ name: 'daily_rate', label: 'Daily rate (₱)', type: 'number', min: 1, step: '0.01', required: true }, { name: 'remarks', label: 'Remarks (optional)', type: 'text', maxlength: 255 }]
      : [{ name: 'remarks', label: decision === 'Rejected' ? 'Reason (optional)' : 'What needs to be revised?', type: 'text', maxlength: 255 }];
    const values = await askAdmin({ message: `${decision === 'Approved' ? 'Approve' : decision === 'Rejected' ? 'Reject' : 'Ask for revision from'} ${a.applicant_name}?`, fields, yes: decision === 'Approved' ? 'Approve & create employee' : 'Confirm', validate: v => decision === 'Approved' && !(Number(v.daily_rate) > 0) ? 'Enter a daily rate above 0.' : null });
    if (!values) return;
    await run(btn, async () => { await api(`admin/applicants/${a.applicant_id}/decision`, { method: 'POST', body: { decision, ...values } }); toast(decision === 'Approved' ? 'Applicant approved — employee record created.' : 'Decision saved.'); await load(); refreshApplicantBadge(); });
  });
  openings.addEventListener('click', async e => {
    const btn = e.target.closest('[data-toggle-opening]'); if (!btn) return;
    const o = data.openings.find(x => x.opening_id === Number(btn.closest('tr').dataset.opening));
    await run(btn, async () => { await api('admin/job-openings', { method: 'POST', body: { id: o.opening_id, description: o.description, slots: o.slots, is_open: !o.is_open } }); await load(); });
  });
  root.querySelector('#opening-form').addEventListener('submit', async e => {
    e.preventDefault(); const f = e.currentTarget;
    await run(f.querySelector('[type=submit]'), async () => { await api('admin/job-openings', { method: 'POST', body: { description: f.description.value, slots: f.slots.value, is_open: true } }); f.reset(); f.slots.value = 1; toast('Opening added.'); await load(); });
  });
  await load();
}
