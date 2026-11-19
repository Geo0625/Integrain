<section class="staff-view" data-staff-view="salary" hidden>
  <div class="stats-grid staff-salary-stats">
    <article class="stat-card">
      <div class="stat-icon green">₱</div>
      <div><small>Daily rate</small><strong id="salary-stat-rate">—</strong><em>Set by the store</em></div>
    </article>
    <article class="stat-card">
      <div class="stat-icon blue">+</div>
      <div><small>Outstanding advance</small><strong id="salary-stat-advance">₱0.00</strong><em>Taken out of your next salary</em></div>
    </article>
    <article class="stat-card">
      <div class="stat-icon violet">₱</div>
      <div><small>Estimated earned pay</small><strong id="staff-earned-pay">&#8369;0.00</strong><em>This
          month, based on attendance</em></div>
    </article>
  </div>
  <div class="staff-salary-layout">
    <article class="panel staff-page-panel">
      <div class="panel-title">
        <div>
          <h2>Salary breakdown</h2>
          <p>Estimate for this month so far</p>
        </div><span class="status-pill status-pending">Estimate</span>
      </div>
      <div class="salary-breakdown">
        <p><span>Payable days</span><b id="salary-days">0</b></p>
        <p><span>Daily rate</span><b id="salary-daily-rate">&#8369;0.00</b></p>
        <p><span>Basic pay</span><b id="salary-earned-basic">&#8369;0.00</b></p>
        <p><span>Overtime pay (<span id="salary-ot-hours">0</span>h)</span><b id="salary-ot-pay">&#8369;0.00</b></p>
        <p class="salary-total"><span>Estimated gross pay</span><b id="salary-estimated-gross">&#8369;0.00</b></p>
      </div>
      <p class="data-note">Holiday pay, bonuses and advance deductions are added when the admin computes your official payslip below.</p>
    </article>
    <article class="panel request-panel">
      <div class="panel-title">
        <div>
          <h2>Make a request</h2>
          <p>Advance or salary release</p>
        </div>
      </div>
      <label class="request-label" for="request-type">Request type</label>
      <select id="request-type" style="width:100%;padding:10px;border:1px solid #dbe5dd;border-radius:7px;background:#fff;font:inherit">
        <option value="Paycheck Advance">Paycheck advance</option>
        <option value="Salary Request">Release a computed salary</option>
      </select>
      <div id="request-advance-fields">
        <label class="request-label" for="advance-amount">Requested amount</label>
        <div class="currency-input"><span>₱</span><input id="advance-amount" type="number" min="1" step="0.01" placeholder="e.g. 2000"></div>
      </div>
      <div id="request-salary-fields" hidden>
        <label class="request-label" for="request-payslip">Salary record</label>
        <select id="request-payslip" style="width:100%;padding:10px;border:1px solid #dbe5dd;border-radius:7px;background:#fff;font:inherit"></select>
      </div>
      <label class="request-label" for="advance-reason">Reason</label><textarea id="advance-reason" rows="3" maxlength="255"
        placeholder="Enter a brief reason"></textarea>
      <button class="button full" id="request-advance" type="button">Submit request</button>
      <div class="request-status" id="staff-request-status"><span>No request yet.</span></div>
    </article>
  </div>
  <article class="panel staff-page-panel">
    <div class="panel-title">
      <div>
        <h2>My payslips</h2>
        <p>Official salary records computed by the admin.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="staff-data-table">
        <thead><tr><th>Period</th><th>Days</th><th>Gross</th><th>Bonus / 13th</th><th>Advances</th><th>Net pay</th><th>Status</th></tr></thead>
        <tbody id="staff-payslip-list"><tr><td colspan="7" class="attendance-empty">Loading…</td></tr></tbody>
      </table>
    </div>
  </article>
  <article class="panel staff-page-panel">
    <div class="panel-title">
      <div>
        <h2>My requests</h2>
        <p>Latest 20 requests and their status.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="staff-data-table">
        <thead><tr><th>Type</th><th>Amount</th><th>Reason</th><th>Date</th><th>Status</th><th>Admin note</th></tr></thead>
        <tbody id="staff-request-list"></tbody>
      </table>
    </div>
  </article>
</section>
