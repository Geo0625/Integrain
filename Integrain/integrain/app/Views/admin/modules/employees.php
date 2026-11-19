<section class="panel employee-directory">
  <div class="panel-title">
    <div>
      <h2>Employees</h2>
      <p>Add and manage your employees, their daily rate and login accounts.</p>
    </div>
    <button class="button" type="button" data-employee-form-toggle>+ Add employee</button>
  </div>

  <form class="employee-form" id="employee-form" hidden autocomplete="off">
    <h3>Employee details</h3>
    <div class="employee-form-grid">
      <label>First name<input name="first_name" required maxlength="60" placeholder="e.g. Maria"></label>
      <label>Middle name <span class="form-hint">(optional)</span><input name="middle_name" maxlength="60"></label>
      <label>Last name<input name="last_name" required maxlength="60" placeholder="e.g. Reyes"></label>
      <label>Employee code <span class="form-hint">(leave blank to generate)</span><input name="employee_code" maxlength="20" placeholder="EMP-0000"></label>
      <label>Contact number<input name="contact_no" maxlength="20" placeholder="09XXXXXXXXX"></label>
      <label>Email<input name="email" type="email" maxlength="100" placeholder="name@example.com"></label>
      <label class="span-2">Address<input name="address" maxlength="255"></label>
      <label>Date hired<input name="date_hired" type="date" required></label>
      <label>Daily rate (₱)<input name="daily_rate" type="number" min="0" step="0.01" required placeholder="500"></label>
      <label>Employment status<select name="employment_status">
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
          <option value="Resigned">Resigned</option>
        </select></label>
    </div>
    <p class="form-section-title">Login account <span class="form-hint">(optional — lets this person sign in)</span></p>
    <div class="employee-form-grid">
      <label>Username<input name="username" maxlength="50" autocomplete="off" placeholder="letters, numbers, . _ -"></label>
      <label>Password <span class="form-hint" id="password-hint">(min. 8 characters)</span><input name="password" type="password" minlength="8" maxlength="72" autocomplete="new-password"></label>
      <label>Account type<select name="account_role">
          <option value="Staff">Staff</option>
          <option value="Admin">Admin</option>
        </select></label>
      <label class="check-field"><input name="account_active" type="checkbox" checked> Account is active</label>
    </div>
    <div class="employee-form-actions"><button class="button" type="submit">Save employee</button><button
        class="text-button" type="button" data-employee-form-toggle>Cancel</button></div>
    <p class="employee-form-message" id="employee-form-message" role="alert"></p>
  </form>

  <div class="table-wrap">
    <table class="employee-table">
      <thead>
        <tr><th>Employee</th><th>Contact</th><th>Daily rate</th><th>Status</th><th>Time in</th><th>Time out</th><th>Today</th><th>Login</th><th></th></tr>
      </thead>
      <tbody id="employee-list"><tr><td colspan="9" class="salary-no-records">Loading…</td></tr></tbody>
    </table>
  </div>
</section>
