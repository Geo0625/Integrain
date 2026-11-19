/* Staff portal: shared helpers and state. Every number comes from the CodeIgniter 4 API (/api/staff/*).
   The other files in this folder (calendar, overview, attendance, salary, portal) add to the Staff object. */
const Staff = (() => {
  const $ = id => document.getElementById(id);
  const monthKey = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  const attendanceCache = new Map();

  const sections = {
    overview: ['', 'Here is your personal overview.'],
    transactions: ['My Transactions', 'Your salary records and pay requests.'],
    attendance: ['My Attendance', 'Your work days and time records at a glance.'],
    salary: ['Salary & Requests', 'Review your pay and make advance or salary requests.']
  };

  const pillFor = status => ({ Released: 'status-paid', Approved: 'status-paid', Computed: 'status-pending', Pending: 'status-pending', Rejected: 'status-absent', Cancelled: 'status-absent' }[status] || 'status-complete');

  const dotFor = type => /advance|deduct/i.test(type) ? 'red-dot' : /bonus|13th/i.test(type) ? 'blue-dot' : 'green-dot';

  const showError = error => toast(error.message || 'Something went wrong.');

  async function monthData(month) {
    const key = monthKey(month);
    if (!attendanceCache.has(key)) attendanceCache.set(key, await api(`staff/attendance?month=${key}`));
    return attendanceCache.get(key);
  }

  return { $, esc: fmt.esc, money: fmt.money, monthKey, attendanceCache, dashboard: null, sections, pillFor, dotFor, showError, monthData };
})();
