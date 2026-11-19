/* Small UI helpers shared by every part of the app. */
function toast(message) {
  const el = document.getElementById('toast');
  el.textContent = message;
  el.classList.add('show');
  clearTimeout(window.toastTimer);
  window.toastTimer = setTimeout(() => el.classList.remove('show'), 2600);
}
window.toast = toast;

function scrollPageToTop() {
  const root = document.documentElement;
  const previousScrollBehavior = root.style.scrollBehavior;
  root.style.scrollBehavior = 'auto';
  window.scrollTo(0, 0);
  root.scrollTop = 0;
  document.body.scrollTop = 0;
  requestAnimationFrame(() => { root.style.scrollBehavior = previousScrollBehavior; });
}
window.addEventListener('pageshow', scrollPageToTop);
