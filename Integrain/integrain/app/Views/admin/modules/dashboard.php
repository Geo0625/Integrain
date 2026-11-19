<div class="admin-dashboard-content">
  <div class="stats-grid admin-stats" id="dash-stats"></div>
  <div class="admin-columns">
    <article class="panel chart-panel">
      <div class="panel-title">
        <div>
          <h2>Attendance Summary</h2>
          <p>Team attendance this week</p>
        </div><span class="chart-legend"><i class="present-dot"></i> Present <i class="absent-dot"></i> Absent</span>
      </div>
      <div class="bar-chart" id="dash-bars" aria-label="Attendance bar chart"></div>
    </article>
    <article class="panel payroll-panel">
      <div class="panel-title">
        <div>
          <h2>Payroll Summary</h2>
          <p id="dash-payroll-month">This month</p>
        </div>
      </div>
      <div class="payroll-body">
        <div class="donut" id="dash-donut">
          <div><b id="dash-donut-total">₱0</b><small>Net payroll</small></div>
        </div>
        <ul class="payroll-legend" id="dash-legend">
          <li><i class="c1"></i>Salaries <b>0%</b></li>
          <li><i class="c2"></i>Overtime <b>0%</b></li>
          <li><i class="c3"></i>Deductions <b>0%</b></li>
          <li><i class="c4"></i>Others <b>0%</b></li>
        </ul>
      </div>
    </article>
    <article class="panel transactions-panel">
      <div class="panel-title">
        <div>
          <h2>Recent Transactions</h2>
          <p>Latest salary and pay-request activity</p>
        </div>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Employee</th><th>Type</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
          <tbody id="dash-recent"><tr><td colspan="5" class="salary-no-records">Loading…</td></tr></tbody>
        </table>
      </div>
    </article>
  </div>
</div>
