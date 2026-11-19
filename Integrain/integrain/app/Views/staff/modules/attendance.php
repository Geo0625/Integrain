<section class="staff-view" data-staff-view="attendance" hidden>
  <div class="stats-grid staff-attendance-stats">
    <article class="stat-card">
      <div class="stat-icon green">✓</div>
      <div><small>Payable days this month</small><strong id="attendance-present-count">0 days</strong><em>Present / Late = 1, Half-day = 0.5</em></div>
    </article>
    <article class="stat-card">
      <div class="stat-icon orange">◷</div>
      <div><small>Total hours worked</small><strong id="attendance-hours-count">0h</strong><em id="attendance-ot-note">This month</em>
      </div>
    </article>
    <article class="stat-card">
      <div class="stat-icon blue">%</div>
      <div><small>Estimated basic pay</small><strong id="attendance-earned-pay">₱0.00</strong><em>Payable days × daily rate</em></div>
    </article>
  </div>
  <article class="panel calendar-panel staff-attendance-panel">
    <div class="panel-title">
      <div>
        <h2>Attendance Calendar</h2>
        <p>Track your attendance this month.</p>
      </div>
      <div class="calendar-arrows"><button type="button" id="attendance-prev-month"
          aria-label="Previous month">&#8249;</button><b id="attendance-month-label"></b><button type="button"
          id="attendance-next-month" aria-label="Next month">&#8250;</button></div>
    </div>
    <div class="calendar" id="attendance-calendar" aria-label="Interactive attendance calendar"></div>
    <div class="legend"><span><i class="present-dot"></i> Present / Late / Half-day</span><span><i class="absent-dot"></i>
        Absent</span></div>
    <div class="calendar-day-detail">
      <h3 id="attendance-selected-date">Select a date</h3>
      <div class="calendar-detail-grid">
        <p><span>Status</span><b id="attendance-selected-status">—</b></p>
        <p><span>Time in</span><b id="attendance-time-in">—</b></p>
        <p><span>Time out</span><b id="attendance-time-out">—</b></p>
        <p><span>Hours worked</span><b id="attendance-selected-hours">—</b></p>
      </div>
    </div>
    <p class="attendance-pay-note" id="attendance-pay-note"></p>
  </article>
  <article class="panel staff-page-panel attendance-log">
    <div class="panel-title">
      <div>
        <h2>Attendance records</h2>
        <p>Your recorded entries for this month.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="staff-data-table">
        <thead><tr><th>Date</th><th>Time in</th><th>Time out</th><th>Hours</th><th>Overtime</th><th>Status</th></tr></thead>
        <tbody id="staff-attendance-log"></tbody>
      </table>
    </div>
  </article>
</section>
