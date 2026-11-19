/* Who is signed in: login form, log-out, session restore and expiry. The session itself lives on the server. */
let currentUser = null;

function activateUser(user) {
  const role = user.role;
  let savedName = user.name;
  try { savedName = localStorage.getItem(`integrain-profile-${user.username}`) || user.name; } catch { /* use the name from the server */ }
  currentUser = { username: user.username, email: user.username, role, name: savedName, title: user.title };
  currentUser.initials = currentUser.name.split(/\s+/).filter(Boolean).slice(0, 2).map(part => part[0].toUpperCase()).join('');
  document.querySelectorAll(`[data-profile-role="${role}"]`).forEach(profile => {
    profile.querySelector('[data-profile-name]').textContent = currentUser.name;
    profile.querySelector('[data-profile-title]').textContent = currentUser.title;
    profile.querySelector('[data-profile-initials]').textContent = currentUser.initials;
    const panel = profile.closest('.sidebar').querySelector('[data-account-email]');
    if (panel) panel.textContent = currentUser.username;
  });
  const avatar = document.querySelector(`#${role}-page .portal-heading .avatar`);
  if (avatar) avatar.textContent = currentUser.initials;
  window.currentUser = currentUser;
  window.dispatchEvent(new CustomEvent('integrain-user-changed', { detail: currentUser }));
}

function openLogin() {
  document.getElementById('login-error').textContent = '';
  document.getElementById('login-form').reset();
  showPage('login');
}

async function signOut() {
  if (!await confirmAdminAction('Are you sure you want to log out?')) return;
  try { await api('auth/logout', { method: 'POST' }); } catch { /* the session is dropped on the next request anyway */ }
  currentUser = null; window.currentUser = null;
  closeAccountMenus();
  closeSettings();
  showPage('home');
}

document.getElementById('login-form').addEventListener('submit', async e => {
  e.preventDefault();
  const username = document.getElementById('login-username').value.trim();
  const password = document.getElementById('login-password').value;
  const errorBox = document.getElementById('login-error');
  if (!username || !password) { errorBox.textContent = 'Enter your username and password.'; return; }
  const submit = e.currentTarget.querySelector('[type="submit"]'); if (submit) submit.disabled = true;
  try {
    const user = await api('auth/login', { method: 'POST', body: { username, password } });
    api.setCsrf(user.csrf);
    errorBox.textContent = '';
    document.getElementById('login-password').value = '';
    activateUser(user);
    showPage(user.role);
  } catch (error) {
    errorBox.textContent = error.message;
  } finally { if (submit) submit.disabled = false; }
});

document.getElementById('toggle-password').addEventListener('click', e => {
  const input = document.getElementById('login-password'), visible = input.type === 'password';
  input.type = visible ? 'text' : 'password';
  e.currentTarget.textContent = visible ? 'Hide' : 'Show';
  e.currentTarget.setAttribute('aria-label', visible ? 'Hide password' : 'Show password');
});

window.addEventListener('integrain-session-expired', () => {
  if (!currentUser) return;
  currentUser = null; window.currentUser = null;
  openLogin();
  document.getElementById('login-error').textContent = 'Your session expired. Please sign in again.';
});
