# Integrain – Documentation

CodeIgniter 4 backend + Integrain frontend + `integrain_db` database.
This document explains **how to run it**, **which accounts to use**, **what you need to do**, and **every change that was made**.

**Contents**
1. [Folder layout](#1-folder-layout)
2. [Run it from the terminal (step by step)](#2-run-it-from-the-terminal-step-by-step)
3. [Accounts](#3-accounts)
4. [Things you need to do (checklists)](#4-things-you-need-to-do)
5. [Troubleshooting](#5-troubleshooting)
6. [Changes made – project structure (this revision)](#6-changes-made--project-structure)
7. [Changes made – backend and database](#7-changes-made--backend-and-database)
8. [Frontend ↔ database mismatches that were fixed](#8-frontendatabase-mismatches-that-were-fixed)
9. [Security measures](#9-security-measures)
10. [API reference](#10-api-reference)
11. [Testing](#11-testing)
12. [Decisions and limitations](#12-decisions-and-limitations)
13. [Going live](#13-going-live)

---

## 1. Folder layout

The layout follows the same idea as your RentEase project: the SQL file sits **next to** the framework project, views are grouped **per role** with a `partials/` folder, controllers are **one per feature**, and CSS/JS are split **by purpose**.

```text
Integrain/
├── integrain_db.sql                    database (import this)
├── patch_existing_db.sql               upgrade script for a database imported from the old dump
└── integrain/                          CodeIgniter 4 project
    ├── .env                            local settings (database login, base URL)
    ├── spark                           command-line tool (php spark …)
    ├── system/  writable/              framework + logs/cache/sessions (do not edit)
    ├── app/
    │   ├── Commands/SetPassword.php        php spark integrain:password
    │   ├── Config/
    │   │   ├── Routes.php                  entry point for routes
    │   │   ├── Routes/site.php admin.php staff.php      routes per area (like routes/web.php)
    │   │   ├── Validation.php              validation rules per form (like Laravel Form Requests)
    │   │   └── Filters.php Security.php Database.php …  (edited, see §7)
    │   ├── Controllers/
    │   │   ├── BaseController.php  ApiController.php    shared base classes
    │   │   ├── Home.php                                 serves the website page
    │   │   ├── Site/        Auth, Store, Applications, Chat
    │   │   ├── Admin/       Dashboard, Employees, Attendance, Products, Applicants,
    │   │   │                Payroll, PayRequests, Adjustments, PayrollRules, Reports, Modules
    │   │   └── Staff/       Dashboard, Attendance, Salary
    │   ├── Models/          StoreModel, UserModel, EmployeeModel, AttendanceModel,
    │   │                    ProductModel, ApplicantModel, PayrollModel
    │   ├── Filters/         AuthFilter (role check), ThrottleFilter (rate limit)
    │   ├── Libraries/       Proc.php (calls stored procedures), Chatbot.php
    │   ├── Helpers/         asset_helper.php  → asset('css/theme.css') with automatic cache-busting
    │   └── Views/
    │       ├── layouts/main.php                 HTML shell (head, scripts)
    │       ├── components/                      icon-sprite, toast, settings-dialog
    │       ├── site/        home.php + pages/ (home, login, products) + partials/ (nav, hero, benefits,
    │       │                featured-products, join-banner, store-location, footer, chat-widget)
    │       ├── admin/       shell.php + partials/sidebar.php + modules/ (dashboard, employees, attendance,
    │       │                products, applicants, salary, reports)
    │       └── staff/       shell.php + partials/sidebar.php + modules/ (overview, transactions, attendance, salary)
    └── public/                         the only folder the web server should expose
        ├── index.php  .htaccess
        ├── assets/
        │   ├── css/     theme, layout, landing, portal, store-pages, chat, responsive,
        │   │            staff-page, footer, account, admin, staff
        │   ├── js/
        │   │   ├── core/    api, ui, dialogs
        │   │   ├── site/    products, chat, navigation, session, settings, main
        │   │   ├── admin/   core, dashboard, employees, attendance, products, applicants, payroll, reports
        │   │   └── staff/   core, calendar, overview, transactions, attendance, salary, portal
        │   └── images/  bigasan.jpg
        └── uploads/products/           pictures uploaded by the admin
```

---

## 2. Run it from the terminal (step by step)

### What you need installed
- **PHP 8.2 or newer** with the extensions `intl`, `mbstring`, `mysqli`
- **MySQL or MariaDB** (XAMPP includes both PHP and MariaDB)

### Step 1 – Open a terminal in the project folder
- **Windows (XAMPP):** open *PowerShell* or *Command Prompt*, then
  ```powershell
  cd C:\xampp\htdocs\Integrain\integrain
  ```
  (use the folder where you extracted the zip)
- **Mac / Linux:**
  ```bash
  cd ~/Integrain/integrain
  ```

### Step 2 – Check PHP
```bash
php -v
```
It must say **PHP 8.2** or higher. Then check the extensions:
- Windows: `php -m | findstr /i "intl mbstring mysqli"`
- Mac/Linux: `php -m | grep -Ei "intl|mbstring|mysqli"`

All three names must appear. If `php` is "not recognized" on Windows, use the full path instead, e.g. `C:\xampp\php\php.exe -v`, and use that full path every time this guide says `php`.
If `intl` is missing in XAMPP: open `C:\xampp\php\php.ini`, remove the `;` in front of `extension=intl`, save, and open a new terminal.

### Step 3 – Start the database server
- **XAMPP:** open the XAMPP Control Panel → click **Start** next to **MySQL**.
- **Linux:** `sudo systemctl start mariadb`   ·   **Mac (Homebrew):** `brew services start mariadb`

### Step 4 – Import the database
From inside `Integrain/integrain`:
```bash
mysql -u root -e "source ../integrain_db.sql"
```
- On Windows without `mysql` in PATH use: `C:\xampp\mysql\bin\mysql.exe -u root -e "source ../integrain_db.sql"`
- If your MySQL `root` user has a password, add `-p` (it will ask for the password).

This creates the `integrain_db` database with all tables, procedures, views and sample data. Check it worked:
```bash
mysql -u root -e "SELECT username, role FROM integrain_db.users"
```
You should see 4 users.
*(Prefer a screen? Open phpMyAdmin → **Import** → choose `integrain_db.sql` → **Go**. Do not create the database first; the file creates it.)*

### Step 5 – Check the settings in `.env`
Open `.env` in any text editor. The defaults work with a fresh XAMPP:
```ini
app.baseURL = 'http://localhost:8080/'
database.default.hostname = localhost
database.default.database = integrain_db
database.default.username = root
database.default.password =
```
Change `database.default.password` only if your `root` user has a password.

### Step 6 – Start the website
```bash
php spark serve
```
Leave this window open. You will see `CodeIgniter development server started on http://localhost:8080`.

### Step 7 – Open it in the browser
Go to **http://localhost:8080/** and sign in with an account from [§3](#3-accounts) using the **Login** button.

### Step 8 – Stop the server
Click the terminal window and press **Ctrl + C**.

### Using a different port (if 8080 is busy)
```bash
php spark serve --port 8081
```
then change `app.baseURL` in `.env` to `'http://localhost:8081/'` and restart.

### Optional: run it through Apache/XAMPP instead of `spark serve`
1. Put the `Integrain` folder in `C:\xampp\htdocs\`.
2. In `.env` set `app.baseURL = 'http://localhost/Integrain/integrain/public/'`.
3. Start **Apache** and **MySQL** in the XAMPP Control Panel and open that address.

### Other useful terminal commands
| Command | What it does |
|---|---|
| `php spark integrain:password <username>` | Sets a new password for an account (asks for the password) |
| `php spark routes` | Lists every URL the app has |
| `php spark list` | Lists all spark commands |

---

## 3. Accounts

These are **development accounts**. Change them before real use ([§4](#4-things-you-need-to-do)).

| Role | Username | Password | Signs in as |
|---|---|---|---|
| **Admin** | `admin` | `Admin@12345` | Store Admin (no employee record) |
| **Admin** | `msantos` | `Admin@12345` | Maria Santos |
| **Staff** | `jdelacruz` | `Staff@12345` | Juan Dela Cruz |
| **Staff** | `preyes` | `Staff@12345` | Pedro Reyes |

- **Admin** sees the admin portal: Dashboard, Employees, Attendance, Products, Applicants, Payroll & Salary, Reports.
- **Staff** sees the staff portal: Overview, Transactions, Attendance, Salary & Requests.
- After 5 wrong passwords in 15 minutes an account is locked for about 15 minutes.

---

## 4. Things you need to do

### A. First-time setup
Follow [§2](#2-run-it-from-the-terminal-step-by-step), steps 1–7.

### B. You already imported the OLD `integrain_db.sql`
1. Make a backup: `mysqldump -u root integrain_db > backup.sql`
2. Run the patch: `mysql -u root -e "source ../patch_existing_db.sql"`  (works in PowerShell too)
3. Start the app (§2 step 6).
4. If the chat later answers *"Illegal mix of collations"*, the old database was created with a different collation. Fix: `mysql -u root -e "DROP DATABASE integrain_db"`, then do §2 step 4 again.

### C. Change the sample passwords (do this before real use)
1. In the terminal: `php spark integrain:password admin`
2. Type a new password (at least 8 characters) and press Enter.
3. Repeat for `msantos`, `jdelacruz` and `preyes`.

### D. Fill in the store contact number
The website and chatbot hide it until you set it.
1. Open phpMyAdmin → database `integrain_db` → table `store_settings`.
2. Edit the row where `setting_key` = `contact_no` and type the real number in `setting_value`.
3. Save, then reload the website.

### E. Give a login to a newly hired employee
Approving an applicant creates the employee **but not a login**.
1. Sign in as admin → **Applicants** → **Approve** (enter the daily rate).
2. Go to **Employees** → **Edit** on that person.
3. Under *Login account* type a username and a password (min. 8 characters), choose *Staff*, tick *Account is active* → **Save employee**.
4. Give the username and password to the employee.

### F. Computing payroll for the first time
1. **Back up the database first** (computed payroll cannot be undone).
2. Admin → **Payroll & Salary** → *Compute payroll* → check the period dates → **Compute**.
3. Review the table, then press **Release** on each salary (or approve a staff *Salary Request*).

### G. Optional – turn the debug toolbar back on while developing
Open `app/Config/Filters.php`, find the line `// Re-enable it while debugging by uncommenting: 'toolbar',` and add `'toolbar',` to the `'after'` list.

---

## 5. Troubleshooting

| Problem | Cause | What to do |
|---|---|---|
| Page opens but has **no styling / buttons do nothing** | `app.baseURL` in `.env` does not match the address in the browser | Make them identical, including the port and the trailing `/`, then restart `spark serve` |
| `Unknown database 'integrain_db'` | Database not imported | Do §2 step 4 |
| `Access denied for user 'root'` | `root` has a password | Put it in `database.default.password` in `.env` |
| `Class "Locale" not found` / intl error | `intl` extension off | §2 step 2 (enable `extension=intl`) |
| *"Illegal mix of collations"* in chat | Old database created with another collation | §4-B step 4 |
| Login says *"Too many failed attempts"* | 5 wrong passwords in 15 minutes | Wait ~15 minutes, or use the correct password |
| *"Your session expired. Reload the page"* (403) | Security token expired (browser kept an old page) | Reload the page (Ctrl+F5) |
| Product picture will not upload | `public/uploads/products` not writable | Give your user write permission on that folder (Linux/Mac: `chmod -R u+w public/uploads`) |
| `Address already in use` | Port 8080 busy | Use `--port 8081` (see §2) |
| Blank page / error 500 | A PHP or SQL error | Look at the newest file in `writable/logs/` |

---

## 6. Changes made – project structure

This revision reorganised the project; behaviour is unchanged (all 108 automated checks still pass).

### 6.1 Before → after
| Before | After |
|---|---|
| `codeigniter4/` root with an extra **`Integrain/`** folder (`frontend/`, `backend/`) inside it | `Integrain/` top folder containing **`integrain/`** (the CI4 project) and the SQL files beside it – same idea as `RentEase/rentease.sql` + `RentEase/rentease/` |
| `Integrain/frontend/views/index.html` (320 lines, everything in one file) | `app/Views/layouts/main.php` + `site/home.php` + **13 small partials/pages** |
| `Integrain/frontend/views/admin/*.html` and `staff/staff.html` | `app/Views/admin/modules/*.php`, `staff/modules/*.php` + sidebar partials + shells |
| `Integrain/frontend/public/css|js|images` served by a PHP `Assets` controller | Moved to **`public/assets/`** – served directly by the web server (faster, no PHP involved); `Assets` controller and `FRONTEND_PATH` constant **removed** |
| `styles.css` – one file of 2,694 lines | **10 files** by purpose: `theme, layout, landing, portal, store-pages, chat, responsive, staff-page, footer, account` (+ existing `admin.css`, `staff.css`) |
| `admin/controller.js` (≈480 lines) | `admin/core.js` + **7 section files** (dashboard, employees, attendance, products, applicants, payroll, reports) |
| `staff/controller.js` (≈190 lines, one closure) | `staff/core.js` + calendar, overview, transactions, attendance, salary, portal |
| `appController.js` (≈190 lines) | `core/ui.js`, `core/dialogs.js`, `site/navigation.js`, `site/session.js`, `site/settings.js`, `site/main.js` |
| `chatController.js`, `products.js`, `api.js` | `site/chat.js`, `site/products.js`, `core/api.js` |
| `Controllers/Api/…` (PublicApi, Payroll with 10 methods…) | `Controllers/Site`, `Admin`, `Staff`; **Payroll split** into `Payroll`, `PayRequests`, `Adjustments`, `PayrollRules` |
| Database queries written inside controllers | New **`app/Models/`** (7 models) – controllers only call models and procedures |
| Validation rules written inside controllers | Moved into **`Config\Validation`** groups (`employeeSave`, `attendanceSave`, …) |
| One long `Routes.php` | `Routes.php` + `Routes/site.php`, `admin.php`, `staff.php` |
| Admin screens loaded from a public static file (`/views/admin/x.html`) | Loaded from **`/admin/modules/{name}`**, which now **requires the Admin role** |
| Staff screen fetched at start-up with a loader script | Rendered directly inside the page (`staff/shell.php`); `loadView.js` removed |
| `database/` folder + `integrain_db.original.sql` | `integrain_db.sql` and `patch_existing_db.sql` next to the project; the original dump is no longer shipped (you still have your own copy) |

### 6.2 Why the CSS split is safe
`styles.css` was cut only at the boundaries between rules and the pieces are linked in the **same order** (`site/home.php` lists them), so the cascade is identical – the pieces joined back together are byte-for-byte the old file. Each file starts with a one-line comment saying what it contains.

### 6.3 Other additions in this revision
- `asset('css/theme.css')` helper adds `?v=<file time>` so browsers always load the latest file after you edit it.
- Script loading order is defined in one place (`app/Views/site/home.php`).

---

## 7. Changes made – backend and database

### 7.1 Database (`integrain_db.sql`)
I imported the dump into MariaDB and exercised every stored procedure (advances, payroll, attendance lock, release trigger, salary requests, 13th month, applicants, dashboards, chat). **The tables, keys, views, procedures and triggers are logically correct.** Problems were in the data and in how the file was exported:

| # | Problem found | Fix |
|---|---|---|
| D1 | All 4 accounts had the placeholder password hash `REPLACE_WITH_REAL_HASH` – nobody could log in | Real bcrypt hashes (passwords in §3) |
| D2 | 5 tables (`attendance_records`, `login_logs`, `payroll_transactions`, `pay_requests`, `users`) were exported without `ENGINE`/`CHARSET`; if the database wasn't `utf8mb4_unicode_ci` the chat failed with *Illegal mix of collations* (reproduced) | Tables completed; file now starts with `CREATE DATABASE … utf8mb4_unicode_ci` + `ALTER DATABASE` |
| D3 | Only category `Rice`, but the site filters are Regular / Well Milled / Premium | Categories are Regular / Well Milled / Premium; Dinorado & Jasmine → Premium |
| D4 | Store hours/address were `Update this: …`; map coordinates differed from the website's | Hours `Mon - Sun, 5:00 AM to 5:00 PM`, address `Nasugbu, Batangas`, coordinates of the website marker |
| D5 | Only "Store staff" was open; the site offers Store Staff, Cashier, Delivery Staff | Added *Cashier* and *Delivery staff* openings |

No table, view, procedure or trigger was changed – only data and the export problems above.

Behaviour of the database to be aware of: computed payroll is permanent (no undo procedure); *compute all* creates a ₱0 record for an employee with no attendance; approving an applicant does not create a login; employees can't be deleted (set *Inactive/Resigned*); `contact_no` is still a placeholder (see §4-D).

### 7.2 How the backend works
- The database already holds the business rules (stored procedures), so controllers **call them** through `App\Libraries\Proc` instead of re-implementing them in PHP.
- `Proc` runs `CALL sp_*()`, reads **all** result sets, drains the connection, converts numbers and forces Philippine time (+08:00).
- PHP adds: authentication, sessions, role checks, validation, CSRF, file upload and the JSON API.
- Rules added by the backend: time in/out uses the **server clock**; employee code (`EMP-0001`) and product code (`RC-001`) are generated when blank and never change on edit; a login account is validated **before** the employee is saved (no half-saved records); computing an already-computed period gives a clear error.

### 7.3 Configuration changes
| File | Change |
|---|---|
| `.env` (new) | environment, base URL, time zone `Asia/Manila`, database login, lockout limit |
| `app/Config/Routes.php` + `Routes/*.php` | frontend + `/api` routes with filters (auto-routing off) |
| `app/Config/Filters.php` | `csrf` and `secureheaders` on every request; aliases `auth`, `throttle`; debug toolbar off |
| `app/Config/Security.php` | CSRF token kept in the session, not regenerated each request (single-page app), no redirect on failure |
| `app/Config/Database.php` | defaults `root` / `integrain_db`, `utf8mb4_unicode_ci`, `numberNative = true` |
| `app/Config/Autoload.php` | loads the `asset` helper |
| `app/Config/Validation.php` | one rule group per form |
| `public/uploads/.htaccess` | blocks script execution in the upload folder |

### 7.4 New spark command
`php spark integrain:password <username> [new-password]` – set/reset a password (min. 8 chars). Login history is never edited; a lockout lifts by itself after 15 minutes.

---

## 8. Frontend↔database mismatches that were fixed

The frontend was a demo (data in `localStorage`, invented payroll formulas). Where it disagreed with the database, **the database won**, because it carries the business rules.

| # | Frontend (before) | Database | Resolution |
|---|---|---|---|
| M1 | Login by **email**, any password worked | `users.username`, bcrypt | Username login with a real password check |
| M2 | If the server was down, `enterDemoLocally()` **logged anyone in as admin** | – | **Removed** (security hole); sessions are server-side |
| M3 | Products: `type`, `weight`, `photo`, 8 hard-coded items in `localStorage` | `category_id`, `unit`, `unit_price`, `image_path`, `product_code`, `is_available` | Catalog from the API; filters built from categories; save via `sp_save_product` |
| M4 | Pictures stored as Base64 in the browser | `image_path VARCHAR(255)` | Real upload (JPG/PNG/WebP/GIF ≤ 5 MB, checked on the server) |
| M5 | Employee: name, **position**, **birthday**, **age**, **picture**, monthly **salary** + **allowance** | code, first/middle/last name, contact, email, address, `date_hired`, `daily_rate`, status | Form/table use the database fields; **position, birthday, age, picture, allowance removed** (no columns; see §12) |
| M6 | Pay = ₱12,000 + ₱2,000, 22 days × 8 h | days × daily rate + overtime + holiday + bonus − advances | Payroll screens use `sp_compute_salary*`, payslips, release |
| M7 | Attendance stamps kept in memory | `TIME` fields, status, overtime, payroll lock | Time in/out buttons + full Attendance screen; locked days shown with 🔒 |
| M8 | Advance requests browser-only, max ₱12,000 | `pay_requests` (*Paycheck Advance*, *Salary Request*) | Staff request advance or salary release; admin approves/rejects with a note |
| M9 | Applicants were demo data; chat asked one "full name" | first + last name; positions from `job_openings` | Chat asks first name, last name, phone, email, position (from DB), message → `sp_submit_application` |
| M10 | Chat answers canned and **contradicted the footer** (7 AM–8 PM vs 5 AM–5 PM) | chat tables + `store_settings` | Messages stored; answers built from the database |
| M11 | Footer hours and map hard-coded | `store_settings` | Loaded from the API |
| M12 | Dashboard numbers, dates, badge "3", "Maria Reyes" hard-coded | – | All live data |
| M13 | Absolute URLs (`/api`, `../public`) only worked at the site root | – | `appUrl()` / `api()` work at any base URL |

---

## 9. Security measures
- **CSRF** protection on every POST (token in the session, sent in the `X-CSRF-TOKEN` header).
- **Passwords**: bcrypt; unknown usernames and wrong passwords give the same message and take the same time.
- **Lockout**: 5 failed sign-ins in 15 minutes → HTTP 429; every attempt is written to `login_logs`.
- **Session**: id regenerated on login, destroyed on logout.
- **Authorization**: `auth:admin` / `auth:staff` filters on every route, including the admin screen fragments. A staff member's `employee_id` always comes from the session, never from the request. An admin cannot demote or deactivate their own account.
- **Rate limits** (per IP): login 15/min, chat 20–30/min, job applications 5 per 10 min.
- **SQL injection**: values are escaped before `CALL`; procedure names are whitelisted; other queries use bound parameters.
- **Validation** on every write (types, lengths, enums, dates, amounts) plus the database's own rules.
- **Uploads**: type detected on the server, size limit, random file names, scripts blocked in the folder.
- **Chat**: the browser keeps a random token; only its **SHA-256 hash** is stored; the conversation is always derived from it.
- **Errors**: messages written by the procedures are shown; any other database error is logged and replaced by a generic message.
- Security headers on; debug toolbar off; all dynamic text is HTML-escaped in the frontend.

---

## 10. API reference
All responses are JSON. Errors: `{ "message": "…" }` with 401 (not signed in), 403 (wrong role / CSRF), 409 (duplicate), 422 (invalid), 429 (too many requests). Routes are defined in `app/Config/Routes/`.

**Public & login** (`Routes/site.php`)
| Method & path | Purpose |
|---|---|
| `GET /api/store`, `/api/products`, `/api/categories`, `/api/jobs` | website data |
| `POST /api/applications` | job application |
| `POST /api/chat/history`, `/api/chat/messages` | chat |
| `POST /api/auth/login`, `/api/auth/logout`, `GET /api/auth/me` | session |

**Admin** (`Routes/admin.php`, prefix `/api/admin`, plus `GET /admin/modules/{name}` for the HTML of each screen)
`dashboard`, `summary` · `employees` (GET, POST, POST `/{id}`) · `attendance` (GET, POST, `clock`, `mark-present`) · `products` (GET, POST, POST `/{id}`, `/{id}/availability`), `categories` · `applicants` (GET, `/{id}/decision`), `job-openings` · `payroll` (GET, `compute`, `/{id}/release`, `/{id}/payslip`) · `requests/{id}/decision` · `adjustments`, `adjustments/{id}/cancel` · `payroll-settings`, `holidays`, `holidays/remove` · `reports?from=&to=`

**Staff** (`Routes/staff.php`, prefix `/api/staff`)
`dashboard` · `attendance?month=YYYY-MM` · `transactions` · `salary` · `requests` (POST)

---

## 11. Testing
After the restructure the whole suite was run again on a fresh database:
- **82 API checks** (real HTTP with cookies and CSRF): login/lockout/CSRF, role isolation, every admin and staff endpoint, validation errors, duplicates, file upload (valid and malicious), chat, applications, payroll math (e.g. 1.5 h overtime at ₱500/day = ₱117.19), advance deduction, attendance lock, salary release.
- **26 UI checks** (the real page and scripts in a simulated browser): home data, filters, login errors, every admin section, adding an employee through the form, time-in button, logout, all staff pages, advance request, session restore after refresh.
- All 36 CSS/JS/image URLs used by the page return 200; the four accounts in §3 were each signed in successfully; the terminal steps in §2 were run exactly as written.
- Bugs found and fixed by the tests: missing `message` on job applications, employee code regenerated on edit, orphan employee when the account was invalid, wrong "computed" count for an already-computed period.
- Not testable here (no internet / no real browser): Google Fonts, the OpenStreetMap iframe and the visual look. **Please click through the pages once in your own browser.**

---

## 12. Decisions and limitations
1. **Removed employee fields** *Position, Birthday, Age, Picture, Allowance* – the database has no columns for them and payroll doesn't use them. To bring them back: add the columns, extend `sp_save_employee`, then add the inputs in `app/Views/admin/modules/employees.php` and `public/assets/js/admin/employees.js`.
2. **Staff can't clock themselves in** – matches the database (admin entry) and the original UI.
3. Display name and time-format preferences stay **in the browser** (no table for them).
4. **Computed payroll is permanent** (database design).
5. Pay is per **period** (default 1st–15th or 16th–end of month, editable) because the database stores `period_start` / `period_end`.
6. The site is still one page that switches sections with JavaScript (as in the original design); only its files were reorganised.

## 13. Going live
1. In `.env`: `CI_ENVIRONMENT = production`, set the real `app.baseURL` (https) and turn on `Config\Cookie::$secure = true`.
2. Create a dedicated MySQL user (not `root`) with a strong password.
3. Point the web server's document root to `integrain/public/` only.
4. Change every sample password (§4-C) and fill in the contact number (§4-D).
5. Back up the database before the first payroll computation.
