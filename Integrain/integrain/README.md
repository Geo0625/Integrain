# Integrain – Jun & Bebot's Bigasan

Rice-retail website with an **admin** and **staff** portal, built with **CodeIgniter 4** and the **`integrain_db`** MariaDB database.

```text
Integrain/
├── integrain_db.sql          ← the database (import this first)
├── patch_existing_db.sql     ← only if you already imported the OLD dump
└── integrain/                ← the CodeIgniter 4 project (you run it from here)
    ├── app/                  controllers, models, views, filters, routes
    ├── public/               web root: index.php + assets/ (css, js, images) + uploads/
    ├── system/  writable/  spark  .env
    └── DOCUMENTATION.md      ← full guide: run steps, accounts, every change that was made
```

**Quick start** (details and troubleshooting are in `DOCUMENTATION.md`):

```bash
cd Integrain/integrain
mysql -u root -e "source ../integrain_db.sql"
php spark serve
# open http://localhost:8080/
```

Sign in with `admin` / `Admin@12345` (Admin) or `jdelacruz` / `Staff@12345` (Staff).
