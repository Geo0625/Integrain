/* Confirm / prompt / info dialogs (used by the admin portal and by the log-out button). */
function adminDialog(id, html) {
  let dialog = document.getElementById(id);
  if (!dialog) {
    dialog = document.createElement('div');
    dialog.id = id; dialog.className = 'admin-confirm-overlay'; dialog.hidden = true;
    dialog.setAttribute('role', 'dialog'); dialog.setAttribute('aria-modal', 'true');
    document.body.append(dialog);
  }
  dialog.innerHTML = html;
  return dialog;
}

function confirmAdminAction(message) {
  const dialog = adminDialog('admin-confirm-dialog', '<div class="admin-confirm-panel"><p id="admin-confirm-message"></p><div class="admin-confirm-actions"><button type="button" class="button secondary" data-confirm-no>No</button><button type="button" class="button" data-confirm-yes>Yes</button></div></div>');
  dialog.querySelector('#admin-confirm-message').textContent = message;
  return new Promise(resolve => {
    const finish = answer => { dialog.hidden = true; dialog.removeEventListener('click', onClick); document.removeEventListener('keydown', onKey); resolve(answer); };
    const onClick = e => { if (e.target === dialog || e.target.closest('[data-confirm-no]')) finish(false); else if (e.target.closest('[data-confirm-yes]')) finish(true); };
    const onKey = e => { if (e.key === 'Escape') finish(false); };
    dialog.addEventListener('click', onClick); document.addEventListener('keydown', onKey);
    dialog.hidden = false; dialog.querySelector('[data-confirm-yes]').focus();
  });
}

/**
 * Small form dialog. askAdmin({ message, fields:[{name,label,type,value,required,options,min,step}], yes:'Save' })
 * resolves with an object of values, or null if cancelled. With info:true it only shows html and an OK button.
 */
function askAdmin({ message, fields = [], yes = 'Save', html = '', info = false, wide = false, validate }) {
  const fieldHtml = fields.map(f => {
    const input = f.type === 'select'
      ? `<select name="${f.name}">${f.options.map(o => `<option value="${fmt.esc(o.value ?? o)}"${(o.value ?? o) == f.value ? ' selected' : ''}>${fmt.esc(o.label ?? o)}</option>`).join('')}</select>`
      : f.type === 'textarea' ? `<textarea name="${f.name}" rows="3" maxlength="255">${fmt.esc(f.value ?? '')}</textarea>`
        : `<input name="${f.name}" type="${f.type || 'text'}" value="${fmt.esc(f.value ?? '')}"${f.required ? ' required' : ''}${f.min !== undefined ? ` min="${f.min}"` : ''}${f.step ? ` step="${f.step}"` : ''}${f.maxlength ? ` maxlength="${f.maxlength}"` : ''}>`;
    return `<label>${fmt.esc(f.label)}${input}</label>`;
  }).join('');
  const dialog = adminDialog('admin-prompt-dialog', `<form class="admin-confirm-panel" style="${wide ? 'width:min(100%,560px)' : ''}"><p>${fmt.esc(message)}</p>${html}<div class="prompt-fields">${fieldHtml}</div><p class="prompt-error" role="alert"></p><div class="admin-confirm-actions">${info ? '' : '<button type="button" class="button secondary" data-no>Cancel</button>'}<button type="submit" class="button">${info ? 'Close' : fmt.esc(yes)}</button></div></form>`);
  const form = dialog.querySelector('form');
  return new Promise(resolve => {
    const finish = value => { dialog.hidden = true; document.removeEventListener('keydown', onKey); resolve(value); };
    const onKey = e => { if (e.key === 'Escape') finish(null); };
    form.addEventListener('submit', e => {
      e.preventDefault();
      if (info) return finish(true);
      const values = Object.fromEntries(new FormData(form).entries());
      const error = validate ? validate(values) : null;
      if (error) { dialog.querySelector('.prompt-error').textContent = error; return; }
      finish(values);
    });
    dialog.addEventListener('click', e => { if (e.target === dialog || e.target.closest('[data-no]')) finish(info ? true : null); });
    document.addEventListener('keydown', onKey);
    dialog.hidden = false;
    const first = form.querySelector('input,select,textarea'); (first || form.querySelector('button[type=submit]')).focus();
  });
}
