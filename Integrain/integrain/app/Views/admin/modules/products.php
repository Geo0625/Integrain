<section class="panel product-manager">
  <div class="panel-title">
    <div>
      <h2>Products</h2>
      <p>Add and edit the rice products shown on the website.</p>
    </div>
    <button class="button" type="button" data-product-form-toggle>+ Add rice</button>
  </div>

  <form class="product-form" id="product-form" hidden>
    <h3>Rice details</h3>
    <div class="product-form-grid">
      <label>Product name<input name="name" required maxlength="100" placeholder="e.g. Sinandomeng"></label>
      <label>Category<select name="category_id" required></select></label>
      <label>Price (₱)<input name="price" type="number" min="0" step="0.01" required placeholder="42"></label>
      <label>Unit<select name="unit" required>
          <option value="kg">Per kg</option>
          <option value="sack">Per sack</option>
        </select></label>
      <label>Description <span class="form-hint">(optional)</span><input name="description" maxlength="255"></label>
      <label>Product code <span class="form-hint">(blank = automatic)</span><input name="code" maxlength="20" placeholder="RC-000"></label>
      <label class="product-image-field">Product picture<input name="image" type="file" accept="image/jpeg,image/png,image/webp,image/gif"><small>Optional · JPG, PNG, WebP or GIF up to 5 MB</small></label>
      <div class="product-image-preview" id="product-image-preview">Picture preview</div>
      <label class="check-field" style="flex-direction:row;align-items:center;gap:9px"><input name="available" type="checkbox" checked style="width:auto;min-height:0"> Available for sale</label>
    </div>
    <div class="product-form-actions"><button class="button" type="submit">Save rice</button><button class="text-button"
        type="button" data-product-form-toggle>Cancel</button></div>
    <p class="product-form-message" id="product-form-message" role="alert"></p>
  </form>

  <div class="table-wrap">
    <table class="product-admin-table">
      <thead><tr><th>Product</th><th>Category</th><th>Price</th><th>Unit</th><th>Availability</th><th></th></tr></thead>
      <tbody id="admin-product-list"><tr><td colspan="6" class="salary-no-records">Loading…</td></tr></tbody>
    </table>
  </div>
</section>
