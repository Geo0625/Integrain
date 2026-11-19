<section class="page" id="staff-page" data-view="staff">
  <div class="portal-shell">
    <button class="sidebar-toggle" type="button" aria-label="Hide sidebar" aria-expanded="true">&#8249;</button>
    <?= $this->include('staff/partials/sidebar') ?>
    <div class="portal-content">
      <div class="portal-heading">
        <div><span class="eyebrow" data-today>&nbsp;</span>
          <h1 id="staff-heading">Welcome <span>&#9728;</span></h1>
          <p id="staff-subheading">Here's your personal overview.</p>
        </div><button class="avatar">&nbsp;</button>
      </div>
      <?= $this->include('staff/modules/overview') ?>
      <?= $this->include('staff/modules/transactions') ?>
      <?= $this->include('staff/modules/attendance') ?>
      <?= $this->include('staff/modules/salary') ?>
    </div>
  </div>
</section>
