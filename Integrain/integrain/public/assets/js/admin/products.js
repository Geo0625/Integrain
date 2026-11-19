/* ================= Products ================= */
async function initProducts(root) {
  const form = root.querySelector('#product-form'), list = root.querySelector('#admin-product-list'), message = root.querySelector('#product-form-message'), preview = root.querySelector('#product-image-preview');
  let items = [], editing = null;
  const categories = await api('categories');
  form.category_id.innerHTML = categories.map(c => `<option value="${c.category_id}">${fmt.esc(c.category_name)}</option>`).join('');

  const closeForm = () => { form.hidden = true; form.classList.remove('is-editing'); editing = null; };
  function openForm(p) {
    editing = p; form.reset(); message.textContent = '';
    form.classList.toggle('is-editing', Boolean(p));
    form.querySelector('h3').textContent = p ? `Edit ${p.name}` : 'Rice details';
    preview.innerHTML = p && p.image ? `<img src="${fmt.esc(p.image)}" alt="">` : 'Picture preview';
    if (p) { form.elements.name.value = p.name; form.category_id.value = p.category_id; form.price.value = p.price; form.unit.value = p.unit; form.description.value = p.description || ''; form.code.value = p.code; form.available.checked = p.available; }
    form.hidden = false; form.elements.name.focus();
  }
  async function load() {
    items = await api('admin/products');
    list.innerHTML = items.length ? items.map(p => `<tr data-id="${p.id}"><td><div class="product-admin-name">${p.image ? `<img src="${fmt.esc(p.image)}" alt="">` : '<span class="product-admin-placeholder">RICE</span>'}<div><b>${fmt.esc(p.name)}</b><div class="table-note">${fmt.esc(p.code)}</div></div></div></td>
      <td>${fmt.esc(p.category)}</td><td>${fmt.money(p.price)}</td><td>per ${fmt.esc(p.unit)}</td>
      <td><button class="btn-small" type="button" data-toggle>${p.available ? pill('Available', 'approved') : pill('Unavailable', 'rejected')}</button></td>
      <td><div class="employee-row-actions"><button class="employee-edit" type="button" data-edit>Edit</button></div></td></tr>`).join('') : emptyRow(6, 'No products yet. Add your first rice above.');
  }
  root.querySelectorAll('[data-product-form-toggle]').forEach(b => b.addEventListener('click', () => form.hidden ? openForm(null) : closeForm()));
  form.image.addEventListener('change', () => {
    const file = form.image.files[0];
    if (file) preview.innerHTML = `<img src="${URL.createObjectURL(file)}" alt="">`;
  });
  list.addEventListener('click', async e => {
    const row = e.target.closest('tr[data-id]'); if (!row) return;
    const p = items.find(x => x.id === Number(row.dataset.id));
    if (e.target.closest('[data-edit]')) { openForm(p); form.scrollIntoView({ behavior: 'smooth', block: 'center' }); return; }
    const toggle = e.target.closest('[data-toggle]');
    if (toggle) await run(toggle, async () => { await api(`admin/products/${p.id}/availability`, { method: 'POST', body: { available: !p.available } }); window.dispatchEvent(new CustomEvent('integrain-products-updated')); await load(); });
  });
  form.addEventListener('submit', async e => {
    e.preventDefault(); message.textContent = '';
    const fd = new FormData(form); fd.set('available', form.available.checked ? '1' : '0');
    if (!form.image.files.length) fd.delete('image');
    if (!fd.get('code')) fd.delete('code');
    await run(form.querySelector('[type=submit]'), async () => {
      try {
        await api(editing ? `admin/products/${editing.id}` : 'admin/products', { method: 'POST', form: fd });
        toast(editing ? 'Product updated.' : 'Product added.'); closeForm();
        window.dispatchEvent(new CustomEvent('integrain-products-updated')); await load();
      } catch (error) { message.textContent = error.message; }
    });
  });
  await load();
}
