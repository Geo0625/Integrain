<div class="admin-stack">
  <section class="panel">
    <div class="panel-title">
      <div>
        <h2>Reports</h2>
        <p>Attendance, payroll, applications and sign-in activity for a period.</p>
      </div>
    </div>
    <form class="admin-toolbar" id="report-form">
      <label>From<input type="date" name="from" required></label>
      <label>To<input type="date" name="to" required></label>
      <button class="button" type="submit">Show report</button>
    </form>
    <div class="stats-grid" id="report-stats"></div>
  </section>
  <section class="panel">
    <div class="panel-title"><div><h2>Attendance</h2><p>Per employee, for the period</p></div></div>
    <div class="table-wrap"><table>
      <thead><tr><th>Employee</th><th>Present</th><th>Late</th><th>Half-day</th><th>Absent</th><th>Leave</th><th>Hours</th><th>Overtime</th></tr></thead>
      <tbody id="report-attendance"></tbody></table></div>
  </section>
  <section class="panel">
    <div class="panel-title"><div><h2>Payroll</h2><p>Salary records with a period end inside the range</p></div></div>
    <div class="table-wrap"><table class="salary-table">
      <thead><tr><th>Employee</th><th>Period</th><th>Days</th><th>Gross</th><th>Bonus / 13th</th><th>Advances</th><th>Net pay</th><th>Status</th></tr></thead>
      <tbody id="report-payroll"></tbody></table></div>
  </section>
  <section class="panel">
    <div class="panel-title"><div><h2>Sign-in activity</h2><p>Most recent 50 attempts</p></div></div>
    <div class="table-wrap"><table>
      <thead><tr><th>Username</th><th>Role</th><th>Result</th><th>When</th></tr></thead>
      <tbody id="report-logins"></tbody></table></div>
  </section>
</div>
