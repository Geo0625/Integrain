/* Staff calendars: month grid coloured by attendance status, with a day-detail panel */
(function () {
  const { monthKey, monthData, showError } = Staff;


  function makeCalendar({ grid, label, prev, next, onSelect, onMonth }) {
    let month = new Date(); month.setDate(1);
    let selected = null;
    async function render() {
      label.textContent = month.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
      let data;
      try { data = await monthData(month); } catch (error) { showError(error); return; }
      const byDate = new Map(data.records.map(r => [r.attendance_date, r]));
      const first = new Date(month), blanks = first.getDay(), days = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
      const today = fmt.dateKey();
      let html = ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(d => `<b>${d}</b>`).join('') + '<span></span>'.repeat(blanks);
      for (let day = 1; day <= days; day++) {
        const key = `${monthKey(month)}-${String(day).padStart(2, '0')}`, rec = byDate.get(key);
        const cls = ['calendar-day'];
        if (rec) cls.push(['Present', 'Late', 'Half-Day'].includes(rec.attendance_status) ? 'marked' : rec.attendance_status === 'Absent' ? 'absent-day' : 'leave-day');
        if (rec && rec.holiday_name) cls.push('holiday-day');
        if (key === today) cls.push('today');
        if (key === selected) cls.push('selected');
        html += `<button type="button" class="${cls.join(' ')}" data-date="${key}">${day}${rec ? '<i></i>' : ''}</button>`;
      }
      grid.innerHTML = html;
      grid.querySelectorAll('[data-date]').forEach(btn => btn.addEventListener('click', () => { selected = btn.dataset.date; onSelect(selected, byDate.get(selected) || null); render(); }));
      if (selected && selected.startsWith(monthKey(month))) onSelect(selected, byDate.get(selected) || null);
    }
    const move = step => { month.setMonth(month.getMonth() + step); selected = null; render(); if (onMonth) onMonth(new Date(month)); };
    prev.addEventListener('click', () => move(-1));
    next.addEventListener('click', () => move(1));
    return { render, month: () => new Date(month), reset() { month = new Date(); month.setDate(1); selected = null; } };
  }

  const dayDetail = (ids, date, rec) => {
    $(ids.title).textContent = fmt.date(date);
    $(ids.status).textContent = rec ? (rec.holiday_name ? `${rec.attendance_status} · ${rec.holiday_name}` : rec.attendance_status) : 'No record';
    $(ids.in).textContent = rec ? fmt.time(rec.time_in) : '—';
    $(ids.out).textContent = rec ? fmt.time(rec.time_out) : '—';
    $(ids.hours).textContent = rec && rec.time_in && rec.time_out ? fmt.hours(rec.hours_worked) : '—';
  };

  Staff.makeCalendar = makeCalendar;
  Staff.dayDetail = dayDetail;
})();
