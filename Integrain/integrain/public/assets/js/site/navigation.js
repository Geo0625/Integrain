/* Page switching (home / products / login / admin / staff), top navigation, sidebars and click handling. */
function setSidebarToggleIcon(button, collapsed) {
  const path = collapsed ? 'm9 18 6-6-6-6' : 'm15 18-6-6 6-6';
  button.innerHTML = `<svg aria-hidden="true" viewBox="0 0 24 24"><path d="${path}"></path></svg>`;
}

function showPage(name) {
  const view = document.querySelector(`[data-view="${name}"]`); if (!view) return;
  document.body.classList.toggle('portal-view', name === 'staff' || name === 'admin');
  document.body.classList.remove('sidebar-collapsed');
  document.querySelectorAll('.sidebar-toggle').forEach(button => {
    button.setAttribute('aria-expanded', 'true');
    button.setAttribute('aria-label', 'Hide sidebar');
    setSidebarToggleIcon(button, false);
  });
  document.querySelectorAll('.page').forEach(p => p.classList.toggle('active', p === view));
  document.querySelectorAll('.nav-link').forEach(a => a.classList.toggle('active', a.dataset.page === name));
  document.querySelector('.top-nav').classList.remove('open'); document.querySelector('.menu-toggle').setAttribute('aria-expanded', 'false');
  if (name === 'admin') { document.querySelectorAll('[data-admin].side-link').forEach(x => x.classList.toggle('selected', x.dataset.admin === 'overview')); loadAdminModule('overview'); }
  if (name === 'staff') { window.staffPortal.openSection('overview'); }
  scrollPageToTop();
  requestAnimationFrame(scrollPageToTop);
}

function closeAccountMenus() {
  document.querySelectorAll('[data-account-panel]').forEach(panel => { panel.hidden = true; });
  document.querySelectorAll('[data-account-toggle]').forEach(button => button.setAttribute('aria-expanded', 'false'));
}

document.addEventListener('click', async e => {
  if (!e.target.closest('[data-account-panel], [data-account-toggle]')) closeAccountMenus();
  const sidebarToggle = e.target.closest('.sidebar-toggle'); if (sidebarToggle) {
    const collapsed = document.body.classList.toggle('sidebar-collapsed');
    document.querySelectorAll('.sidebar-toggle').forEach(button => {
      button.setAttribute('aria-expanded', String(!collapsed));
      button.setAttribute('aria-label', collapsed ? 'Show sidebar' : 'Hide sidebar');
      setSidebarToggleIcon(button, collapsed);
    });
    return;
  }
  const login = e.target.closest('[data-login]'); if (login) { openLogin(); return; }
  const apply = e.target.closest('[data-apply-start]'); if (apply) { e.preventDefault(); startJobApplication(); return; }
  const accountToggle = e.target.closest('[data-account-toggle]'); if (accountToggle) {
    const panel = accountToggle.closest('.sidebar').querySelector('[data-account-panel]');
    const open = panel.hidden;
    closeAccountMenus();
    panel.hidden = !open;
    accountToggle.setAttribute('aria-expanded', String(open));
    return;
  }
  const settings = e.target.closest('[data-settings-open]'); if (settings) {
    const panel = settings.closest('[data-account-panel]');
    let focusTarget = settings;
    if (panel) {
      focusTarget = panel.closest('.sidebar').querySelector('[data-account-toggle]');
      panel.hidden = true;
      focusTarget.setAttribute('aria-expanded', 'false');
    }
    openSettings(focusTarget); return;
  }
  if (e.target.closest('[data-settings-close]') || e.target.id === 'settings-dialog') { closeSettings(); return; }
  const logout = e.target.closest('[data-logout]'); if (logout) { signOut(); return; }
  const page = e.target.closest('[data-page]'); if (page) { e.preventDefault(); showPage(page.dataset.page); return; }
  const add = e.target.closest('[data-add]'); if (add) { toast(`${add.dataset.add} added to your basket`); return; }
  const filter = e.target.closest('[data-filter]'); if (filter) { window.IntegrainProducts.setFilter(filter.dataset.filter); return; }
  const staff = e.target.closest('[data-staff]'); if (staff) { e.preventDefault(); window.staffPortal.openSection(staff.dataset.staff); return; }
  const admin = e.target.closest('[data-admin]'); if (admin) { e.preventDefault(); document.querySelectorAll('[data-admin].side-link').forEach(x => x.classList.toggle('selected', x === admin)); loadAdminModule(admin.dataset.admin); return; }
  const quick = e.target.closest('.quick-question'); if (quick) { sendChat(quick.textContent); return; }
});

const menu = document.querySelector('.menu-toggle');
menu.addEventListener('click', () => {
  const nav = document.querySelector('.top-nav'), open = nav.classList.toggle('open');
  menu.setAttribute('aria-expanded', String(open));
});

document.addEventListener('keydown', event => {
  if (event.key === 'Escape') {
    if (!document.getElementById('settings-dialog').hidden) closeSettings();
    closeAccountMenus();
  }
});
