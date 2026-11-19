-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 25, 2026 at 09:46 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

CREATE DATABASE IF NOT EXISTS `integrain_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER DATABASE `integrain_db` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `integrain_db`;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `integrain_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_add_adjustment` (IN `p_employee_id` INT, IN `p_type` ENUM('Bonus','13th Month Pay'), IN `p_amount` DECIMAL(10,2), IN `p_remarks` VARCHAR(255), IN `p_admin_user_id` INT)   BEGIN
    DECLARE v_amount DECIMAL(12,2);
    IF NOT EXISTS (SELECT 1 FROM employees
                    WHERE employee_id = p_employee_id AND employment_status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found or inactive.';
    END IF;
    IF p_type = '13th Month Pay' AND EXISTS (
           SELECT 1 FROM pay_adjustments
            WHERE employee_id = p_employee_id AND adjustment_type = '13th Month Pay'
              AND YEAR(created_at) = YEAR(CURDATE())) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '13th month pay was already added for this employee this year.';
    END IF;
    SET v_amount = p_amount;
    IF v_amount IS NULL AND p_type = '13th Month Pay' THEN
        SET v_amount = fn_thirteenth_month_pay(p_employee_id, YEAR(CURDATE()));
    END IF;
    IF v_amount IS NULL OR v_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amount must be greater than zero.';
    END IF;
    INSERT INTO pay_adjustments (employee_id, adjustment_type, amount, remarks, created_by)
    VALUES (p_employee_id, p_type, v_amount, p_remarks, p_admin_user_id);
    SELECT LAST_INSERT_ID() AS adjustment_id, v_amount AS amount;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_admin_dashboard` ()   BEGIN
    SELECT
      (SELECT COUNT(*) FROM employees WHERE employment_status = 'Active')            AS active_employees,
      (SELECT COUNT(*) FROM attendance_records
        WHERE attendance_date = CURDATE()
          AND attendance_status IN ('Present','Late','Half-Day'))                    AS present_today,
      (SELECT COUNT(*) FROM applicants WHERE application_status = 'Pending')         AS pending_applicants,
      (SELECT COUNT(*) FROM pay_requests WHERE request_status = 'Pending')           AS pending_requests,
      (SELECT IFNULL(SUM(net_pay), 0) FROM v_payroll_detail
        WHERE YEAR(period_end) = YEAR(CURDATE())
          AND MONTH(period_end) = MONTH(CURDATE()))                                  AS payroll_this_month,
      (SELECT IFNULL(SUM(net_pay), 0) FROM v_payroll_detail
        WHERE payment_status = 'Computed')                                           AS unreleased_salaries,
      (SELECT IFNULL(SUM(outstanding_amount), 0) FROM v_outstanding_advances)        AS outstanding_advances,
      (SELECT COUNT(*) FROM products WHERE is_available = 0)                         AS unavailable_products,
      (SELECT COUNT(*) FROM login_logs
        WHERE login_status = 'Failed' AND DATE(attempted_at) = CURDATE())             AS failed_logins_today;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_attendance_report` (IN `p_from` DATE, IN `p_to` DATE)   BEGIN
    SELECT e.employee_code, CONCAT(e.first_name,' ',e.last_name) AS employee_name,
           SUM(ar.attendance_status = 'Present')  AS present_days,
           SUM(ar.attendance_status = 'Late')     AS late_days,
           SUM(ar.attendance_status = 'Half-Day') AS half_days,
           SUM(ar.attendance_status = 'Absent')   AS absent_days,
           SUM(ar.attendance_status = 'On Leave') AS leave_days,
           IFNULL(SUM(ar.hours_worked), 0)        AS total_hours,
           IFNULL(SUM(ar.overtime_hours), 0)      AS total_overtime
      FROM employees e
      LEFT JOIN attendance_records ar
        ON ar.employee_id = e.employee_id
       AND ar.attendance_date BETWEEN IFNULL(p_from,'1000-01-01') AND IFNULL(p_to,'9999-12-31')
     GROUP BY e.employee_id, e.employee_code, e.first_name, e.last_name
     ORDER BY e.last_name;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_cancel_adjustment` (IN `p_adjustment_id` INT)   BEGIN
    DELETE FROM pay_adjustments WHERE adjustment_id = p_adjustment_id AND transaction_id IS NULL;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Adjustment not found or already included in a salary.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_chat_add_message` (IN `p_conversation_id` INT, IN `p_sender` ENUM('Visitor','Chatbot'), IN `p_text` TEXT, IN `p_product_id` INT)   BEGIN
    DECLARE v_id BIGINT;
    IF NOT EXISTS (SELECT 1 FROM chat_conversations WHERE conversation_id = p_conversation_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Conversation not found.';
    END IF;
    IF p_text IS NULL OR CHAR_LENGTH(TRIM(p_text)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Message is empty.';
    END IF;
    IF CHAR_LENGTH(p_text) > 4000 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Message is too long (4000 characters max).';
    END IF;
    INSERT INTO chat_messages (conversation_id, sender, message_text, product_id)
    VALUES (p_conversation_id, p_sender, p_text, p_product_id);
    SET v_id = LAST_INSERT_ID();
    UPDATE chat_visitors v JOIN chat_conversations c ON c.visitor_id = v.visitor_id
       SET v.last_seen = NOW()
     WHERE c.conversation_id = p_conversation_id;
    SELECT v_id AS message_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_chat_get_history` (IN `p_conversation_id` INT, IN `p_limit` INT)   BEGIN
    IF p_limit IS NULL OR p_limit < 1 THEN SET p_limit = 20; END IF;
    IF p_limit > 100 THEN SET p_limit = 100; END IF;
    SELECT t.message_id, t.sender, t.message_text, t.created_at
      FROM (SELECT message_id, sender, message_text, created_at
              FROM chat_messages WHERE conversation_id = p_conversation_id
             ORDER BY created_at DESC, message_id DESC LIMIT p_limit) t
     ORDER BY t.created_at, t.message_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_chat_new_conversation` (IN `p_visitor_id` INT)   BEGIN
    IF NOT EXISTS (SELECT 1 FROM chat_visitors WHERE visitor_id = p_visitor_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Visitor not found.';
    END IF;
    INSERT INTO chat_conversations (visitor_id) VALUES (p_visitor_id);
    SELECT LAST_INSERT_ID() AS conversation_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_chat_open_session` (IN `p_token_hash` CHAR(64))   BEGIN
    DECLARE v_visitor INT DEFAULT NULL;
    DECLARE v_conv INT DEFAULT NULL;
    DECLARE v_new TINYINT DEFAULT 0;
    IF p_token_hash IS NULL OR p_token_hash NOT REGEXP '^[0-9a-f]{64}$' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid token hash.';
    END IF;
    SELECT visitor_id INTO v_visitor FROM chat_visitors WHERE token_hash = p_token_hash;
    IF v_visitor IS NULL THEN
        -- IGNORE keeps two simultaneous first requests with the same token from failing
        INSERT IGNORE INTO chat_visitors (token_hash) VALUES (p_token_hash);
        SET v_new = IF(ROW_COUNT() = 1, 1, 0);
        SELECT visitor_id INTO v_visitor FROM chat_visitors WHERE token_hash = p_token_hash;
    END IF;
    UPDATE chat_visitors SET last_seen = NOW() WHERE visitor_id = v_visitor;
    SELECT conversation_id INTO v_conv FROM chat_conversations
     WHERE visitor_id = v_visitor ORDER BY started_at DESC, conversation_id DESC LIMIT 1;
    IF v_conv IS NULL THEN
        INSERT INTO chat_conversations (visitor_id) VALUES (v_visitor);
        SET v_conv = LAST_INSERT_ID();
    END IF;
    SELECT v_visitor AS visitor_id, v_conv AS conversation_id, v_new AS is_new_visitor;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_chat_purge_old` (IN `p_days` INT)   BEGIN
    IF p_days IS NULL OR p_days < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Days must be at least 1.';
    END IF;
    DELETE FROM chat_visitors WHERE last_seen < NOW() - INTERVAL p_days DAY;
    SELECT ROW_COUNT() AS visitors_deleted;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_compute_salary` (IN `p_employee_id` INT, IN `p_start` DATE, IN `p_end` DATE, IN `p_admin_user_id` INT)   BEGIN
    DECLARE v_txn INT;
    CALL sp_compute_salary_core(p_employee_id, p_start, p_end, p_admin_user_id, v_txn);
    SELECT * FROM v_salary_report WHERE transaction_id = v_txn;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_compute_salary_all` (IN `p_start` DATE, IN `p_end` DATE, IN `p_admin_user_id` INT)   BEGIN
    DECLARE done INT DEFAULT 0; DECLARE v_emp INT; DECLARE v_txn INT;
    DECLARE cur CURSOR FOR
        SELECT employee_id FROM employees e
         WHERE employment_status = 'Active'
           AND NOT EXISTS (SELECT 1 FROM payroll_transactions p
                            WHERE p.employee_id = e.employee_id
                              AND p.period_start <= p_end AND p.period_end >= p_start);
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    IF p_end < p_start THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid period.';
    END IF;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_emp;
        IF done THEN LEAVE read_loop; END IF;
        CALL sp_compute_salary_core(v_emp, p_start, p_end, p_admin_user_id, v_txn);
    END LOOP;
    CLOSE cur;
    SELECT * FROM v_salary_report
     WHERE period_start = p_start AND period_end = p_end;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_compute_salary_core` (IN `p_employee_id` INT, IN `p_start` DATE, IN `p_end` DATE, IN `p_admin_user_id` INT, OUT `p_txn` INT)   BEGIN
    DECLARE v_rate DECIMAL(10,2);      DECLARE v_days DECIMAL(5,2);
    DECLARE v_work_hours DECIMAL(10,2); DECLARE v_ot_mult DECIMAL(10,2);
    DECLARE v_reg_mult DECIMAL(10,2);  DECLARE v_spc_mult DECIMAL(10,2);
    DECLARE v_ot_hours DECIMAL(5,2);   DECLARE v_ot_pay DECIMAL(12,2);
    DECLARE v_hol_pay DECIMAL(12,2);   DECLARE v_adj DECIMAL(12,2);
    DECLARE v_available DECIMAL(12,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;
    IF p_end < p_start THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid period.';
    END IF;
    START TRANSACTION;
    -- lock the employee row so two admins can't compute the same person at once
    SELECT daily_rate INTO v_rate FROM employees
     WHERE employee_id = p_employee_id FOR UPDATE;
    IF v_rate IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
    END IF;
    -- block exact duplicates AND overlapping periods (would double-pay the same days)
    IF EXISTS (SELECT 1 FROM payroll_transactions
                WHERE employee_id = p_employee_id
                  AND period_start <= p_end AND period_end >= p_start) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary already computed for this period (or an overlapping one).';
    END IF;
    -- pay rules
    SELECT setting_value INTO v_work_hours FROM payroll_settings WHERE setting_key = 'work_hours_per_day';
    SELECT setting_value INTO v_ot_mult    FROM payroll_settings WHERE setting_key = 'overtime_multiplier';
    SELECT setting_value INTO v_reg_mult   FROM payroll_settings WHERE setting_key = 'regular_holiday_multiplier';
    SELECT setting_value INTO v_spc_mult   FROM payroll_settings WHERE setting_key = 'special_holiday_multiplier';
    IF v_work_hours IS NULL OR v_ot_mult IS NULL OR v_reg_mult IS NULL OR v_spc_mult IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payroll settings are incomplete.';
    END IF;
    -- basic days, overtime, holiday premium
    SET v_days = fn_payable_days(p_employee_id, p_start, p_end);
    SELECT IFNULL(SUM(overtime_hours), 0) INTO v_ot_hours
      FROM attendance_records
     WHERE employee_id = p_employee_id AND attendance_date BETWEEN p_start AND p_end
       AND attendance_status IN ('Present','Late','Half-Day');
    SET v_ot_pay = ROUND(v_ot_hours * (v_rate / v_work_hours) * v_ot_mult, 2);
    -- the day itself is already paid in basic pay; a holiday adds only the extra (multiplier - 1)
    SELECT IFNULL(ROUND(SUM(
               CASE ar.attendance_status WHEN 'Present' THEN 1 WHEN 'Late' THEN 1
                                         WHEN 'Half-Day' THEN 0.5 ELSE 0 END
               * v_rate * (CASE h.holiday_type WHEN 'Regular' THEN v_reg_mult ELSE v_spc_mult END - 1)), 2), 0)
      INTO v_hol_pay
      FROM attendance_records ar
      JOIN holidays h ON h.holiday_date = ar.attendance_date
     WHERE ar.employee_id = p_employee_id AND ar.attendance_date BETWEEN p_start AND p_end;
    -- bonus / 13th month waiting to be included
    SELECT IFNULL(SUM(amount), 0) INTO v_adj FROM pay_adjustments
     WHERE employee_id = p_employee_id AND transaction_id IS NULL;
    -- advances can be deducted up to everything the employee earns this period
    SET v_available = ROUND(v_days * v_rate, 2) + v_ot_pay + v_hol_pay + v_adj;
    -- gross_pay is generated; advance_deduction and net_pay are derived in v_payroll_detail
    INSERT INTO payroll_transactions
        (employee_id, period_start, period_end, days_worked, daily_rate,
         overtime_hours, overtime_pay, holiday_pay, computed_by)
    VALUES (p_employee_id, p_start, p_end, v_days, v_rate,
            v_ot_hours, v_ot_pay, v_hol_pay, p_admin_user_id);
    SET p_txn = LAST_INSERT_ID();
    UPDATE pay_adjustments SET transaction_id = p_txn
     WHERE employee_id = p_employee_id AND transaction_id IS NULL;
    -- deduct approved Paycheck Advances oldest first; partial deduction allowed
    INSERT INTO advance_deductions (request_id, transaction_id, amount)
    SELECT r.request_id, p_txn, r.to_deduct
      FROM (SELECT q.request_id,
                   LEAST(q.remaining, GREATEST(0, v_available - (q.running - q.remaining))) AS to_deduct
              FROM (SELECT t.request_id, t.remaining,
                           SUM(t.remaining) OVER (ORDER BY t.decided_at, t.request_id) AS running
                      FROM (SELECT pr.request_id, pr.decided_at,
                                   pr.amount - IFNULL((SELECT SUM(ad.amount) FROM advance_deductions ad
                                                        WHERE ad.request_id = pr.request_id), 0) AS remaining
                              FROM pay_requests pr
                             WHERE pr.employee_id = p_employee_id
                               AND pr.request_type = 'Paycheck Advance'
                               AND pr.request_status = 'Approved') t
                     WHERE t.remaining > 0) q) r
     WHERE r.to_deduct > 0;
    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_decide_applicant` (IN `p_applicant_id` INT, IN `p_admin_user_id` INT, IN `p_decision` ENUM('Approved','Rejected','For Revision'), IN `p_daily_rate` DECIMAL(10,2), IN `p_remarks` VARCHAR(255))   BEGIN
    DECLARE v_first VARCHAR(60); DECLARE v_last VARCHAR(60);
    DECLARE v_email VARCHAR(100); DECLARE v_contact VARCHAR(20);
    DECLARE v_addr VARCHAR(255);
    DECLARE v_status VARCHAR(20); DECLARE v_new_id INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT first_name, last_name, email, contact_no, address, application_status
      INTO v_first, v_last, v_email, v_contact, v_addr, v_status
      FROM applicants WHERE applicant_id = p_applicant_id FOR UPDATE;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Applicant not found.';
    ELSEIF v_status NOT IN ('Pending','For Revision') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Applicant already decided.';
    END IF;
    UPDATE applicants
       SET application_status = p_decision, admin_remarks = p_remarks,
           decided_by = p_admin_user_id, decided_at = NOW()
     WHERE applicant_id = p_applicant_id;
    IF p_decision = 'Approved' THEN
        INSERT INTO employees (employee_code, first_name, last_name,
                               contact_no, email, address, date_hired, daily_rate)
        VALUES (CONCAT('EMP-', LPAD(
                    (SELECT IFNULL(MAX(CAST(SUBSTRING(e2.employee_code, 5) AS UNSIGNED)), 0) + 1
                       FROM employees e2
                      WHERE e2.employee_code REGEXP '^EMP-[0-9]+$'), 4, '0')),
                v_first, v_last, v_contact, v_email, v_addr,
                CURDATE(), IFNULL(p_daily_rate, 0));
        SET v_new_id = LAST_INSERT_ID();
    END IF;
    COMMIT;
    SELECT p_decision AS decision, v_new_id AS new_employee_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_attendance_history` (IN `p_employee_id` INT, IN `p_from` DATE, IN `p_to` DATE)   BEGIN
    SELECT * FROM v_attendance_history
     WHERE employee_id = p_employee_id
       AND attendance_date BETWEEN IFNULL(p_from,'1000-01-01') AND IFNULL(p_to,'9999-12-31')
     ORDER BY attendance_date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_login` (IN `p_username` VARCHAR(50))   BEGIN
    SELECT user_id, employee_id, username, password_hash, role, is_active,
           fn_recent_failed_logins(username, 15) AS failed_attempts_15min
      FROM users WHERE username = p_username;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_login_history` (IN `p_from` DATE, IN `p_to` DATE, IN `p_status` VARCHAR(10))   BEGIN
    SELECT * FROM v_login_history
     WHERE attempted_at >= IFNULL(p_from, '1000-01-01')
       AND attempted_at <  DATE_ADD(IFNULL(p_to, '9998-12-31'), INTERVAL 1 DAY)
       AND (p_status IS NULL OR login_status = p_status)
     ORDER BY attempted_at DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_payslip` (IN `p_transaction_id` INT)   BEGIN
    SELECT * FROM v_salary_report WHERE transaction_id = p_transaction_id;
    SELECT ad.request_id, pr.request_type, pr.reason, ad.amount AS deducted_amount
      FROM advance_deductions ad
      JOIN pay_requests pr ON pr.request_id = ad.request_id
     WHERE ad.transaction_id = p_transaction_id;
    SELECT adjustment_id, adjustment_type, remarks, amount
      FROM pay_adjustments WHERE transaction_id = p_transaction_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_pending_requests` ()   BEGIN
    SELECT * FROM v_pending_pay_requests;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_product_list` (IN `p_keyword` VARCHAR(100))   BEGIN
    SELECT * FROM v_product_list
     WHERE p_keyword IS NULL OR p_keyword = ''
        OR product_name LIKE CONCAT('%', p_keyword, '%')
        OR category     LIKE CONCAT('%', p_keyword, '%');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_salary_detail` (IN `p_employee_id` INT)   BEGIN
    SELECT pt.*, e.employee_code, CONCAT(e.first_name,' ',e.last_name) AS employee_name
      FROM v_payroll_detail pt
      JOIN employees e ON e.employee_id = pt.employee_id
     WHERE pt.employee_id = p_employee_id
     ORDER BY pt.period_end DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_transaction_history` (IN `p_employee_id` INT)   BEGIN
    SELECT * FROM v_transaction_history
     WHERE employee_id = p_employee_id
     ORDER BY txn_date DESC;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_mark_present_all` (IN `p_date` DATE, IN `p_admin_user_id` INT)   BEGIN
    DECLARE v_count INT;
    INSERT INTO attendance_records (employee_id, attendance_date, attendance_status, remarks)
    SELECT e.employee_id, p_date, 'Present', 'Bulk entry'
      FROM employees e
     WHERE e.employment_status = 'Active' AND e.date_hired <= p_date
       AND NOT EXISTS (SELECT 1 FROM attendance_records ar
                        WHERE ar.employee_id = e.employee_id AND ar.attendance_date = p_date)
       AND NOT EXISTS (SELECT 1 FROM payroll_transactions pt
                        WHERE pt.employee_id = e.employee_id
                          AND p_date BETWEEN pt.period_start AND pt.period_end);
    SET v_count = ROW_COUNT();
    INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
    VALUES ('attendance_records', 0, 'BULK_PRESENT',
            CONCAT(v_count, ' employee(s) marked Present on ', p_date), p_admin_user_id);
    SELECT v_count AS employees_marked_present;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_payroll_report` (IN `p_from` DATE, IN `p_to` DATE)   BEGIN
    SELECT * FROM v_salary_report
     WHERE period_end BETWEEN IFNULL(p_from,'1000-01-01') AND IFNULL(p_to,'9999-12-31');
    SELECT COUNT(*) AS records, IFNULL(SUM(gross_pay),0) AS total_gross,
           IFNULL(SUM(adjustments_total),0) AS total_bonus_13th,
           IFNULL(SUM(advance_deduction),0) AS total_advances, IFNULL(SUM(net_pay),0) AS total_net
      FROM v_payroll_detail
     WHERE period_end BETWEEN IFNULL(p_from,'1000-01-01') AND IFNULL(p_to,'9999-12-31');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_record_failed_login` (IN `p_username` VARCHAR(50))   BEGIN
    DECLARE v_uid INT DEFAULT NULL;
    SELECT user_id INTO v_uid FROM users WHERE username = p_username;
    INSERT INTO login_logs (user_id, username_entered, login_status)
    VALUES (v_uid, IF(v_uid IS NULL, p_username, NULL), 'Failed');
    SELECT fn_recent_failed_logins(p_username, 15) AS failed_attempts_15min;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_record_login` (IN `p_user_id` INT)   BEGIN
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';
    END IF;
    UPDATE users SET last_login = NOW() WHERE user_id = p_user_id;
    INSERT INTO login_logs (user_id, login_status)
    VALUES (p_user_id, 'Success');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_record_pay_request` (IN `p_employee_id` INT, IN `p_type` ENUM('Salary Request','Paycheck Advance'), IN `p_amount` DECIMAL(10,2), IN `p_reason` VARCHAR(255), IN `p_transaction_id` INT)   BEGIN
    DECLARE v_net DECIMAL(12,2); DECLARE v_status VARCHAR(20) DEFAULT NULL;
    IF NOT EXISTS (SELECT 1 FROM employees
                    WHERE employee_id = p_employee_id AND employment_status = 'Active') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found or inactive.';
    END IF;
    IF EXISTS (SELECT 1 FROM pay_requests
                WHERE employee_id = p_employee_id AND request_status = 'Pending') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You still have a pending request.';
    END IF;
    IF p_type = 'Salary Request' THEN
        SELECT net_pay, payment_status INTO v_net, v_status
          FROM v_payroll_detail
         WHERE transaction_id = p_transaction_id AND employee_id = p_employee_id;
        IF v_status IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary record not found.';
        ELSEIF v_status <> 'Computed' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'That salary was already released.';
        ELSEIF v_net <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nothing to release for that salary.';
        END IF;
        INSERT INTO pay_requests (employee_id, request_type, payroll_transaction_id, amount, reason)
        VALUES (p_employee_id, p_type, p_transaction_id, NULL, p_reason);
    ELSE
        IF p_amount IS NULL OR p_amount <= 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amount must be greater than zero.';
        END IF;
        INSERT INTO pay_requests (employee_id, request_type, amount, reason)
        VALUES (p_employee_id, p_type, p_amount, p_reason);
    END IF;
    SELECT LAST_INSERT_ID() AS request_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_release_salary` (IN `p_transaction_id` INT, IN `p_admin_user_id` INT)   BEGIN
    UPDATE payroll_transactions
       SET payment_status = 'Released', released_at = NOW(), released_by = p_admin_user_id
     WHERE transaction_id = p_transaction_id AND payment_status = 'Computed';
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary record not found or already released.';
    END IF;
    SELECT * FROM v_salary_report WHERE transaction_id = p_transaction_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_remove_holiday` (IN `p_date` DATE)   BEGIN
    DELETE FROM holidays WHERE holiday_date = p_date;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Holiday not found.';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_review_pay_request` (IN `p_request_id` INT, IN `p_admin_user_id` INT, IN `p_decision` ENUM('Approved','Rejected'), IN `p_remarks` VARCHAR(255))   BEGIN
    DECLARE v_type VARCHAR(20) DEFAULT NULL; DECLARE v_txn INT DEFAULT NULL;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    SELECT request_type, payroll_transaction_id INTO v_type, v_txn
      FROM pay_requests WHERE request_id = p_request_id AND request_status = 'Pending' FOR UPDATE;
    IF v_type IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Request not found or already decided.';
    END IF;
    UPDATE pay_requests
       SET request_status = p_decision, decided_by = p_admin_user_id,
           decided_at = NOW(), admin_remarks = p_remarks
     WHERE request_id = p_request_id;
    IF p_decision = 'Approved' AND v_type = 'Salary Request' THEN
        UPDATE payroll_transactions
           SET payment_status = 'Released', released_at = NOW(), released_by = p_admin_user_id
         WHERE transaction_id = v_txn AND payment_status = 'Computed';
    END IF;
    COMMIT;
    SELECT request_id, request_type, request_status FROM pay_requests WHERE request_id = p_request_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_attendance` (IN `p_employee_id` INT, IN `p_date` DATE, IN `p_time_in` TIME, IN `p_time_out` TIME, IN `p_status` ENUM('Present','Late','Half-Day','Absent','On Leave'), IN `p_overtime_hours` DECIMAL(5,2), IN `p_remarks` VARCHAR(255), IN `p_admin_user_id` INT)   BEGIN
    DECLARE v_id INT DEFAULT NULL;
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
    END IF;
    IF EXISTS (SELECT 1 FROM payroll_transactions
                WHERE employee_id = p_employee_id
                  AND p_date BETWEEN period_start AND period_end) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary for this date is already computed. Attendance is locked.';
    END IF;
    SELECT attendance_id INTO v_id FROM attendance_records
     WHERE employee_id = p_employee_id AND attendance_date = p_date;
    IF v_id IS NULL THEN
        INSERT INTO attendance_records (employee_id, attendance_date, time_in, time_out,
                                        attendance_status, overtime_hours, remarks)
        VALUES (p_employee_id, p_date, p_time_in, p_time_out, p_status,
                IFNULL(p_overtime_hours, 0), p_remarks);
        SET v_id = LAST_INSERT_ID();
        INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
        VALUES ('attendance_records', v_id, 'ADMIN_ENTRY',
                CONCAT('Added ', p_status, ' for employee ', p_employee_id, ' on ', p_date),
                p_admin_user_id);
    ELSE
        UPDATE attendance_records
           SET time_in = p_time_in, time_out = p_time_out, attendance_status = p_status,
               overtime_hours = IFNULL(p_overtime_hours, 0), remarks = p_remarks
         WHERE attendance_id = v_id;
        INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
        VALUES ('attendance_records', v_id, 'ADMIN_EDIT',
                CONCAT('Changed to ', p_status, ' for employee ', p_employee_id, ' on ', p_date),
                p_admin_user_id);
    END IF;
    SELECT * FROM v_attendance_history WHERE attendance_id = v_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_category` (IN `p_category_id` INT, IN `p_name` VARCHAR(50))   BEGIN
    IF p_category_id IS NULL THEN
        INSERT INTO product_categories (category_name) VALUES (p_name);
        SELECT LAST_INSERT_ID() AS category_id;
    ELSE
        UPDATE product_categories SET category_name = p_name WHERE category_id = p_category_id;
        SELECT p_category_id AS category_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_employee` (IN `p_employee_id` INT, IN `p_code` VARCHAR(20), IN `p_first` VARCHAR(60), IN `p_middle` VARCHAR(60), IN `p_last` VARCHAR(60), IN `p_contact` VARCHAR(20), IN `p_email` VARCHAR(100), IN `p_address` VARCHAR(255), IN `p_date_hired` DATE, IN `p_daily_rate` DECIMAL(10,2), IN `p_status` ENUM('Active','Inactive','Resigned'))   BEGIN
    IF p_employee_id IS NULL THEN
        INSERT INTO employees (employee_code, first_name, middle_name, last_name,
                               contact_no, email, address, date_hired, daily_rate, employment_status)
        VALUES (p_code, p_first, p_middle, p_last, p_contact, p_email,
                p_address, p_date_hired, p_daily_rate, IFNULL(p_status,'Active'));
        SELECT LAST_INSERT_ID() AS employee_id;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
        END IF;
        UPDATE employees
           SET employee_code = p_code, first_name = p_first, middle_name = p_middle,
               last_name = p_last, contact_no = p_contact,
               email = p_email, address = p_address, date_hired = p_date_hired,
               daily_rate = p_daily_rate, employment_status = IFNULL(p_status, employment_status)
         WHERE employee_id = p_employee_id;
        SELECT p_employee_id AS employee_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_holiday` (IN `p_date` DATE, IN `p_name` VARCHAR(100), IN `p_type` ENUM('Regular','Special'))   BEGIN
    INSERT INTO holidays (holiday_date, holiday_name, holiday_type)
    VALUES (p_date, p_name, p_type)
    ON DUPLICATE KEY UPDATE holiday_name = p_name, holiday_type = p_type;
    SELECT * FROM holidays WHERE holiday_date = p_date;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_job_opening` (IN `p_opening_id` INT, IN `p_description` VARCHAR(255), IN `p_slots` SMALLINT, IN `p_is_open` TINYINT, IN `p_admin_user_id` INT)   BEGIN
    IF p_opening_id IS NULL THEN
        INSERT INTO job_openings (description, slots, is_open, created_by)
        VALUES (p_description, IFNULL(p_slots, 1), IFNULL(p_is_open, 1), p_admin_user_id);
        SELECT LAST_INSERT_ID() AS opening_id;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM job_openings WHERE opening_id = p_opening_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job opening not found.';
        END IF;
        UPDATE job_openings
           SET description = p_description,
               slots = IFNULL(p_slots, slots), is_open = IFNULL(p_is_open, is_open)
         WHERE opening_id = p_opening_id;
        SELECT p_opening_id AS opening_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_payroll_setting` (IN `p_key` VARCHAR(50), IN `p_value` DECIMAL(10,2), IN `p_admin_user_id` INT)   BEGIN
    IF NOT EXISTS (SELECT 1 FROM payroll_settings WHERE setting_key = p_key) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unknown payroll setting.';
    END IF;
    UPDATE payroll_settings SET setting_value = p_value, updated_by = p_admin_user_id
     WHERE setting_key = p_key;
    SELECT setting_key, setting_value, description FROM payroll_settings WHERE setting_key = p_key;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_product` (IN `p_product_id` INT, IN `p_code` VARCHAR(20), IN `p_name` VARCHAR(100), IN `p_category_id` INT, IN `p_description` VARCHAR(255), IN `p_image` VARCHAR(255), IN `p_unit` VARCHAR(20), IN `p_price` DECIMAL(10,2), IN `p_available` TINYINT, IN `p_admin_user_id` INT)   BEGIN
    IF p_product_id IS NULL THEN
        INSERT INTO products (product_code, product_name, category_id, description, image_path, unit,
                              unit_price, is_available, updated_by)
        VALUES (p_code, p_name, p_category_id, p_description, p_image, p_unit,
                p_price, IFNULL(p_available, 1), p_admin_user_id);
        SELECT LAST_INSERT_ID() AS product_id;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found.';
        END IF;
        UPDATE products
           SET product_code = p_code, product_name = p_name, category_id = p_category_id,
               description = p_description, image_path = p_image, unit = p_unit,
               unit_price = p_price, is_available = IFNULL(p_available, is_available),
               updated_by = p_admin_user_id
         WHERE product_id = p_product_id;
        SELECT p_product_id AS product_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_setting` (IN `p_key` VARCHAR(50), IN `p_value` VARCHAR(255), IN `p_admin_user_id` INT)   BEGIN
    INSERT INTO store_settings (setting_key, setting_value, updated_by)
    VALUES (p_key, p_value, p_admin_user_id)
    ON DUPLICATE KEY UPDATE setting_value = p_value, updated_by = p_admin_user_id;
    SELECT * FROM store_settings WHERE setting_key = p_key;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_save_user` (IN `p_user_id` INT, IN `p_employee_id` INT, IN `p_username` VARCHAR(50), IN `p_password_hash` VARCHAR(255), IN `p_role` ENUM('Admin','Staff'), IN `p_is_active` TINYINT)   BEGIN
    IF p_role = 'Staff' AND p_employee_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A Staff account must be linked to an employee.';
    END IF;
    IF p_employee_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee not found.';
    END IF;
    IF p_user_id IS NULL THEN
        IF p_password_hash IS NULL OR p_password_hash = '' THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Password hash is required for a new account.';
        END IF;
        INSERT INTO users (employee_id, username, password_hash, role, is_active)
        VALUES (p_employee_id, p_username, p_password_hash, p_role, IFNULL(p_is_active, 1));
        SELECT LAST_INSERT_ID() AS user_id;
    ELSE
        IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_user_id) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found.';
        END IF;
        UPDATE users
           SET employee_id = p_employee_id, username = p_username, role = p_role,
               password_hash = IFNULL(NULLIF(p_password_hash, ''), password_hash),
               is_active = IFNULL(p_is_active, is_active)
         WHERE user_id = p_user_id;
        SELECT p_user_id AS user_id;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_set_product_availability` (IN `p_product_id` INT, IN `p_available` TINYINT, IN `p_admin_user_id` INT)   BEGIN
    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found.';
    END IF;
    UPDATE products SET is_available = p_available, updated_by = p_admin_user_id
     WHERE product_id = p_product_id;
    SELECT product_id, product_name, availability FROM v_product_list WHERE product_id = p_product_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_staff_dashboard` (IN `p_employee_id` INT)   BEGIN
    SELECT
      (SELECT attendance_status FROM attendance_records
        WHERE employee_id = p_employee_id AND attendance_date = CURDATE())           AS today_status,
      (SELECT time_in  FROM attendance_records
        WHERE employee_id = p_employee_id AND attendance_date = CURDATE())           AS today_time_in,
      (SELECT time_out FROM attendance_records
        WHERE employee_id = p_employee_id AND attendance_date = CURDATE())           AS today_time_out,
      fn_payable_days(p_employee_id, DATE_FORMAT(CURDATE(), '%Y-%m-01'), LAST_DAY(CURDATE()))
                                                                                      AS payable_days_this_month,
      (SELECT net_pay FROM v_payroll_detail
        WHERE employee_id = p_employee_id ORDER BY period_end DESC LIMIT 1)          AS latest_net_pay,
      (SELECT payment_status FROM payroll_transactions
        WHERE employee_id = p_employee_id ORDER BY period_end DESC LIMIT 1)          AS latest_payment_status,
      (SELECT IFNULL(SUM(outstanding_amount), 0) FROM v_outstanding_advances
        WHERE employee_id = p_employee_id)                                           AS outstanding_advance,
      (SELECT COUNT(*) FROM pay_requests
        WHERE employee_id = p_employee_id AND request_status = 'Pending')            AS pending_requests;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_submit_application` (IN `p_first` VARCHAR(60), IN `p_last` VARCHAR(60), IN `p_contact` VARCHAR(20), IN `p_email` VARCHAR(100), IN `p_address` VARCHAR(255), IN `p_opening_id` INT, IN `p_resume` VARCHAR(255), IN `p_message` TEXT)   BEGIN
    DECLARE v_opening INT DEFAULT NULL;
    SELECT opening_id INTO v_opening FROM job_openings
     WHERE opening_id = p_opening_id AND is_open = 1;
    IF v_opening IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'That job opening is not open.';
    END IF;
    INSERT INTO applicants (job_opening_id, first_name, last_name, contact_no, email, address,
                            resume_path, message)
    VALUES (v_opening, p_first, p_last, p_contact, p_email, p_address, p_resume, p_message);
    SELECT LAST_INSERT_ID() AS applicant_id;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_payable_days` (`p_employee_id` INT, `p_start` DATE, `p_end` DATE) RETURNS DECIMAL(5,2) READS SQL DATA BEGIN
    DECLARE v_days DECIMAL(5,2);
    SELECT IFNULL(SUM(CASE attendance_status
                          WHEN 'Present'  THEN 1
                          WHEN 'Late'     THEN 1
                          WHEN 'Half-Day' THEN 0.5
                          ELSE 0 END), 0)
      INTO v_days
      FROM attendance_records
     WHERE employee_id = p_employee_id AND attendance_date BETWEEN p_start AND p_end;
    RETURN v_days;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_recent_failed_logins` (`p_username` VARCHAR(50), `p_minutes` INT) RETURNS INT(11) READS SQL DATA BEGIN
    DECLARE v_uid INT DEFAULT NULL;
    DECLARE v_last_ok TIMESTAMP(3) DEFAULT '1971-01-01 00:00:00';
    DECLARE v_n INT;
    SELECT user_id INTO v_uid FROM users WHERE username = p_username;
    IF v_uid IS NOT NULL THEN
        SELECT IFNULL(MAX(attempted_at), '1971-01-01 00:00:00') INTO v_last_ok
          FROM login_logs WHERE user_id = v_uid AND login_status = 'Success';
    END IF;
    SELECT COUNT(*) INTO v_n
      FROM login_logs
     WHERE login_status = 'Failed'
       AND attempted_at > v_last_ok
       AND attempted_at >= NOW(3) - INTERVAL p_minutes MINUTE
       AND ((v_uid IS NOT NULL AND user_id = v_uid)
         OR (v_uid IS NULL AND username_entered = p_username));
    RETURN v_n;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_thirteenth_month_pay` (`p_employee_id` INT, `p_year` INT) RETURNS DECIMAL(12,2) READS SQL DATA BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT IFNULL(SUM(ROUND(days_worked * daily_rate, 2)), 0) INTO v_total
      FROM payroll_transactions
     WHERE employee_id = p_employee_id AND YEAR(period_end) = p_year;
    RETURN ROUND(v_total / 12, 2);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `advance_deductions`
--

CREATE TABLE `advance_deductions` (
  `deduction_id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL,
  `transaction_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL CHECK (`amount` > 0),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `applicants`
--

CREATE TABLE `applicants` (
  `applicant_id` int(11) NOT NULL,
  `job_opening_id` int(11) NOT NULL,
  `first_name` varchar(60) NOT NULL,
  `last_name` varchar(60) NOT NULL,
  `contact_no` varchar(20) DEFAULT NULL,
  `email` varchar(100) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `resume_path` varchar(255) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `application_status` enum('Pending','For Revision','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `admin_remarks` varchar(255) DEFAULT NULL,
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `date_applied` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `applicants`
--

INSERT INTO `applicants` (`applicant_id`, `job_opening_id`, `first_name`, `last_name`, `contact_no`, `email`, `address`, `resume_path`, `message`, `application_status`, `admin_remarks`, `decided_by`, `decided_at`, `date_applied`) VALUES
(1, 1, 'Ana', 'Villanueva', '09201234567', 'ana@example.com', NULL, NULL, 'Interested in working at the store.', 'Pending', NULL, NULL, NULL, '2026-10-25 03:44:28');

--
-- Triggers `applicants`
--
DELIMITER $$
CREATE TRIGGER `trg_applicant_decision_audit` AFTER UPDATE ON `applicants` FOR EACH ROW BEGIN
    IF OLD.application_status <> NEW.application_status THEN
        INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
        VALUES ('applicants', NEW.applicant_id, 'DECISION',
                CONCAT(OLD.application_status, ' -> ', NEW.application_status),
                NEW.decided_by);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendance_records`
--

CREATE TABLE `attendance_records` (
  `attendance_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `attendance_date` date NOT NULL,
  `time_in` time DEFAULT NULL,
  `time_out` time DEFAULT NULL,
  `hours_worked` decimal(5,2) GENERATED ALWAYS AS (if(`time_in` is not null and `time_out` is not null,round(time_to_sec(timediff(`time_out`,`time_in`)) / 3600,2),0)) STORED,
  `overtime_hours` decimal(5,2) NOT NULL DEFAULT 0.00 CHECK (`overtime_hours` >= 0),
  `attendance_status` enum('Present','Late','Half-Day','Absent','On Leave') NOT NULL DEFAULT 'Present',
  `remarks` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `attendance_records`
--

INSERT INTO `attendance_records` (`attendance_id`, `employee_id`, `attendance_date`, `time_in`, `time_out`, `overtime_hours`, `attendance_status`, `remarks`, `created_at`) VALUES
(1, 2, '2026-09-28', '08:00:00', '17:00:00', 0.00, 'Present', NULL, '2026-10-25 03:44:28'),
(2, 2, '2026-09-29', '08:30:00', '17:00:00', 0.00, 'Late', NULL, '2026-10-25 03:44:28'),
(3, 2, '2026-09-30', '08:00:00', '12:00:00', 0.00, 'Half-Day', NULL, '2026-10-25 03:44:28'),
(4, 3, '2026-09-28', '07:55:00', '17:00:00', 0.00, 'Present', NULL, '2026-10-25 03:44:28'),
(5, 3, '2026-09-29', '08:00:00', '17:00:00', 0.00, 'Present', NULL, '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `audit_id` bigint(20) NOT NULL,
  `table_name` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `action` varchar(30) NOT NULL,
  `details` varchar(500) DEFAULT NULL,
  `performed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`audit_id`, `table_name`, `record_id`, `action`, `details`, `performed_by`, `created_at`) VALUES
(1, 'users', 1, 'ACCOUNT_CREATED', 'admin (Admin)', NULL, '2026-10-25 03:44:28'),
(2, 'users', 2, 'ACCOUNT_CREATED', 'msantos (Admin)', NULL, '2026-10-25 03:44:28'),
(3, 'users', 3, 'ACCOUNT_CREATED', 'jdelacruz (Staff)', NULL, '2026-10-25 03:44:28'),
(4, 'users', 4, 'ACCOUNT_CREATED', 'preyes (Staff)', NULL, '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `chat_conversations`
--

CREATE TABLE `chat_conversations` (
  `conversation_id` int(11) NOT NULL,
  `visitor_id` int(11) NOT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_messages`
--

CREATE TABLE `chat_messages` (
  `message_id` bigint(20) NOT NULL,
  `conversation_id` int(11) NOT NULL,
  `sender` enum('Visitor','Chatbot') NOT NULL,
  `message_text` text NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `created_at` timestamp(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_visitors`
--

CREATE TABLE `chat_visitors` (
  `visitor_id` int(11) NOT NULL,
  `token_hash` char(64) NOT NULL,
  `first_seen` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `employee_id` int(11) NOT NULL,
  `employee_code` varchar(20) NOT NULL,
  `first_name` varchar(60) NOT NULL,
  `middle_name` varchar(60) DEFAULT NULL,
  `last_name` varchar(60) NOT NULL,
  `contact_no` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `date_hired` date NOT NULL,
  `daily_rate` decimal(10,2) NOT NULL CHECK (`daily_rate` >= 0),
  `employment_status` enum('Active','Inactive','Resigned') NOT NULL DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`employee_id`, `employee_code`, `first_name`, `middle_name`, `last_name`, `contact_no`, `email`, `address`, `date_hired`, `daily_rate`, `employment_status`, `created_at`, `updated_at`) VALUES
(1, 'EMP-0001', 'Maria', NULL, 'Santos', '09171234567', NULL, NULL, '2024-01-15', 650.00, 'Active', '2026-10-25 03:44:28', '2026-10-25 03:44:28'),
(2, 'EMP-0002', 'Juan', NULL, 'Dela Cruz', '09181234567', NULL, NULL, '2024-03-01', 500.00, 'Active', '2026-10-25 03:44:28', '2026-10-25 03:44:28'),
(3, 'EMP-0003', 'Pedro', NULL, 'Reyes', '09191234567', NULL, NULL, '2024-06-10', 480.00, 'Active', '2026-10-25 03:44:28', '2026-10-25 03:44:28');

--
-- Triggers `employees`
--
DELIMITER $$
CREATE TRIGGER `trg_emp_rate_audit` AFTER UPDATE ON `employees` FOR EACH ROW BEGIN
    IF OLD.daily_rate <> NEW.daily_rate THEN
        INSERT INTO audit_logs (table_name, record_id, action, details)
        VALUES ('employees', NEW.employee_id, 'RATE_CHANGE',
                CONCAT('Daily rate ', OLD.daily_rate, ' -> ', NEW.daily_rate));
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays` (
  `holiday_date` date NOT NULL,
  `holiday_name` varchar(100) NOT NULL,
  `holiday_type` enum('Regular','Special') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `holidays`
--

INSERT INTO `holidays` (`holiday_date`, `holiday_name`, `holiday_type`) VALUES
('2026-11-01', 'All Saints\' Day', 'Special'),
('2026-11-30', 'Bonifacio Day', 'Regular'),
('2026-12-25', 'Christmas Day', 'Regular'),
('2026-12-30', 'Rizal Day', 'Regular');

-- --------------------------------------------------------

--
-- Table structure for table `job_openings`
--

CREATE TABLE `job_openings` (
  `opening_id` int(11) NOT NULL,
  `description` varchar(255) NOT NULL,
  `slots` smallint(6) NOT NULL DEFAULT 1,
  `is_open` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `job_openings`
--

INSERT INTO `job_openings` (`opening_id`, `description`, `slots`, `is_open`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Store staff', 1, 1, 1, '2026-10-25 03:44:28', '2026-10-25 03:44:28'),
(2, 'Additional store staff (hiring closed)', 2, 0, 1, '2026-10-25 03:44:28', '2026-10-25 03:44:28'),
(3, 'Cashier', 1, 1, 1, '2026-10-25 03:44:28', '2026-10-25 03:44:28'),
(4, 'Delivery staff', 1, 1, 1, '2026-10-25 03:44:28', '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `login_logs`
--

CREATE TABLE `login_logs` (
  `login_id` bigint(20) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `username_entered` varchar(50) DEFAULT NULL,
  `login_status` enum('Success','Failed') NOT NULL,
  `attempted_at` timestamp(3) NOT NULL DEFAULT current_timestamp(3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payroll_settings`
--

CREATE TABLE `payroll_settings` (
  `setting_key` varchar(50) NOT NULL,
  `setting_value` decimal(10,2) NOT NULL CHECK (`setting_value` > 0),
  `description` varchar(255) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `payroll_settings`
--

INSERT INTO `payroll_settings` (`setting_key`, `setting_value`, `description`, `updated_by`, `updated_at`) VALUES
('overtime_multiplier', 1.25, 'Overtime pay = hourly rate x this', 1, '2026-10-25 03:44:28'),
('regular_holiday_multiplier', 2.00, 'Pay for working on a Regular holiday (x daily rate)', 1, '2026-10-25 03:44:28'),
('special_holiday_multiplier', 1.30, 'Pay for working on a Special holiday (x daily rate)', 1, '2026-10-25 03:44:28'),
('work_hours_per_day', 8.00, 'Hours in a normal workday (used to get the hourly rate)', 1, '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `payroll_transactions`
--

CREATE TABLE `payroll_transactions` (
  `transaction_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `period_start` date NOT NULL,
  `period_end` date NOT NULL,
  `days_worked` decimal(5,2) NOT NULL DEFAULT 0.00,
  `daily_rate` decimal(10,2) NOT NULL,
  `overtime_hours` decimal(5,2) NOT NULL DEFAULT 0.00,
  `overtime_pay` decimal(12,2) NOT NULL DEFAULT 0.00,
  `holiday_pay` decimal(12,2) NOT NULL DEFAULT 0.00,
  `gross_pay` decimal(12,2) GENERATED ALWAYS AS (round(`days_worked` * `daily_rate`,2) + `overtime_pay` + `holiday_pay`) STORED,
  `payment_status` enum('Computed','Released') NOT NULL DEFAULT 'Computed',
  `released_at` datetime DEFAULT NULL,
  `released_by` int(11) DEFAULT NULL,
  `computed_by` int(11) DEFAULT NULL,
  `computed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `payroll_transactions`
--
DELIMITER $$
CREATE TRIGGER `trg_payroll_release_audit` AFTER UPDATE ON `payroll_transactions` FOR EACH ROW BEGIN
    IF OLD.payment_status = 'Computed' AND NEW.payment_status = 'Released' THEN
        INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
        VALUES ('payroll_transactions', NEW.transaction_id, 'RELEASED',
                CONCAT('Net pay ', (SELECT d.net_pay FROM v_payroll_detail d
                                  WHERE d.transaction_id = NEW.transaction_id)),
                NEW.released_by);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `pay_adjustments`
--

CREATE TABLE `pay_adjustments` (
  `adjustment_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `adjustment_type` enum('Bonus','13th Month Pay') NOT NULL,
  `amount` decimal(10,2) NOT NULL CHECK (`amount` > 0),
  `remarks` varchar(255) DEFAULT NULL,
  `transaction_id` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pay_requests`
--

CREATE TABLE `pay_requests` (
  `request_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `request_type` enum('Salary Request','Paycheck Advance') NOT NULL DEFAULT 'Paycheck Advance',
  `payroll_transaction_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `request_status` enum('Pending','Approved','Rejected') NOT NULL DEFAULT 'Pending',
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `decided_by` int(11) DEFAULT NULL,
  `decided_at` datetime DEFAULT NULL,
  `admin_remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `pay_requests`
--
DELIMITER $$
CREATE TRIGGER `trg_payreq_decision_audit` AFTER UPDATE ON `pay_requests` FOR EACH ROW BEGIN
    IF OLD.request_status = 'Pending' AND NEW.request_status <> 'Pending' THEN
        INSERT INTO audit_logs (table_name, record_id, action, details, performed_by)
        VALUES ('pay_requests', NEW.request_id, 'DECISION',
                CONCAT(NEW.request_type, ' ', NEW.request_status,
                       IF(NEW.amount IS NULL, '', CONCAT(' - amount ', NEW.amount))),
                NEW.decided_by);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `product_id` int(11) NOT NULL,
  `product_code` varchar(20) NOT NULL,
  `product_name` varchar(100) NOT NULL,
  `category_id` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `unit` varchar(20) NOT NULL DEFAULT 'kg',
  `unit_price` decimal(10,2) NOT NULL CHECK (`unit_price` >= 0),
  `is_available` tinyint(1) NOT NULL DEFAULT 1,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`product_id`, `product_code`, `product_name`, `category_id`, `description`, `image_path`, `unit`, `unit_price`, `is_available`, `updated_by`, `updated_at`) VALUES
(1, 'RC-001', 'Dinorado Premium', 3, 'Soft and fragrant', NULL, 'kg', 62.00, 1, NULL, '2026-10-25 03:44:28'),
(2, 'RC-002', 'Jasmine Rice', 3, 'Aromatic long grain', NULL, 'kg', 58.00, 1, NULL, '2026-10-25 03:44:28'),
(3, 'RC-003', 'NFA Regular Milled', 1, 'Budget rice', NULL, 'kg', 45.00, 0, NULL, '2026-10-25 03:44:28'),
(4, 'RC-004', 'Sinandomeng 25kg', 1, 'Sack of rice', NULL, 'sack', 1350.00, 1, NULL, '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `product_categories`
--

CREATE TABLE `product_categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_categories`
--

INSERT INTO `product_categories` (`category_id`, `category_name`) VALUES
(1, 'Regular'),
(2, 'Well Milled'),
(3, 'Premium');

-- --------------------------------------------------------

--
-- Table structure for table `store_settings`
--

CREATE TABLE `store_settings` (
  `setting_key` varchar(50) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `store_settings`
--

INSERT INTO `store_settings` (`setting_key`, `setting_value`, `updated_by`, `updated_at`) VALUES
('address', 'Nasugbu, Batangas', 1, '2026-10-25 03:44:28'),
('contact_no', 'Update this: store contact number', 1, '2026-10-25 03:44:28'),
('latitude', '14.038972', 1, '2026-10-25 03:44:28'),
('longitude', '120.650472', 1, '2026-10-25 03:44:28'),
('store_hours', 'Mon - Sun, 5:00 AM to 5:00 PM', 1, '2026-10-25 03:44:28'),
('store_name', 'Jun & Bebot\'s Bigasan', 1, '2026-10-25 03:44:28');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('Admin','Staff') NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `employee_id`, `username`, `password_hash`, `role`, `is_active`, `last_login`, `created_at`) VALUES
(1, NULL, 'admin', '$2y$10$dgoVEIl1HWRBumx7uhSH5.UV459k8RTbf0Hc4UzhUlvy1ZQNRbjJC', 'Admin', 1, NULL, '2026-10-25 03:44:28'),
(2, 1, 'msantos', '$2y$10$dgoVEIl1HWRBumx7uhSH5.UV459k8RTbf0Hc4UzhUlvy1ZQNRbjJC', 'Admin', 1, NULL, '2026-10-25 03:44:28'),
(3, 2, 'jdelacruz', '$2y$10$ZcXsBj5qjeeY5gOfivsf/OMOErOntY3lXnLv11VSVRpKvTYAe.cKq', 'Staff', 1, NULL, '2026-10-25 03:44:28'),
(4, 3, 'preyes', '$2y$10$ZcXsBj5qjeeY5gOfivsf/OMOErOntY3lXnLv11VSVRpKvTYAe.cKq', 'Staff', 1, NULL, '2026-10-25 03:44:28');

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `trg_users_insert_audit` AFTER INSERT ON `users` FOR EACH ROW BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, details)
    VALUES ('users', NEW.user_id, 'ACCOUNT_CREATED', CONCAT(NEW.username, ' (', NEW.role, ')'));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_users_update_audit` AFTER UPDATE ON `users` FOR EACH ROW BEGIN
    IF OLD.role <> NEW.role THEN
        INSERT INTO audit_logs (table_name, record_id, action, details)
        VALUES ('users', NEW.user_id, 'ROLE_CHANGE', CONCAT(OLD.role, ' -> ', NEW.role));
    END IF;
    IF OLD.is_active <> NEW.is_active THEN
        INSERT INTO audit_logs (table_name, record_id, action, details)
        VALUES ('users', NEW.user_id, 'ACTIVATION_CHANGE', CONCAT(OLD.is_active, ' -> ', NEW.is_active));
    END IF;
    IF OLD.username <> NEW.username THEN
        INSERT INTO audit_logs (table_name, record_id, action, details)
        VALUES ('users', NEW.user_id, 'USERNAME_CHANGE', CONCAT(OLD.username, ' -> ', NEW.username));
    END IF;
    IF OLD.password_hash <> NEW.password_hash THEN
        INSERT INTO audit_logs (table_name, record_id, action, details)
        VALUES ('users', NEW.user_id, 'PASSWORD_CHANGE', 'Password changed');
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_adjustment_list`
-- (See below for the actual view)
--
CREATE TABLE `v_adjustment_list` (
`adjustment_id` int(11)
,`employee_code` varchar(20)
,`employee_name` varchar(121)
,`adjustment_type` enum('Bonus','13th Month Pay')
,`amount` decimal(10,2)
,`remarks` varchar(255)
,`adjustment_status` varchar(18)
,`transaction_id` int(11)
,`created_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_applicant_list`
-- (See below for the actual view)
--
CREATE TABLE `v_applicant_list` (
`applicant_id` int(11)
,`applicant_name` varchar(121)
,`applied_for` varchar(255)
,`email` varchar(100)
,`contact_no` varchar(20)
,`resume_path` varchar(255)
,`application_status` enum('Pending','For Revision','Approved','Rejected')
,`admin_remarks` varchar(255)
,`date_applied` timestamp
,`decided_at` datetime
,`decided_by_admin` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_attendance_history`
-- (See below for the actual view)
--
CREATE TABLE `v_attendance_history` (
`attendance_id` int(11)
,`employee_id` int(11)
,`employee_code` varchar(20)
,`employee_name` varchar(121)
,`attendance_date` date
,`holiday_name` varchar(100)
,`time_in` time
,`time_out` time
,`hours_worked` decimal(5,2)
,`overtime_hours` decimal(5,2)
,`attendance_status` enum('Present','Late','Half-Day','Absent','On Leave')
,`remarks` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_attendance_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_attendance_summary` (
`employee_id` int(11)
,`yr` int(4)
,`mo` int(2)
,`days_present` decimal(23,0)
,`days_late` decimal(23,0)
,`days_half` decimal(23,0)
,`days_absent` decimal(23,0)
,`days_leave` decimal(23,0)
,`payable_days` decimal(24,1)
,`total_hours` decimal(27,2)
,`total_overtime` decimal(27,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_chat_history`
-- (See below for the actual view)
--
CREATE TABLE `v_chat_history` (
`message_id` bigint(20)
,`visitor_id` int(11)
,`conversation_id` int(11)
,`conversation_started` timestamp
,`sender` enum('Visitor','Chatbot')
,`message_text` text
,`product_name` varchar(100)
,`created_at` timestamp(3)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_employee_profile`
-- (See below for the actual view)
--
CREATE TABLE `v_employee_profile` (
`employee_id` int(11)
,`employee_code` varchar(20)
,`full_name` varchar(124)
,`contact_no` varchar(20)
,`email` varchar(100)
,`date_hired` date
,`daily_rate` decimal(10,2)
,`employment_status` enum('Active','Inactive','Resigned')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_login_history`
-- (See below for the actual view)
--
CREATE TABLE `v_login_history` (
`login_id` bigint(20)
,`username` varchar(50)
,`role` enum('Admin','Staff')
,`login_status` enum('Success','Failed')
,`attempted_at` timestamp(3)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_open_jobs`
-- (See below for the actual view)
--
CREATE TABLE `v_open_jobs` (
`opening_id` int(11)
,`description` varchar(255)
,`slots` smallint(6)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_outstanding_advances`
-- (See below for the actual view)
--
CREATE TABLE `v_outstanding_advances` (
`employee_id` int(11)
,`outstanding_amount` decimal(55,2)
,`no_of_requests` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_payroll_detail`
-- (See below for the actual view)
--
CREATE TABLE `v_payroll_detail` (
`transaction_id` int(11)
,`employee_id` int(11)
,`period_start` date
,`period_end` date
,`days_worked` decimal(5,2)
,`daily_rate` decimal(10,2)
,`basic_pay` decimal(14,2)
,`overtime_hours` decimal(5,2)
,`overtime_pay` decimal(12,2)
,`holiday_pay` decimal(12,2)
,`gross_pay` decimal(12,2)
,`adjustments_total` decimal(32,2)
,`advance_deduction` decimal(32,2)
,`net_pay` decimal(34,2)
,`payment_status` enum('Computed','Released')
,`released_at` datetime
,`released_by` int(11)
,`computed_by` int(11)
,`computed_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_pay_request_detail`
-- (See below for the actual view)
--
CREATE TABLE `v_pay_request_detail` (
`request_id` int(11)
,`employee_id` int(11)
,`request_type` enum('Salary Request','Paycheck Advance')
,`payroll_transaction_id` int(11)
,`amount` decimal(34,2)
,`reason` varchar(255)
,`request_status` enum('Pending','Approved','Rejected')
,`requested_at` timestamp
,`decided_by` int(11)
,`decided_at` datetime
,`admin_remarks` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_pending_pay_requests`
-- (See below for the actual view)
--
CREATE TABLE `v_pending_pay_requests` (
`request_id` int(11)
,`employee_id` int(11)
,`employee_code` varchar(20)
,`employee_name` varchar(121)
,`request_type` enum('Salary Request','Paycheck Advance')
,`payroll_transaction_id` int(11)
,`amount` decimal(34,2)
,`reason` varchar(255)
,`requested_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_product_list`
-- (See below for the actual view)
--
CREATE TABLE `v_product_list` (
`product_id` int(11)
,`product_code` varchar(20)
,`product_name` varchar(100)
,`category` varchar(50)
,`description` varchar(255)
,`image_path` varchar(255)
,`unit` varchar(20)
,`unit_price` decimal(10,2)
,`availability` varchar(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_salary_report`
-- (See below for the actual view)
--
CREATE TABLE `v_salary_report` (
`transaction_id` int(11)
,`employee_code` varchar(20)
,`employee_name` varchar(121)
,`period_start` date
,`period_end` date
,`days_worked` decimal(5,2)
,`daily_rate` decimal(10,2)
,`basic_pay` decimal(14,2)
,`overtime_pay` decimal(12,2)
,`holiday_pay` decimal(12,2)
,`gross_pay` decimal(12,2)
,`adjustments_total` decimal(32,2)
,`advance_deduction` decimal(32,2)
,`net_pay` decimal(34,2)
,`payment_status` enum('Computed','Released')
,`released_at` datetime
,`computed_at` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_store_info`
-- (See below for the actual view)
--
CREATE TABLE `v_store_info` (
`setting_key` varchar(50)
,`setting_value` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_transaction_history`
-- (See below for the actual view)
--
CREATE TABLE `v_transaction_history` (
`employee_id` int(11)
,`txn_type` varchar(16)
,`txn_date` date
,`amount` decimal(34,2)
,`txn_status` varchar(8)
,`ref_id` int(11)
);

-- --------------------------------------------------------

--
-- Structure for view `v_adjustment_list`
--
DROP TABLE IF EXISTS `v_adjustment_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_adjustment_list`  AS SELECT `a`.`adjustment_id` AS `adjustment_id`, `e`.`employee_code` AS `employee_code`, concat(`e`.`first_name`,' ',`e`.`last_name`) AS `employee_name`, `a`.`adjustment_type` AS `adjustment_type`, `a`.`amount` AS `amount`, `a`.`remarks` AS `remarks`, if(`a`.`transaction_id` is null,'Pending','Included in salary') AS `adjustment_status`, `a`.`transaction_id` AS `transaction_id`, `a`.`created_at` AS `created_at` FROM (`pay_adjustments` `a` join `employees` `e` on(`e`.`employee_id` = `a`.`employee_id`)) ORDER BY `a`.`created_at` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_applicant_list`
--
DROP TABLE IF EXISTS `v_applicant_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_applicant_list`  AS SELECT `a`.`applicant_id` AS `applicant_id`, concat(`a`.`first_name`,' ',`a`.`last_name`) AS `applicant_name`, `jo`.`description` AS `applied_for`, `a`.`email` AS `email`, `a`.`contact_no` AS `contact_no`, `a`.`resume_path` AS `resume_path`, `a`.`application_status` AS `application_status`, `a`.`admin_remarks` AS `admin_remarks`, `a`.`date_applied` AS `date_applied`, `a`.`decided_at` AS `decided_at`, `u`.`username` AS `decided_by_admin` FROM ((`applicants` `a` join `job_openings` `jo` on(`jo`.`opening_id` = `a`.`job_opening_id`)) left join `users` `u` on(`u`.`user_id` = `a`.`decided_by`)) ORDER BY `a`.`date_applied` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_attendance_history`
--
DROP TABLE IF EXISTS `v_attendance_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_attendance_history`  AS SELECT `ar`.`attendance_id` AS `attendance_id`, `ar`.`employee_id` AS `employee_id`, `e`.`employee_code` AS `employee_code`, concat(`e`.`first_name`,' ',`e`.`last_name`) AS `employee_name`, `ar`.`attendance_date` AS `attendance_date`, `h`.`holiday_name` AS `holiday_name`, `ar`.`time_in` AS `time_in`, `ar`.`time_out` AS `time_out`, `ar`.`hours_worked` AS `hours_worked`, `ar`.`overtime_hours` AS `overtime_hours`, `ar`.`attendance_status` AS `attendance_status`, `ar`.`remarks` AS `remarks` FROM ((`attendance_records` `ar` join `employees` `e` on(`e`.`employee_id` = `ar`.`employee_id`)) left join `holidays` `h` on(`h`.`holiday_date` = `ar`.`attendance_date`)) ORDER BY `ar`.`attendance_date` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_attendance_summary`
--
DROP TABLE IF EXISTS `v_attendance_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_attendance_summary`  AS SELECT `attendance_records`.`employee_id` AS `employee_id`, year(`attendance_records`.`attendance_date`) AS `yr`, month(`attendance_records`.`attendance_date`) AS `mo`, sum(`attendance_records`.`attendance_status` = 'Present') AS `days_present`, sum(`attendance_records`.`attendance_status` = 'Late') AS `days_late`, sum(`attendance_records`.`attendance_status` = 'Half-Day') AS `days_half`, sum(`attendance_records`.`attendance_status` = 'Absent') AS `days_absent`, sum(`attendance_records`.`attendance_status` = 'On Leave') AS `days_leave`, sum(case `attendance_records`.`attendance_status` when 'Present' then 1 when 'Late' then 1 when 'Half-Day' then 0.5 else 0 end) AS `payable_days`, sum(`attendance_records`.`hours_worked`) AS `total_hours`, sum(`attendance_records`.`overtime_hours`) AS `total_overtime` FROM `attendance_records` GROUP BY `attendance_records`.`employee_id`, year(`attendance_records`.`attendance_date`), month(`attendance_records`.`attendance_date`) ;

-- --------------------------------------------------------

--
-- Structure for view `v_chat_history`
--
DROP TABLE IF EXISTS `v_chat_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_chat_history`  AS SELECT `m`.`message_id` AS `message_id`, `c`.`visitor_id` AS `visitor_id`, `m`.`conversation_id` AS `conversation_id`, `c`.`started_at` AS `conversation_started`, `m`.`sender` AS `sender`, `m`.`message_text` AS `message_text`, `pr`.`product_name` AS `product_name`, `m`.`created_at` AS `created_at` FROM ((`chat_messages` `m` join `chat_conversations` `c` on(`c`.`conversation_id` = `m`.`conversation_id`)) left join `products` `pr` on(`pr`.`product_id` = `m`.`product_id`)) ORDER BY `m`.`created_at` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_employee_profile`
--
DROP TABLE IF EXISTS `v_employee_profile`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_employee_profile`  AS SELECT `employees`.`employee_id` AS `employee_id`, `employees`.`employee_code` AS `employee_code`, concat(`employees`.`first_name`,' ',ifnull(concat(left(`employees`.`middle_name`,1),'. '),''),`employees`.`last_name`) AS `full_name`, `employees`.`contact_no` AS `contact_no`, `employees`.`email` AS `email`, `employees`.`date_hired` AS `date_hired`, `employees`.`daily_rate` AS `daily_rate`, `employees`.`employment_status` AS `employment_status` FROM `employees` ;

-- --------------------------------------------------------

--
-- Structure for view `v_login_history`
--
DROP TABLE IF EXISTS `v_login_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_login_history`  AS SELECT `l`.`login_id` AS `login_id`, coalesce(`u`.`username`,`l`.`username_entered`) AS `username`, `u`.`role` AS `role`, `l`.`login_status` AS `login_status`, `l`.`attempted_at` AS `attempted_at` FROM (`login_logs` `l` left join `users` `u` on(`u`.`user_id` = `l`.`user_id`)) ORDER BY `l`.`attempted_at` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_open_jobs`
--
DROP TABLE IF EXISTS `v_open_jobs`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_open_jobs`  AS SELECT `job_openings`.`opening_id` AS `opening_id`, `job_openings`.`description` AS `description`, `job_openings`.`slots` AS `slots` FROM `job_openings` WHERE `job_openings`.`is_open` = 1 ;

-- --------------------------------------------------------

--
-- Structure for view `v_outstanding_advances`
--
DROP TABLE IF EXISTS `v_outstanding_advances`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_outstanding_advances`  AS SELECT `x`.`employee_id` AS `employee_id`, sum(`x`.`remaining`) AS `outstanding_amount`, count(0) AS `no_of_requests` FROM (select `pr`.`employee_id` AS `employee_id`,`pr`.`amount` - ifnull((select sum(`ad`.`amount`) from `advance_deductions` `ad` where `ad`.`request_id` = `pr`.`request_id`),0) AS `remaining` from `pay_requests` `pr` where `pr`.`request_type` = 'Paycheck Advance' and `pr`.`request_status` = 'Approved') AS `x` WHERE `x`.`remaining` > 0 GROUP BY `x`.`employee_id` ;

-- --------------------------------------------------------

--
-- Structure for view `v_payroll_detail`
--
DROP TABLE IF EXISTS `v_payroll_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_payroll_detail`  AS SELECT `pt`.`transaction_id` AS `transaction_id`, `pt`.`employee_id` AS `employee_id`, `pt`.`period_start` AS `period_start`, `pt`.`period_end` AS `period_end`, `pt`.`days_worked` AS `days_worked`, `pt`.`daily_rate` AS `daily_rate`, round(`pt`.`days_worked` * `pt`.`daily_rate`,2) AS `basic_pay`, `pt`.`overtime_hours` AS `overtime_hours`, `pt`.`overtime_pay` AS `overtime_pay`, `pt`.`holiday_pay` AS `holiday_pay`, `pt`.`gross_pay` AS `gross_pay`, ifnull(`adj`.`total`,0) AS `adjustments_total`, ifnull(`ad`.`total`,0) AS `advance_deduction`, `pt`.`gross_pay`+ ifnull(`adj`.`total`,0) - ifnull(`ad`.`total`,0) AS `net_pay`, `pt`.`payment_status` AS `payment_status`, `pt`.`released_at` AS `released_at`, `pt`.`released_by` AS `released_by`, `pt`.`computed_by` AS `computed_by`, `pt`.`computed_at` AS `computed_at` FROM ((`payroll_transactions` `pt` left join (select `advance_deductions`.`transaction_id` AS `transaction_id`,sum(`advance_deductions`.`amount`) AS `total` from `advance_deductions` group by `advance_deductions`.`transaction_id`) `ad` on(`ad`.`transaction_id` = `pt`.`transaction_id`)) left join (select `pay_adjustments`.`transaction_id` AS `transaction_id`,sum(`pay_adjustments`.`amount`) AS `total` from `pay_adjustments` where `pay_adjustments`.`transaction_id` is not null group by `pay_adjustments`.`transaction_id`) `adj` on(`adj`.`transaction_id` = `pt`.`transaction_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_pay_request_detail`
--
DROP TABLE IF EXISTS `v_pay_request_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_pay_request_detail`  AS SELECT `pr`.`request_id` AS `request_id`, `pr`.`employee_id` AS `employee_id`, `pr`.`request_type` AS `request_type`, `pr`.`payroll_transaction_id` AS `payroll_transaction_id`, coalesce(`pr`.`amount`,`d`.`net_pay`) AS `amount`, `pr`.`reason` AS `reason`, `pr`.`request_status` AS `request_status`, `pr`.`requested_at` AS `requested_at`, `pr`.`decided_by` AS `decided_by`, `pr`.`decided_at` AS `decided_at`, `pr`.`admin_remarks` AS `admin_remarks` FROM (`pay_requests` `pr` left join `v_payroll_detail` `d` on(`d`.`transaction_id` = `pr`.`payroll_transaction_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_pending_pay_requests`
--
DROP TABLE IF EXISTS `v_pending_pay_requests`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_pending_pay_requests`  AS SELECT `d`.`request_id` AS `request_id`, `d`.`employee_id` AS `employee_id`, `e`.`employee_code` AS `employee_code`, concat(`e`.`first_name`,' ',`e`.`last_name`) AS `employee_name`, `d`.`request_type` AS `request_type`, `d`.`payroll_transaction_id` AS `payroll_transaction_id`, `d`.`amount` AS `amount`, `d`.`reason` AS `reason`, `d`.`requested_at` AS `requested_at` FROM (`v_pay_request_detail` `d` join `employees` `e` on(`e`.`employee_id` = `d`.`employee_id`)) WHERE `d`.`request_status` = 'Pending' ORDER BY `d`.`requested_at` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_product_list`
--
DROP TABLE IF EXISTS `v_product_list`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_product_list`  AS SELECT `pr`.`product_id` AS `product_id`, `pr`.`product_code` AS `product_code`, `pr`.`product_name` AS `product_name`, `c`.`category_name` AS `category`, `pr`.`description` AS `description`, `pr`.`image_path` AS `image_path`, `pr`.`unit` AS `unit`, `pr`.`unit_price` AS `unit_price`, if(`pr`.`is_available` = 1,'Available','Unavailable') AS `availability` FROM (`products` `pr` join `product_categories` `c` on(`c`.`category_id` = `pr`.`category_id`)) ORDER BY `c`.`category_name` ASC, `pr`.`product_name` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_salary_report`
--
DROP TABLE IF EXISTS `v_salary_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_salary_report`  AS SELECT `pt`.`transaction_id` AS `transaction_id`, `e`.`employee_code` AS `employee_code`, concat(`e`.`first_name`,' ',`e`.`last_name`) AS `employee_name`, `pt`.`period_start` AS `period_start`, `pt`.`period_end` AS `period_end`, `pt`.`days_worked` AS `days_worked`, `pt`.`daily_rate` AS `daily_rate`, `pt`.`basic_pay` AS `basic_pay`, `pt`.`overtime_pay` AS `overtime_pay`, `pt`.`holiday_pay` AS `holiday_pay`, `pt`.`gross_pay` AS `gross_pay`, `pt`.`adjustments_total` AS `adjustments_total`, `pt`.`advance_deduction` AS `advance_deduction`, `pt`.`net_pay` AS `net_pay`, `pt`.`payment_status` AS `payment_status`, `pt`.`released_at` AS `released_at`, `pt`.`computed_at` AS `computed_at` FROM (`v_payroll_detail` `pt` join `employees` `e` on(`e`.`employee_id` = `pt`.`employee_id`)) ORDER BY `pt`.`period_end` DESC, `e`.`last_name` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_store_info`
--
DROP TABLE IF EXISTS `v_store_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_store_info`  AS SELECT `store_settings`.`setting_key` AS `setting_key`, `store_settings`.`setting_value` AS `setting_value` FROM `store_settings` ;

-- --------------------------------------------------------

--
-- Structure for view `v_transaction_history`
--
DROP TABLE IF EXISTS `v_transaction_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_transaction_history`  AS SELECT `v_payroll_detail`.`employee_id` AS `employee_id`, 'Salary' AS `txn_type`, `v_payroll_detail`.`period_end` AS `txn_date`, `v_payroll_detail`.`net_pay` AS `amount`, `v_payroll_detail`.`payment_status` AS `txn_status`, `v_payroll_detail`.`transaction_id` AS `ref_id` FROM `v_payroll_detail`union all select `v_pay_request_detail`.`employee_id` AS `employee_id`,`v_pay_request_detail`.`request_type` AS `request_type`,cast(`v_pay_request_detail`.`requested_at` as date) AS `DATE(requested_at)`,`v_pay_request_detail`.`amount` AS `amount`,`v_pay_request_detail`.`request_status` AS `request_status`,`v_pay_request_detail`.`request_id` AS `request_id` from `v_pay_request_detail`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `advance_deductions`
--
ALTER TABLE `advance_deductions`
  ADD PRIMARY KEY (`deduction_id`),
  ADD KEY `fk_ad_txn` (`transaction_id`),
  ADD KEY `idx_ad_request` (`request_id`);

--
-- Indexes for table `applicants`
--
ALTER TABLE `applicants`
  ADD PRIMARY KEY (`applicant_id`),
  ADD KEY `fk_applicants_admin` (`decided_by`),
  ADD KEY `fk_applicants_opening` (`job_opening_id`),
  ADD KEY `idx_applicant_stat` (`application_status`);

--
-- Indexes for table `attendance_records`
--
ALTER TABLE `attendance_records`
  ADD PRIMARY KEY (`attendance_id`),
  ADD UNIQUE KEY `uq_employee_date` (`employee_id`,`attendance_date`),
  ADD KEY `idx_att_date` (`attendance_date`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `fk_audit_user` (`performed_by`);

--
-- Indexes for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  ADD PRIMARY KEY (`conversation_id`),
  ADD KEY `idx_chat_conv` (`visitor_id`,`started_at`);

--
-- Indexes for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`message_id`),
  ADD KEY `fk_msg_product` (`product_id`),
  ADD KEY `idx_chat_msg` (`conversation_id`,`created_at`);

--
-- Indexes for table `chat_visitors`
--
ALTER TABLE `chat_visitors`
  ADD PRIMARY KEY (`visitor_id`),
  ADD UNIQUE KEY `token_hash` (`token_hash`),
  ADD KEY `idx_chat_last_seen` (`last_seen`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`employee_id`),
  ADD UNIQUE KEY `employee_code` (`employee_code`);

--
-- Indexes for table `holidays`
--
ALTER TABLE `holidays`
  ADD PRIMARY KEY (`holiday_date`);

--
-- Indexes for table `job_openings`
--
ALTER TABLE `job_openings`
  ADD PRIMARY KEY (`opening_id`),
  ADD KEY `fk_jo_admin` (`created_by`),
  ADD KEY `idx_jo_open` (`is_open`);

--
-- Indexes for table `login_logs`
--
ALTER TABLE `login_logs`
  ADD PRIMARY KEY (`login_id`),
  ADD KEY `idx_login_user` (`user_id`,`attempted_at`),
  ADD KEY `idx_login_unknown` (`username_entered`,`attempted_at`),
  ADD KEY `idx_login_status` (`login_status`,`attempted_at`);

--
-- Indexes for table `payroll_settings`
--
ALTER TABLE `payroll_settings`
  ADD PRIMARY KEY (`setting_key`),
  ADD KEY `fk_ps_admin` (`updated_by`);

--
-- Indexes for table `payroll_transactions`
--
ALTER TABLE `payroll_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD UNIQUE KEY `uq_employee_period` (`employee_id`,`period_start`,`period_end`),
  ADD KEY `fk_pt_admin` (`computed_by`),
  ADD KEY `fk_pt_released` (`released_by`),
  ADD KEY `idx_pt_period` (`period_start`,`period_end`);

--
-- Indexes for table `pay_adjustments`
--
ALTER TABLE `pay_adjustments`
  ADD PRIMARY KEY (`adjustment_id`),
  ADD KEY `fk_adj_txn` (`transaction_id`),
  ADD KEY `fk_adj_admin` (`created_by`),
  ADD KEY `idx_adj_employee` (`employee_id`,`transaction_id`);

--
-- Indexes for table `pay_requests`
--
ALTER TABLE `pay_requests`
  ADD PRIMARY KEY (`request_id`),
  ADD KEY `fk_pr_employee` (`employee_id`),
  ADD KEY `fk_pr_admin` (`decided_by`),
  ADD KEY `fk_pr_txn` (`payroll_transaction_id`),
  ADD KEY `idx_pr_status` (`request_status`,`employee_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`product_id`),
  ADD UNIQUE KEY `product_code` (`product_code`),
  ADD KEY `fk_prod_admin` (`updated_by`),
  ADD KEY `fk_prod_category` (`category_id`),
  ADD KEY `idx_prod_available` (`is_available`);

--
-- Indexes for table `product_categories`
--
ALTER TABLE `product_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `store_settings`
--
ALTER TABLE `store_settings`
  ADD PRIMARY KEY (`setting_key`),
  ADD KEY `fk_ss_admin` (`updated_by`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `employee_id` (`employee_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `advance_deductions`
--
ALTER TABLE `advance_deductions`
  MODIFY `deduction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `applicants`
--
ALTER TABLE `applicants`
  MODIFY `applicant_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `attendance_records`
--
ALTER TABLE `attendance_records`
  MODIFY `attendance_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `audit_id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  MODIFY `conversation_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat_messages`
--
ALTER TABLE `chat_messages`
  MODIFY `message_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat_visitors`
--
ALTER TABLE `chat_visitors`
  MODIFY `visitor_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `employee_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `job_openings`
--
ALTER TABLE `job_openings`
  MODIFY `opening_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `login_logs`
--
ALTER TABLE `login_logs`
  MODIFY `login_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payroll_transactions`
--
ALTER TABLE `payroll_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pay_adjustments`
--
ALTER TABLE `pay_adjustments`
  MODIFY `adjustment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pay_requests`
--
ALTER TABLE `pay_requests`
  MODIFY `request_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `product_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `product_categories`
--
ALTER TABLE `product_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `advance_deductions`
--
ALTER TABLE `advance_deductions`
  ADD CONSTRAINT `fk_ad_request` FOREIGN KEY (`request_id`) REFERENCES `pay_requests` (`request_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ad_txn` FOREIGN KEY (`transaction_id`) REFERENCES `payroll_transactions` (`transaction_id`) ON UPDATE CASCADE;

--
-- Constraints for table `applicants`
--
ALTER TABLE `applicants`
  ADD CONSTRAINT `fk_applicants_admin` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_applicants_opening` FOREIGN KEY (`job_opening_id`) REFERENCES `job_openings` (`opening_id`) ON UPDATE CASCADE;

--
-- Constraints for table `attendance_records`
--
ALTER TABLE `attendance_records`
  ADD CONSTRAINT `fk_att_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`) ON UPDATE CASCADE;

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `fk_audit_user` FOREIGN KEY (`performed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `chat_conversations`
--
ALTER TABLE `chat_conversations`
  ADD CONSTRAINT `fk_conv_visitor` FOREIGN KEY (`visitor_id`) REFERENCES `chat_visitors` (`visitor_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `fk_msg_conv` FOREIGN KEY (`conversation_id`) REFERENCES `chat_conversations` (`conversation_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_msg_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `job_openings`
--
ALTER TABLE `job_openings`
  ADD CONSTRAINT `fk_jo_admin` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `login_logs`
--
ALTER TABLE `login_logs`
  ADD CONSTRAINT `fk_login_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `payroll_settings`
--
ALTER TABLE `payroll_settings`
  ADD CONSTRAINT `fk_ps_admin` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `payroll_transactions`
--
ALTER TABLE `payroll_transactions`
  ADD CONSTRAINT `fk_pt_admin` FOREIGN KEY (`computed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pt_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pt_released` FOREIGN KEY (`released_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `pay_adjustments`
--
ALTER TABLE `pay_adjustments`
  ADD CONSTRAINT `fk_adj_admin` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_adj_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_adj_txn` FOREIGN KEY (`transaction_id`) REFERENCES `payroll_transactions` (`transaction_id`) ON UPDATE CASCADE;

--
-- Constraints for table `pay_requests`
--
ALTER TABLE `pay_requests`
  ADD CONSTRAINT `fk_pr_admin` FOREIGN KEY (`decided_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pr_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pr_txn` FOREIGN KEY (`payroll_transaction_id`) REFERENCES `payroll_transactions` (`transaction_id`);

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `fk_prod_admin` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_prod_category` FOREIGN KEY (`category_id`) REFERENCES `product_categories` (`category_id`) ON UPDATE CASCADE;

--
-- Constraints for table `store_settings`
--
ALTER TABLE `store_settings`
  ADD CONSTRAINT `fk_ss_admin` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_employee` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`employee_id`);

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_purge_old_chats` ON SCHEDULE EVERY 1 DAY STARTS '2026-10-26 02:00:00' ON COMPLETION PRESERVE ENABLE DO CALL sp_chat_purge_old(90)$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
