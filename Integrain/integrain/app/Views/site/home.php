<?= $this->extend('layouts/main') ?>

<?= $this->section('styles') ?>
<?php
// Same order as they were written, so the cascade is unchanged.
foreach (['theme', 'layout', 'landing', 'portal', 'store-pages', 'chat', 'responsive', 'staff-page', 'footer', 'account', 'admin', 'staff'] as $sheet): ?>
  <link rel="stylesheet" href="<?= asset("css/{$sheet}.css") ?>">
<?php endforeach ?>
<?= $this->endSection() ?>

<?= $this->section('content') ?>
<?= $this->include('site/partials/nav') ?>
<main>
  <?= $this->include('site/pages/home') ?>
  <?= $this->include('site/pages/login') ?>
  <?= $this->include('staff/shell') ?>
  <?= $this->include('admin/shell') ?>
  <?= $this->include('site/pages/products') ?>
</main>
<?= $this->include('site/partials/footer') ?>
<?= $this->include('site/partials/chat-widget') ?>
<?= $this->endSection() ?>

<?= $this->section('scripts') ?>
<?php
// Load order matters: core -> site data -> admin -> staff -> navigation/session -> main.
foreach ([
    'core/api', 'core/ui', 'core/dialogs',
    'site/products', 'site/chat',
    'admin/core', 'admin/dashboard', 'admin/employees', 'admin/attendance', 'admin/products', 'admin/applicants', 'admin/payroll', 'admin/reports',
    'staff/core', 'staff/calendar', 'staff/overview', 'staff/transactions', 'staff/attendance', 'staff/salary', 'staff/portal',
    'site/navigation', 'site/session', 'site/settings', 'site/main',
] as $script): ?>
  <script src="<?= asset("js/{$script}.js") ?>" defer></script>
<?php endforeach ?>
<?= $this->endSection() ?>
