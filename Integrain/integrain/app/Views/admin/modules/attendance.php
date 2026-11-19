<section class="panel">
  <div class="panel-title">
    <div>
      <h2>Attendance</h2>
      <p>Daily records. Attendance is locked once salary for that date has been computed.</p>
    </div>
  </div>
  <div class="admin-toolbar">
    <label>Date<input type="date" id="att-date"></label>
    <button class="btn-small" type="button" id="att-today">Today</button>
    <span class="grow"></span>
    <button class="button" type="button" id="att-mark-all">Mark everyone present</button>
  </div>
  <div class="stats-grid" id="att-stats"></div>

  <form class="employee-form" id="att-form" hidden>
    <h3 id="att-form-title">Edit attendance</h3>
    <div class="employee-form-grid">
      <label>Status<select name="status">
          <option>Present</option><option>Late</option><option>Half-Day</option><option>Absent</option><option>On Leave</option>
        </select></label>
      <label>Overtime hours<input name="overtime_hours" type="number" min="0" max="23.99" step="0.25" value="0"></label>
      <label>Time in<input name="time_in" type="time"></label>
      <label>Time out<input name="time_out" type="time"></label>
      <label class="span-2">Remarks<input name="remarks" maxlength="255"></label>
    </div>
    <div class="employee-form-actions"><button class="button" type="submit">Save attendance</button><button class="text-button" type="button" id="att-cancel">Cancel</button></div>
    <p class="employee-form-message" id="att-message" role="alert"></p>
  </form>

  <div class="table-wrap">
    <table>
      <thead><tr><th>Employee</th><th>Status</th><th>Time in</th><th>Time out</th><th>Hours</th><th>Overtime</th><th>Remarks</th><th></th></tr></thead>
      <tbody id="att-list"><tr><td colspan="8" class="salary-no-records">Loading…</td></tr></tbody>
    </table>
  </div>
</section>
