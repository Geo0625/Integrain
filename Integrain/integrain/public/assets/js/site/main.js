/* Runs last: today's date labels and restoring the signed-in session after a page refresh. */
document.querySelectorAll('[data-today]').forEach(el => { el.textContent = fmt.longDate(); });
api('auth/me').then(user => { activateUser(user); showPage(user.role); }).catch(() => {});
