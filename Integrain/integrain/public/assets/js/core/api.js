/* Shared helpers: talks to the CodeIgniter 4 backend. Loaded before every other script. */
(function () {
  const base = (document.querySelector('meta[name="app-base"]') || {}).content || '/';
  let csrf = (document.querySelector('meta[name="csrf-token"]') || {}).content || '';

  class ApiError extends Error {
    constructor(message, status, errors) { super(message); this.status = status; this.errors = errors || {}; }
  }

  /** URL for a path inside the app (works under /, /codeigniter4/public/, etc.) */
  window.appUrl = path => base + String(path).replace(/^\//, '');

  /**
   * api('admin/employees')                                  GET
   * api('auth/login', { method:'POST', body:{...} })        JSON
   * api('admin/products', { method:'POST', form: FormData }) multipart
   */
  window.api = async function api(path, { method = 'GET', body, form } = {}) {
    const headers = { Accept: 'application/json', 'X-Requested-With': 'XMLHttpRequest', 'X-CSRF-TOKEN': csrf };
    const init = { method, headers, credentials: 'same-origin' };
    if (form) init.body = form;
    else if (body !== undefined) { headers['Content-Type'] = 'application/json'; init.body = JSON.stringify(body); }
    let response;
    try { response = await fetch(appUrl('api/' + path), init); }
    catch { throw new ApiError('The server could not be reached. Check your connection and try again.', 0); }
    let data = null;
    try { data = await response.json(); } catch { /* non-JSON response */ }
    if (!response.ok) {
      const message = (data && data.message) || (response.status === 403 ? 'Your session expired. Reload the page and try again.' : 'Something went wrong. Please try again.');
      if (response.status === 401 && path !== 'auth/login' && path !== 'auth/me') window.dispatchEvent(new CustomEvent('integrain-session-expired'));
      throw new ApiError(message, response.status, data && data.errors);
    }
    return data;
  };
  window.api.setCsrf = token => { if (token) csrf = token; };
  window.ApiError = ApiError;

  const entities = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
  const pad = n => String(n).padStart(2, '0');
  function timeFormat() {
    try { return JSON.parse(localStorage.getItem('integrain-settings'))?.timeFormat || '12-hour'; } catch { return '12-hour'; }
  }
  window.fmt = {
    esc: v => String(v ?? '').replace(/[&<>"']/g, c => entities[c]),
    money: n => '₱' + Number(n || 0).toLocaleString('en-PH', { minimumFractionDigits: 2, maximumFractionDigits: 2 }),
    moneyShort: n => '₱' + Number(n || 0).toLocaleString('en-PH', { minimumFractionDigits: 0, maximumFractionDigits: 2 }),
    /** 'HH:MM[:SS]' -> '8:05 AM' (or 24-hour, from the user's settings) */
    time(value) {
      if (!value) return '—';
      const [h, m] = String(value).split(':').map(Number);
      if (timeFormat() === '24-hour') return `${pad(h)}:${pad(m)}`;
      return `${h % 12 || 12}:${pad(m)} ${h < 12 ? 'AM' : 'PM'}`;
    },
    /** 'YYYY-MM-DD[ HH:MM:SS]' -> 'Oct 3, 2026' */
    date(value) {
      if (!value) return '—';
      const d = new Date(String(value).slice(0, 10) + 'T00:00:00');
      return isNaN(d) ? '—' : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    },
    dateKey(d = new Date()) { return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`; },
    longDate: (d = new Date()) => d.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' }),
    hours: h => `${Math.floor(h)}h ${pad(Math.round((h % 1) * 60))}m`
  };
})();
