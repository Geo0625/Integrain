<div class="settings-overlay" id="settings-dialog" role="dialog" aria-modal="true" aria-labelledby="settings-title"
    hidden>
    <form class="settings-panel" id="settings-form">
      <div class="settings-heading">
        <div><span class="eyebrow">Account preferences</span>
          <h2 id="settings-title">Settings</h2>
        </div><button type="button" class="settings-close" data-settings-close
          aria-label="Close settings">&#215;</button>
      </div>
      <section class="settings-group">
        <h3>Profile</h3>
        <label>Display name<input id="settings-display-name" name="displayName" maxlength="60" required></label>
        <div class="settings-readonly-grid">
          <p><span>Username</span><strong id="settings-email"></strong></p>
          <p><span>Role</span><strong id="settings-role"></strong></p>
        </div>
      </section>
      <section class="settings-group">
        <h3>Preferences</h3>
        <label>Time format<select id="settings-time-format" name="timeFormat">
            <option value="12-hour">12-hour clock</option>
            <option value="24-hour">24-hour clock</option>
          </select></label>
        <label class="settings-check"><input id="settings-attendance-reminders" type="checkbox"><span>Attendance
            reminders</span></label>
        <label class="settings-check"><input id="settings-payroll-updates" type="checkbox"><span>Salary and advance
            updates</span></label>
      </section>
      <div class="settings-actions"><span id="settings-saved" role="status"></span><button class="button"
          type="submit">Save settings</button></div>
    </form>
  </div>
