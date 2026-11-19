<section class="page" id="admin-page" data-view="admin">
  <div class="portal-shell">
    <button class="sidebar-toggle" type="button" aria-label="Hide sidebar" aria-expanded="true">&#8249;</button>
    <?= $this->include('admin/partials/sidebar') ?>
    <div class="portal-content">
      <div class="portal-heading">
        <div><span class="eyebrow" data-today>&nbsp;</span>
          <h1 id="admin-heading">Dashboard</h1>
          <p>Here's what's happening at your store today.</p>
        </div><button class="avatar">JB</button>
      </div>
      <div id="admin-module-content" aria-live="polite"></div>
    </div>
  </div>
</section>
