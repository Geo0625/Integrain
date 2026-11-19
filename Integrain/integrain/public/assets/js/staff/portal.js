/* Staff portal navigation between its four pages */
(function () {
  const { $ } = Staff;


  function openSection(section) {
    if (!Staff.sections[section]) section = 'overview';
    document.querySelectorAll('#staff-page [data-staff-view]').forEach(view => { view.hidden = view.dataset.staffView !== section; });
    document.querySelectorAll('#staff-page [data-staff].side-link').forEach(link => {
      const selected = link.dataset.staff === section;
      link.classList.toggle('selected', selected);
      link.setAttribute('aria-current', selected ? 'page' : 'false');
    });
    if (section !== 'overview') { $('staff-heading').textContent = Staff.sections[section][0]; }
    $('staff-subheading').textContent = Staff.sections[section][1];
    if (section === 'overview') Staff.renderOverview();
    if (section === 'transactions') Staff.renderTransactions();
    if (section === 'attendance') Staff.renderStaffAttendance();
    if (section === 'salary') Staff.renderStaffSalary();
  }

  window.addEventListener('integrain-user-changed', event => {
    if (event.detail.role !== 'staff') return;
    Staff.attendanceCache.clear(); Staff.dashboard = null; Staff.overviewCalendar.reset(); Staff.attendanceCalendar.reset();
  });
  window.staffPortal = { openSection };

})();
