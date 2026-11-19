<div class="admin-stack">
  <section class="panel">
    <div class="panel-title">
      <div>
        <h2>Applicants</h2>
        <p>Applications submitted through the website chat. Approving creates the employee record.</p>
      </div>
    </div>
    <div class="table-wrap">
      <table class="salary-table">
        <thead><tr><th>Applicant</th><th>Position</th><th>Contact</th><th>Date applied</th><th>Status</th><th></th></tr></thead>
        <tbody id="applicant-list"><tr><td colspan="6" class="salary-no-records">Loading…</td></tr></tbody>
      </table>
    </div>
  </section>

  <section class="panel">
    <div class="panel-title">
      <div>
        <h2>Job openings</h2>
        <p>Only open positions can be chosen by applicants.</p>
      </div>
    </div>
    <form class="admin-toolbar" id="opening-form">
      <label class="grow">Position<input name="description" required maxlength="255" placeholder="e.g. Cashier"></label>
      <label>Slots<input name="slots" type="number" min="1" max="999" value="1" style="width:90px"></label>
      <button class="button" type="submit">Add opening</button>
    </form>
    <div class="table-wrap">
      <table class="salary-table" style="min-width:0">
        <thead><tr><th>Position</th><th>Slots</th><th>Status</th><th></th></tr></thead>
        <tbody id="opening-list"></tbody>
      </table>
    </div>
  </section>
</div>
