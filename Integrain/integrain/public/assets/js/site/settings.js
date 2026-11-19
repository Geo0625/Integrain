/* Account settings dialog. Display name and preferences are kept in this browser only (localStorage). */
let settingsTrigger = null;

function openSettings(trigger) {
  settingsTrigger = trigger;
  const dialog = document.getElementById('settings-dialog');
  if (!dialog || !currentUser) return;
  let preferences = {};
  try { preferences = JSON.parse(localStorage.getItem('integrain-settings')) || {}; } catch { preferences = {}; }
  document.getElementById('settings-display-name').value = currentUser.name;
  document.getElementById('settings-email').textContent = currentUser.username;
  document.getElementById('settings-role').textContent = currentUser.title;
  document.getElementById('settings-time-format').value = preferences.timeFormat || '12-hour';
  document.getElementById('settings-attendance-reminders').checked = Boolean(preferences.attendanceReminders);
  document.getElementById('settings-payroll-updates').checked = Boolean(preferences.payrollUpdates);
  document.getElementById('settings-saved').textContent = '';
  dialog.hidden = false;
  document.getElementById('settings-display-name').focus();
}

function closeSettings() {
  const dialog = document.getElementById('settings-dialog');
  if (!dialog) return;
  dialog.hidden = true;
  if (settingsTrigger) settingsTrigger.focus();
  settingsTrigger = null;
}

document.getElementById('settings-form').addEventListener('submit', event => {
  event.preventDefault();
  if (!currentUser) return;
  const name = document.getElementById('settings-display-name').value.trim();
  if (!name) return;
  const settings = {
    timeFormat: document.getElementById('settings-time-format').value,
    attendanceReminders: document.getElementById('settings-attendance-reminders').checked,
    payrollUpdates: document.getElementById('settings-payroll-updates').checked
  };
  try {
    localStorage.setItem(`integrain-profile-${currentUser.username}`, name);
    localStorage.setItem('integrain-settings', JSON.stringify(settings));
  } catch {
    document.getElementById('settings-saved').textContent = 'Could not save settings in browser storage.';
    return;
  }
  api('auth/me').then(user => activateUser(user)).catch(() => {});
  document.getElementById('settings-display-name').value = currentUser.name;
  document.getElementById('settings-saved').textContent = 'Settings saved on this device.';
});
