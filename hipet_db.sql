-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 13, 2025 at 05:51 PM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hipet_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateBooking` (IN `p_user_id` INT, IN `p_pet_id` INT, IN `p_service_id` INT, IN `p_schedule_id` INT, IN `p_appointment_datetime` DATETIME, IN `p_notes` TEXT, OUT `p_booking_id` INT, OUT `p_result` VARCHAR(100))   BEGIN
    DECLARE v_service_price DECIMAL(10,2);
    DECLARE v_max_capacity INT;
    DECLARE v_current_bookings INT;
    DECLARE v_schedule_available BOOLEAN;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction failed';
        SET p_booking_id = 0;
    END;

    START TRANSACTION;
    
    -- Check schedule availability
    SELECT max_capacity, current_bookings, is_available 
    INTO v_max_capacity, v_current_bookings, v_schedule_available
    FROM schedules WHERE schedule_id = p_schedule_id;
    
    IF v_schedule_available = FALSE OR v_current_bookings >= v_max_capacity THEN
        SET p_result = 'ERROR: Schedule not available';
        SET p_booking_id = 0;
        ROLLBACK;
    ELSE
        -- Get service price
        SELECT price INTO v_service_price FROM services WHERE service_id = p_service_id;
        
        -- Insert booking
        INSERT INTO bookings (user_id, pet_id, service_id, schedule_id, appointment_datetime, total_price, notes)
        VALUES (p_user_id, p_pet_id, p_service_id, p_schedule_id, p_appointment_datetime, v_service_price, p_notes);
        
        SET p_booking_id = LAST_INSERT_ID();
        
        -- Update schedule capacity
        UPDATE schedules SET current_bookings = current_bookings + 1 WHERE schedule_id = p_schedule_id;
        
        -- Insert booking history
        INSERT INTO booking_history (booking_id, old_status, new_status, changed_by, changed_by_id, change_reason)
        VALUES (p_booking_id, NULL, 'pending', 'user', p_user_id, 'New booking created');
        
        SET p_result = 'SUCCESS: Booking created successfully';
        COMMIT;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateDatabaseBackup` (IN `backup_name` VARCHAR(100))   BEGIN
    DECLARE backup_query TEXT;
    
    -- This is a simplified backup procedure
    -- In production, you would use mysqldump or similar tools
    SET backup_query = CONCAT(
        'CREATE TABLE backup_', backup_name, '_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), ' AS ',
        'SELECT "bookings" as table_name, COUNT(*) as record_count FROM bookings ',
        'UNION SELECT "users", COUNT(*) FROM users ',
        'UNION SELECT "services", COUNT(*) FROM services ',
        'UNION SELECT "schedules", COUNT(*) FROM schedules'
    );
    
    -- Execute backup (simplified version)
    SET @sql = backup_query;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetAvailableSchedules` (IN `p_service_id` INT, IN `p_date` DATE)   BEGIN
    SELECT 
        s.schedule_id,
        s.available_date,
        s.start_time,
        s.end_time,
        s.max_capacity,
        s.current_bookings,
        (s.max_capacity - s.current_bookings) AS available_slots,
        srv.service_name,
        srv.price,
        srv.duration_minutes
    FROM schedules s
    JOIN services srv ON s.service_id = srv.service_id
    WHERE s.service_id = p_service_id 
        AND s.available_date = p_date
        AND s.is_available = TRUE
        AND s.current_bookings < s.max_capacity
    ORDER BY s.start_time;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateBookingStatus` (IN `p_booking_id` INT, IN `p_new_status` VARCHAR(50), IN `p_changed_by_type` ENUM('user','admin'), IN `p_changed_by_id` INT, IN `p_reason` TEXT)   BEGIN
    DECLARE v_old_status VARCHAR(50);
    DECLARE v_schedule_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;
    
    -- Get current status and schedule_id
    SELECT status, schedule_id INTO v_old_status, v_schedule_id 
    FROM bookings WHERE booking_id = p_booking_id;
    
    -- Update booking status
    UPDATE bookings SET status = p_new_status WHERE booking_id = p_booking_id;
    
    -- If booking is cancelled, decrease schedule capacity
    IF p_new_status = 'cancelled' AND v_old_status != 'cancelled' THEN
        UPDATE schedules SET current_bookings = current_bookings - 1 WHERE schedule_id = v_schedule_id;
    END IF;
    
    -- Insert history
    INSERT INTO booking_history (booking_id, old_status, new_status, changed_by, changed_by_id, change_reason)
    VALUES (p_booking_id, v_old_status, p_new_status, p_changed_by_type, p_changed_by_id, p_reason);
    
    COMMIT;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `GetTotalRevenue` (`start_date` DATE, `end_date` DATE) RETURNS DECIMAL(12,2) DETERMINISTIC READS SQL DATA BEGIN
    DECLARE total_revenue DECIMAL(12,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(total_price), 0) INTO total_revenue
    FROM bookings 
    WHERE DATE(appointment_datetime) BETWEEN start_date AND end_date
        AND status = 'completed'
        AND payment_status = 'paid';
    
    RETURN total_revenue;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `GetUserBookingCount` (`p_user_id` INT, `p_status` VARCHAR(50)) RETURNS INT DETERMINISTIC READS SQL DATA BEGIN
    DECLARE booking_count INT DEFAULT 0;
    
    SELECT COUNT(*) INTO booking_count
    FROM bookings 
    WHERE user_id = p_user_id 
        AND (p_status IS NULL OR status = p_status);
    
    RETURN booking_count;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `IsScheduleAvailable` (`p_schedule_id` INT) RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA BEGIN
    DECLARE is_available BOOLEAN DEFAULT FALSE;
    DECLARE v_max_capacity INT;
    DECLARE v_current_bookings INT;
    DECLARE v_is_active BOOLEAN;
    
    SELECT max_capacity, current_bookings, is_available 
    INTO v_max_capacity, v_current_bookings, v_is_active
    FROM schedules 
    WHERE schedule_id = p_schedule_id;
    
    IF v_is_active = TRUE AND v_current_bookings < v_max_capacity THEN
        SET is_available = TRUE;
    END IF;
    
    RETURN is_available;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `booking_id` int NOT NULL,
  `user_id` int NOT NULL,
  `pet_id` int NOT NULL,
  `service_id` int NOT NULL,
  `schedule_id` int NOT NULL,
  `booking_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `appointment_datetime` datetime NOT NULL,
  `status` enum('pending','confirmed','in_progress','completed','cancelled') DEFAULT 'pending',
  `total_price` decimal(10,2) NOT NULL,
  `payment_status` enum('unpaid','paid','refunded') DEFAULT 'unpaid',
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`booking_id`, `user_id`, `pet_id`, `service_id`, `schedule_id`, `booking_date`, `appointment_datetime`, `status`, `total_price`, `payment_status`, `notes`, `created_at`, `updated_at`) VALUES
(1, 2, 1, 1, 2, '2025-06-12 12:08:56', '2025-06-11 19:08:00', 'confirmed', 50000.00, 'unpaid', '11', '2025-06-12 12:08:56', '2025-06-13 16:04:13'),
(3, 4, 3, 5, 1, '2025-06-13 17:40:01', '2025-06-06 09:20:00', 'in_progress', 75000.00, 'paid', 'apa yaa', '2025-06-13 17:40:01', '2025-06-13 17:41:40');

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `tr_auto_create_payment` AFTER UPDATE ON `bookings` FOR EACH ROW BEGIN
    IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
        INSERT INTO payments (booking_id, amount, payment_method, status)
        VALUES (NEW.booking_id, NEW.total_price, 'cash', 'pending');
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_booking_status_update` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    IF OLD.status != NEW.status THEN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
        
        -- Auto update payment status based on booking status
        IF NEW.status = 'completed' AND NEW.payment_status = 'unpaid' THEN
            SET NEW.payment_status = 'paid';
        ELSEIF NEW.status = 'cancelled' AND NEW.payment_status = 'paid' THEN
            SET NEW.payment_status = 'refunded';
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_update_schedule_on_delete` AFTER DELETE ON `bookings` FOR EACH ROW BEGIN
    UPDATE schedules 
    SET current_bookings = current_bookings - 1 
    WHERE schedule_id = OLD.schedule_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `booking_history`
--

CREATE TABLE `booking_history` (
  `history_id` int NOT NULL,
  `booking_id` int NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) DEFAULT NULL,
  `changed_by` enum('user','admin') NOT NULL,
  `changed_by_id` int NOT NULL,
  `change_reason` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `booking_history`
--

INSERT INTO `booking_history` (`history_id`, `booking_id`, `old_status`, `new_status`, `changed_by`, `changed_by_id`, `change_reason`, `created_at`) VALUES
(1, 1, NULL, 'pending', 'user', 2, 'New booking created', '2025-06-12 12:08:56'),
(2, 1, 'pending', 'confirmed', 'admin', 1, 'terbayar', '2025-06-12 12:29:57'),
(3, 1, 'confirmed', 'cancelled', 'admin', 1, '', '2025-06-12 12:30:06'),
(4, 2, NULL, 'pending', 'user', 2, 'New booking created', '2025-06-12 12:33:19'),
(5, 2, 'pending', 'in_progress', 'admin', 1, 'sabar yaa', '2025-06-12 12:36:14'),
(6, 2, 'in_progress', 'completed', 'admin', 1, 'udah beres ya', '2025-06-12 12:42:09'),
(7, 2, 'completed', 'pending', 'admin', 1, 'tutup', '2025-06-12 12:49:25'),
(8, 1, 'cancelled', 'cancelled', 'admin', 1, '', '2025-06-12 14:47:51'),
(9, 2, 'pending', 'confirmed', 'admin', 1, '', '2025-06-12 15:19:15'),
(10, 2, 'confirmed', 'completed', 'admin', 1, '', '2025-06-13 03:03:37'),
(11, 2, 'completed', 'completed', 'admin', 1, '', '2025-06-13 03:04:52'),
(12, 2, 'completed', 'completed', 'admin', 1, '', '2025-06-13 15:46:21'),
(13, 2, 'completed', 'pending', 'admin', 1, '', '2025-06-13 15:49:39'),
(14, 2, 'pending', 'pending', 'admin', 1, '', '2025-06-13 15:55:25'),
(15, 2, 'pending', 'pending', 'admin', 1, '', '2025-06-13 15:55:28'),
(16, 2, 'pending', 'in_progress', 'admin', 1, 'abcd', '2025-06-13 15:55:37'),
(17, 1, 'cancelled', 'confirmed', 'admin', 1, 'abcd', '2025-06-13 16:04:13'),
(23, 3, NULL, 'pending', 'user', 4, 'New booking created', '2025-06-13 17:40:01'),
(24, 3, 'pending', 'in_progress', 'admin', 1, 'abcd', '2025-06-13 17:41:40');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `message`, `is_read`, `created_at`) VALUES
(1, 2, 'Booking #2 diubah menjadi \'pending\'. Catatan: tutup', 0, '2025-06-12 12:49:25'),
(2, 2, 'Booking #2 diubah menjadi \'pending\'.', 0, '2025-06-13 15:55:25'),
(3, 2, 'Booking #2 diubah menjadi \'pending\'.', 0, '2025-06-13 15:55:28'),
(4, 2, 'Booking #2 diubah menjadi \'in_progress\'. Catatan: abcd', 0, '2025-06-13 15:55:37'),
(5, 2, 'Booking #1 diubah menjadi \'confirmed\'. Catatan: abcd', 0, '2025-06-13 16:04:13'),
(6, 4, 'Booking #3 diubah menjadi \'in_progress\'. Catatan: abcd', 0, '2025-06-13 17:41:40');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int NOT NULL,
  `booking_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` enum('cash','transfer','card','ewallet') NOT NULL,
  `payment_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `transaction_id` varchar(100) DEFAULT NULL,
  `status` enum('pending','success','failed') DEFAULT 'pending',
  `notes` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`payment_id`, `booking_id`, `amount`, `payment_method`, `payment_date`, `transaction_id`, `status`, `notes`) VALUES
(1, 1, 50000.00, 'cash', '2025-06-12 12:29:57', NULL, 'pending', NULL),
(3, 1, 50000.00, 'cash', '2025-06-13 16:04:13', NULL, 'pending', NULL),
(5, 3, 75000.00, 'transfer', '2025-06-13 17:40:21', NULL, 'success', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `pets`
--

CREATE TABLE `pets` (
  `pet_id` int NOT NULL,
  `user_id` int NOT NULL,
  `pet_name` varchar(100) NOT NULL,
  `pet_type` enum('dog','cat','bird','rabbit','other') NOT NULL,
  `breed` varchar(100) DEFAULT NULL,
  `age` int DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `pets`
--

INSERT INTO `pets` (`pet_id`, `user_id`, `pet_name`, `pet_type`, `breed`, `age`, `weight`, `notes`, `created_at`) VALUES
(1, 1, 'Buddy', 'dog', 'Golden Retriever', 3, 25.50, NULL, '2025-06-05 15:48:42'),
(2, 2, 'sadsa', 'other', NULL, NULL, NULL, NULL, '2025-06-12 12:33:19'),
(3, 4, 'cemong', 'other', NULL, NULL, NULL, NULL, '2025-06-13 17:40:01');

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `schedule_id` int NOT NULL,
  `service_id` int NOT NULL,
  `available_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `max_capacity` int DEFAULT '1',
  `current_bookings` int DEFAULT '0',
  `is_available` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `schedules`
--

INSERT INTO `schedules` (`schedule_id`, `service_id`, `available_date`, `start_time`, `end_time`, `max_capacity`, `current_bookings`, `is_available`, `created_at`) VALUES
(1, 1, '2025-06-06', '09:00:00', '10:00:00', 2, 1, 1, '2025-06-05 15:48:42'),
(2, 1, '2025-06-06', '10:00:00', '11:00:00', 2, 0, 1, '2025-06-05 15:48:42'),
(3, 2, '2025-06-07', '09:00:00', '10:30:00', 1, 0, 1, '2025-06-05 15:48:42'),
(4, 3, '2025-06-08', '14:00:00', '14:30:00', 3, 0, 1, '2025-06-05 15:48:42'),
(6, 4, '2025-06-10', '03:40:00', '05:50:00', 3, 0, 1, '2025-06-13 17:42:37');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `service_id` int NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `service_type` enum('grooming','vaccination','consultation') NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `duration_minutes` int NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`service_id`, `service_name`, `service_type`, `description`, `price`, `duration_minutes`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Basic Grooming', 'grooming', 'Mandi, potong kuku, bersihkan telinga', 50000.00, 60, 1, '2025-06-05 15:48:41', '2025-06-05 15:48:41'),
(2, 'Premium Grooming', 'grooming', 'Mandi, potong kuku, bersihkan telinga, styling bulu', 100000.00, 90, 1, '2025-06-05 15:48:41', '2025-06-05 15:48:41'),
(3, 'Vaksinasi Rabies', 'vaccination', 'Vaksin rabies untuk anjing dan kucing', 150000.00, 30, 1, '2025-06-05 15:48:41', '2025-06-05 15:48:41'),
(4, 'Vaksinasi 4in1', 'vaccination', 'Vaksin lengkap 4 in 1', 200000.00, 30, 1, '2025-06-05 15:48:41', '2025-06-05 15:48:41'),
(5, 'Konsultasi Kesehatan', 'consultation', 'Konsultasi dengan dokter hewan', 75000.00, 45, 1, '2025-06-05 15:48:41', '2025-06-05 15:48:41');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `role` enum('user','admin') DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password`, `full_name`, `phone`, `address`, `created_at`, `updated_at`, `role`) VALUES
(1, 'user1', 'user1@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John Doe', '081234567892', 'Jl. Example No. 123', '2025-06-05 15:48:41', '2025-06-12 12:12:31', 'admin'),
(2, 'test', 'test@gmail.com', '$2y$10$wFt2P9gp1Fhb0eVtqbj16.CV3Elq1nha2ACThiyCpiSpUdMdaMcO2', 'test', '08888888888888', 'asdadasdas', '2025-06-12 11:52:30', '2025-06-12 11:52:30', 'user'),
(3, 'chacha', 'chacha@gmail.com', '$2y$10$mDDKzf4PYneZaS1F7DukxeGbUsE8uTUGLGECuBc.JqO1zFbIAiuU.', 'Caca', '0812345678911', 'Jl. Pajajaran', '2025-06-13 15:58:57', '2025-06-13 15:58:57', 'user'),
(4, 'abcd', 'abcd@gmail.com', '$2y$10$sTAMY08yGUe4ueLFajk/lO5bcEuHGWt2W2KU5BbcmdE7RkRpNhxeK', 'abcd', '0812345678', 'abcd', '2025-06-13 17:37:50', '2025-06-13 17:37:50', 'user'),
(5, 'abc', 'abc@example.com', '$2y$10$WcKL2HUPIgJ5cyQmK82fhexk39AmDfsVlB8M0WFDvSEtpNhooSQFy', 'abc', '082345678901', 'Jl. Pajajaran', '2025-06-13 17:47:30', '2025-06-13 17:47:30', 'user');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_booking_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_booking_summary` (
`appointment_datetime` datetime
,`booking_id` int
,`customer_name` varchar(100)
,`payment_status` enum('unpaid','paid','refunded')
,`pet_name` varchar(100)
,`pet_type` enum('dog','cat','bird','rabbit','other')
,`service_name` varchar(100)
,`status` enum('pending','confirmed','in_progress','completed','cancelled')
,`total_price` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_daily_revenue`
-- (See below for the actual view)
--
CREATE TABLE `v_daily_revenue` (
`booking_date` date
,`cancelled_amount` decimal(32,2)
,`completed_revenue` decimal(32,2)
,`total_bookings` bigint
,`total_potential_revenue` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_service_performance`
-- (See below for the actual view)
--
CREATE TABLE `v_service_performance` (
`avg_price` decimal(14,6)
,`completed_bookings` decimal(23,0)
,`service_name` varchar(100)
,`service_type` enum('grooming','vaccination','consultation')
,`total_bookings` bigint
,`total_revenue` decimal(32,2)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`booking_id`);

--
-- Indexes for table `booking_history`
--
ALTER TABLE `booking_history`
  ADD PRIMARY KEY (`history_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `payments_ibfk_1` (`booking_id`);

--
-- Indexes for table `pets`
--
ALTER TABLE `pets`
  ADD PRIMARY KEY (`pet_id`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`schedule_id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `booking_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `booking_history`
--
ALTER TABLE `booking_history`
  MODIFY `history_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `pets`
--
ALTER TABLE `pets`
  MODIFY `pet_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `schedule_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `service_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

-- --------------------------------------------------------

--
-- Structure for view `v_booking_summary`
--
DROP TABLE IF EXISTS `v_booking_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_booking_summary`  AS SELECT `b`.`booking_id` AS `booking_id`, `u`.`full_name` AS `customer_name`, `p`.`pet_name` AS `pet_name`, `p`.`pet_type` AS `pet_type`, `s`.`service_name` AS `service_name`, `b`.`appointment_datetime` AS `appointment_datetime`, `b`.`status` AS `status`, `b`.`total_price` AS `total_price`, `b`.`payment_status` AS `payment_status` FROM (((`bookings` `b` join `users` `u` on((`b`.`user_id` = `u`.`user_id`))) join `pets` `p` on((`b`.`pet_id` = `p`.`pet_id`))) join `services` `s` on((`b`.`service_id` = `s`.`service_id`))) ORDER BY `b`.`appointment_datetime` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_daily_revenue`
--
DROP TABLE IF EXISTS `v_daily_revenue`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_daily_revenue`  AS SELECT cast(`bookings`.`appointment_datetime` as date) AS `booking_date`, count(0) AS `total_bookings`, sum((case when (`bookings`.`status` = 'completed') then `bookings`.`total_price` else 0 end)) AS `completed_revenue`, sum((case when (`bookings`.`status` = 'cancelled') then `bookings`.`total_price` else 0 end)) AS `cancelled_amount`, sum(`bookings`.`total_price`) AS `total_potential_revenue` FROM `bookings` GROUP BY cast(`bookings`.`appointment_datetime` as date) ORDER BY `booking_date` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_service_performance`
--
DROP TABLE IF EXISTS `v_service_performance`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_service_performance`  AS SELECT `s`.`service_name` AS `service_name`, `s`.`service_type` AS `service_type`, count(`b`.`booking_id`) AS `total_bookings`, sum((case when (`b`.`status` = 'completed') then 1 else 0 end)) AS `completed_bookings`, avg(`s`.`price`) AS `avg_price`, sum((case when (`b`.`status` = 'completed') then `b`.`total_price` else 0 end)) AS `total_revenue` FROM (`services` `s` left join `bookings` `b` on((`s`.`service_id` = `b`.`service_id`))) GROUP BY `s`.`service_id`, `s`.`service_name`, `s`.`service_type` ORDER BY `total_revenue` DESC ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
