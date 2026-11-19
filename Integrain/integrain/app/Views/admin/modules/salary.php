<section class="salary-admin">
  <div class="stats-grid salary-admin-stats" id="salary-admin-stats"></div>

  <section class="panel salary-section">
    <div class="panel-title">
      <div>
        <h2>Pay requests</h2>
        <p>Salary release requests and paycheck advances from staff.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="salary-table">
        <thead><tr><th>Employee</th><th>Type</th><th>Requested</th><th>Amount</th><th>Reason</th><th>Action</th></tr></thead>
        <tbody id="salary-request-list"></tbody>
      </table>
    </div>
    <p class="salary-empty" id="salary-request-empty" hidden>No pending requests.</p>
  </section>

  <section class="panel salary-section">
    <div class="panel-title">
      <div>
        <h2>Compute payroll</h2>
        <p>Pay = days worked × daily rate + overtime + holiday pay + bonuses − advances.</p>
      </div>
    </div>
    <form class="admin-toolbar" id="compute-form">
      <label>Period start<input type="date" name="start" required></label>
      <label>Period end<input type="date" name="end" required></label>
      <label>Employee<select name="employee_id"><option value="">All active employees</option></select></label>
      <button class="button" type="submit">Compute</button>
    </form>
    <div class="table-wrap">
      <table class="salary-table" style="min-width:900px">
        <thead><tr><th>Employee</th><th>Period</th><th>Days</th><th>Gross pay</th><th>Bonus / 13th</th><th>Advances</th><th>Net pay</th><th>Status</th><th></th></tr></thead>
        <tbody id="salary-payroll-list"></tbody>
      </table>
    </div>
  </section>

  <section class="panel salary-section">
    <div class="panel-title">
      <div>
        <h2>Bonuses &amp; 13th month</h2>
        <p>Waiting adjustments are added to the next salary you compute for that employee.</p>
      </div>
    </div>
    <form class="admin-toolbar" id="adjust-form">
      <label>Employee<select name="employee_id" required></select></label>
      <label>Type<select name="type"><option>Bonus</option><option>13th Month Pay</option></select></label>
      <label>Amount (₱) <span class="form-hint" id="adjust-hint"></span><input name="amount" type="number" min="0.01" step="0.01" style="width:140px"></label>
      <label class="grow">Remarks<input name="remarks" maxlength="255"></label>
      <button class="button" type="submit">Add</button>
    </form>
    <div class="table-wrap">
      <table class="salary-table" style="min-width:600px">
        <thead><tr><th>Employee</th><th>Type</th><th>Amount</th><th>Remarks</th><th>Status</th><th></th></tr></thead>
        <tbody id="adjust-list"></tbody>
      </table>
    </div>
  </section>

  <section class="panel salary-section">
    <details>
      <summary>Payroll rules &amp; holidays</summary>
      <div class="admin-stack" style="margin-top:16px">
        <div>
          <p class="table-note">Used whenever payroll is computed. Changes do not affect salaries already computed.</p>
          <div class="table-wrap"><table class="salary-table" style="min-width:0">
            <thead><tr><th>Rule</th><th>Value</th><th></th></tr></thead><tbody id="rules-list"></tbody></table></div>
        </div>
        <div>
          <form class="admin-toolbar" id="holiday-form">
            <label>Date<input type="date" name="date" required></label>
            <label class="grow">Holiday name<input name="name" required maxlength="100"></label>
            <label>Type<select name="type"><option>Regular</option><option>Special</option></select></label>
            <button class="button" type="submit">Add holiday</button>
          </form>
          <div class="table-wrap"><table class="salary-table" style="min-width:0">
            <thead><tr><th>Date</th><th>Holiday</th><th>Type</th><th></th></tr></thead><tbody id="holiday-list"></tbody></table></div>
        </div>
      </div>
    </details>
  </section>
</section>
