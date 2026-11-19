/* Public product catalog + store info. Data comes from the CodeIgniter 4 API (products, product_categories, store_settings). */
let products = [];
let productCategories = [];
let activeProductFilter = 'All';

function productCard(product) {
  const esc = fmt.esc;
  const style = product.image ? ` style="background-image:url('${esc(product.image)}')"` : '';
  const photoClass = product.image ? '' : ' no-photo';
  const unavailable = !product.available;
  return `<article class="product-card${unavailable ? ' is-unavailable' : ''}"><div class="product-photo${photoClass}"${style}><span class="product-tag">${esc(product.category)}</span></div><div class="product-info"><h3>${esc(product.name)}</h3><div class="product-meta"><strong>${fmt.moneyShort(product.price)}<span style="font-size:10px;font-weight:500"> / ${esc(product.unit)}</span></strong><span>${unavailable ? 'Unavailable' : '★★★★★'}</span></div><button data-add="${esc(product.name)}"${unavailable ? ' disabled' : ''}>${unavailable ? 'Out of stock' : 'Add to basket&nbsp; +'}</button></div></article>`;
}

function renderProducts(target, list = products) {
  const element = document.getElementById(target);
  if (!element) return;
  element.innerHTML = list.length
    ? list.map(productCard).join('')
    : '<p style="grid-column:1/-1;color:var(--muted)">No rice products to show yet.</p>';
}

function renderProductFilters() {
  const box = document.getElementById('product-filters');
  if (!box) return;
  const names = ['All', ...productCategories.map(c => c.category_name)];
  if (!names.includes(activeProductFilter)) activeProductFilter = 'All';
  box.innerHTML = names.map(name => `<button class="filter${name === activeProductFilter ? ' active' : ''}" data-filter="${fmt.esc(name)}">${name === 'All' ? 'All rice' : fmt.esc(name)}</button>`).join('');
}

function renderProductLists() {
  renderProducts('home-products', products.filter(p => p.available).slice(0, 4));
  renderProducts('all-products', activeProductFilter === 'All' ? products : products.filter(p => p.category === activeProductFilter));
}

window.IntegrainProducts = {
  setFilter(name) { activeProductFilter = name; renderProductFilters(); renderProductLists(); },
  async reload() {
    try {
      [products, productCategories] = await Promise.all([api('products'), api('categories')]);
    } catch (error) {
      products = [];
      const grid = document.getElementById('all-products');
      if (grid) grid.innerHTML = `<p style="grid-column:1/-1;color:var(--muted)">${fmt.esc(error.message)}</p>`;
      return;
    }
    renderProductFilters();
    renderProductLists();
  }
};
window.addEventListener('integrain-products-updated', () => window.IntegrainProducts.reload());

/* Footer hours + map come from the store_settings table so they are edited in one place. */
async function loadStoreInfo() {
  try {
    const store = await api('store');
    window.storeInfo = store;
    if (store.store_hours) document.querySelectorAll('[data-store-hours]').forEach(el => { el.textContent = store.store_hours; });
    const lat = parseFloat(store.latitude), lng = parseFloat(store.longitude), map = document.getElementById('store-map');
    if (map && isFinite(lat) && isFinite(lng)) {
      const d = 0.00555;
      map.src = `https://www.openstreetmap.org/export/embed.html?bbox=${lng - d}%2C${lat - d}%2C${lng + d}%2C${lat + d}&layer=mapnik&marker=${lat}%2C${lng}`;
    }
  } catch { /* keep the static footer text */ }
}

window.IntegrainProducts.reload();
loadStoreInfo();
