<section class="staff-view" data-staff-view="overview">
  <div class="stats-grid">
    <article class="stat-card">
      <div class="stat-icon green">&#10003;</div>
      <div><small>Attendance today</small><strong id="staff-today-status">No record</strong><em
          id="staff-today-time">No time entry today</em></div>
    </article>
    <article class="stat-card">
      <div class="stat-icon blue">&#8369;</div>
      <div><small>Estimated pay</small><strong id="staff-total-earned-pay">&#8369;0.00</strong><em>This month so far, before deductions</em></div>
    </article>
    <article class="stat-card">
      <div class="stat-icon orange">&#9633;</div>
      <div><small>Pending requests</small><strong id="staff-pending">0</strong><em><a href="#"
            data-staff="salary">View details &#8594;</a></em></div>
    </article>
  </div>
  <div class="staff-columns">
    <article class="panel calendar-panel">
      <div class="panel-title">
        <div>
          <h2>My Attendance</h2>
          <p>Tap a date to view your time and hours.</p>
        </div>
        <div class="calendar-arrows"><button id="prev-month" aria-label="Previous month">&#8249;</button><b
            id="month-label"></b><button id="next-month" aria-label="Next month">&#8250;</button>
        </div>
      </div>
      <div class="calendar" id="calendar"></div>
      <div class="legend"><span><i class="present-dot"></i> Present / Late / Half-day</span><span><i class="absent-dot"></i>
          Absent</span></div>
      <div class="calendar-day-detail">
        <h3 id="overview-selected-date">Select a date</h3>
        <div class="calendar-detail-grid">
          <p><span>Status</span><b id="overview-status">—</b></p>
          <p><span>Time in</span><b id="overview-time-in">—</b></p>
          <p><span>Time out</span><b id="overview-time-out">—</b></p>
          <p><span>Hours</span><b id="overview-hours">—</b></p>
        </div>
      </div>
    </article>
    <article class="panel">
      <div class="panel-title">
        <div>
          <h2>Recent Transactions</h2>
          <p>Your latest pay activity</p>
        </div>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th>Type</th><th>Amount</th><th>Date</th></tr></thead>
          <tbody id="staff-recent-list"><tr><td colspan="3" class="attendance-empty">Loading…</td></tr></tbody>
        </table>
      </div>
    </article>
    <article class="panel request-panel">
      <div class="panel-title">
        <div>
          <h2>Salary Request</h2>
          <p>Need an advance or salary?</p>
        </div>
      </div>
      <p>Submit your request and we'll process it as soon as possible.</p><button class="button full"
        type="button" data-staff="salary">Request advance</button>
      <div class="salary-details">
        <h3>Your salary details</h3>
        <p><span>Daily rate</span><b id="staff-detail-rate">—</b></p>
        <p><span>Outstanding advance</span><b id="staff-detail-advance">—</b></p>
        <p class="net"><span>Last net pay</span><b id="staff-detail-net">—</b></p>
      </div>
    </article>
  </div>
</section>
