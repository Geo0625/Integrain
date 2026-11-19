<!doctype html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#07583b">
  <meta name="app-base" content="<?= esc(base_url(), 'attr') ?>">
  <meta name="csrf-token" content="<?= esc(csrf_hash(), 'attr') ?>">
  <title><?= esc($title ?? "Integrain | Jun & Bebot's Rice Retailer") ?></title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link
    href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&family=Playfair+Display:wght@600;700&display=swap"
    rel="stylesheet">
  <?= $this->renderSection('styles') ?>
</head>

<body>
  <?= $this->include('components/icon-sprite') ?>
  <?= $this->renderSection('content') ?>
  <?= $this->include('components/toast') ?>
  <?= $this->include('components/settings-dialog') ?>
  <?= $this->renderSection('scripts') ?>
</body>

</html>
