/* Admin portal core: module loader, shared helpers and the sidebar badge.
   Each section (dashboard, employees, …) lives in its own file in this folder and is
   initialised by the loader after its HTML fragment (app/Views/admin/modules/*.php) arrives. */
const adminModuleNames = {
  overview: 'dashboard', employees: 'employees', attendance: 'attendance', products: 'products',
  applicants: 'applicants', salary: 'salary', reports: 'reports'
};
const adminHeadings = { dashboard: 'Dashboard', salary: 'Payroll & Salary' };

/* ---------- helpers ---------- */
const pill = (text, kind = 'muted') => `<span class="salary-status is-${kind}">${fmt.esc(text)}</span>`;
const statusKind = s => ({ Active: 'approved', Approved: 'approved', Released: 'approved', Available: 'approved', Present: 'approved', Open: 'approved', Success: 'approved',
  Pending: 'pending', Computed: 'pending', Late: 'pending', 'Half-Day': 'pending', 'For Revision': 'pending', Inactive: 'muted', Resigned: 'muted', Cancelled: 'muted', Closed: 'muted', 'On Leave': 'info', Applied: 'info',
  Rejected: 'rejected', Absent: 'rejected', Unavailable: 'rejected', Failed: 'rejected' }[s] || 'muted');
const emptyRow = (cols, text) => `<tr><td colspan="${cols}" class="salary-no-records">${text}</td></tr>`;
const num = v => Number(v || 0);
const adminError = e => toast(e.message || 'Something went wrong.');
const todayKey = () => fmt.dateKey();

async function run(button, work) {
  if (button) button.disabled = true;
  try { return await work(); } catch (e) { adminError(e); } finally { if (button) button.disabled = false; }
}

async function refreshApplicantBadge() {
  const badge = document.getElementById('applicant-badge');
  if (!badge) return;
  try {
    const { pending_applicants: n } = await api('admin/summary');
    badge.textContent = n; badge.hidden = !n;
  } catch { badge.hidden = true; }
}

/* ---------- module loader ---------- */
async function loadAdminModule(name) {
  const moduleName = adminModuleNames[name] || 'dashboard';
  const target = document.getElementById('admin-module-content');
  const heading = document.getElementById('admin-heading');
  if (!target || !heading) return;
  heading.textContent = adminHeadings[moduleName] || moduleName[0].toUpperCase() + moduleName.slice(1);
  target.setAttribute('aria-busy', 'true');
  try {
    const response = await fetch(appUrl(`admin/modules/${moduleName}`), { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } });
    if (response.status === 401) window.dispatchEvent(new CustomEvent('integrain-session-expired'));
    if (!response.ok) throw new Error('Unable to load this section.');
    target.innerHTML = await response.text();
    const init = { dashboard: initDashboard, employees: initEmployees, attendance: initAttendance, products: initProducts, applicants: initApplicants, salary: initSalary, reports: initReports }[moduleName];
    await init(target);
  } catch (error) {
    if (!target.innerHTML.trim()) target.innerHTML = `<section class="panel"><p>${fmt.esc(error.message)}</p></section>`;
    else adminError(error);
  } finally {
    target.removeAttribute('aria-busy');
    refreshApplicantBadge();
  }
}
