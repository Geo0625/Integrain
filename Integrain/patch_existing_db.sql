-- =====================================================================
-- Integrain: patch for a database that was ALREADY imported from the original dump.
-- Safe to run more than once. (A fresh install should import integrain_db.sql instead.)
-- Run it with the integrain_db database selected, e.g. in phpMyAdmin > SQL.
-- =====================================================================
USE `integrain_db`;

-- 1. Five tables lost their ENGINE / CHARSET in the original dump -> make them match the rest.
ALTER DATABASE `integrain_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `attendance_records`   CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `login_logs`           CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `payroll_transactions` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `pay_requests`         CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE `users`                CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 2. Placeholder password hashes -> real bcrypt hashes (dev defaults, CHANGE THEM after first login)
--    admin / msantos : Admin@12345      jdelacruz / preyes : Staff@12345
UPDATE `users` SET `password_hash` = '$2y$10$dgoVEIl1HWRBumx7uhSH5.UV459k8RTbf0Hc4UzhUlvy1ZQNRbjJC'
 WHERE `username` IN ('admin','msantos') AND `password_hash` LIKE '%REPLACE_WITH_REAL_HASH';
UPDATE `users` SET `password_hash` = '$2y$10$ZcXsBj5qjeeY5gOfivsf/OMOErOntY3lXnLv11VSVRpKvTYAe.cKq'
 WHERE `username` IN ('jdelacruz','preyes') AND `password_hash` LIKE '%REPLACE_WITH_REAL_HASH';

-- 3. Product categories now match the website filters (Regular / Well Milled / Premium)
UPDATE `product_categories` SET `category_name` = 'Regular' WHERE `category_id` = 1 AND `category_name` = 'Rice';
INSERT IGNORE INTO `product_categories` (`category_id`, `category_name`) VALUES (2, 'Well Milled'), (3, 'Premium');
UPDATE `products` SET `category_id` = 3 WHERE `product_code` IN ('RC-001','RC-002') AND `category_id` = 1;

-- 4. Store information that matches the website footer and map
UPDATE `store_settings` SET `setting_value` = 'Nasugbu, Batangas'            WHERE `setting_key` = 'address'     AND `setting_value` LIKE 'Update this%';
UPDATE `store_settings` SET `setting_value` = 'Mon - Sun, 5:00 AM to 5:00 PM' WHERE `setting_key` = 'store_hours' AND `setting_value` LIKE 'Update this%';
UPDATE `store_settings` SET `setting_value` = '14.038972'  WHERE `setting_key` = 'latitude'  AND `setting_value` = '14.0700';
UPDATE `store_settings` SET `setting_value` = '120.650472' WHERE `setting_key` = 'longitude' AND `setting_value` = '120.6330';

-- 5. Job openings for the positions the website offers
INSERT INTO `job_openings` (`description`, `slots`, `is_open`, `created_by`)
SELECT 'Cashier', 1, 1, 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `job_openings` WHERE `description` = 'Cashier');
INSERT INTO `job_openings` (`description`, `slots`, `is_open`, `created_by`)
SELECT 'Delivery staff', 1, 1, 1 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `job_openings` WHERE `description` = 'Delivery staff');
