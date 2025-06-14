-- MySQL dump 10.13  Distrib 8.0.30, for Win64 (x86_64)
--
-- Host: localhost    Database: hipet_db
-- ------------------------------------------------------
-- Server version	8.0.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `booking_history`
--

DROP TABLE IF EXISTS `booking_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking_history` (
  `history_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `old_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) DEFAULT NULL,
  `changed_by` enum('user','admin') NOT NULL,
  `changed_by_id` int NOT NULL,
  `change_reason` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking_history`
--

LOCK TABLES `booking_history` WRITE;
/*!40000 ALTER TABLE `booking_history` DISABLE KEYS */;
INSERT INTO `booking_history` VALUES (1,1,NULL,'pending','user',2,'New booking created','2025-06-12 12:08:56'),(2,1,'pending','confirmed','admin',1,'terbayar','2025-06-12 12:29:57'),(3,1,'confirmed','cancelled','admin',1,'','2025-06-12 12:30:06'),(4,2,NULL,'pending','user',2,'New booking created','2025-06-12 12:33:19'),(5,2,'pending','in_progress','admin',1,'sabar yaa','2025-06-12 12:36:14'),(6,2,'in_progress','completed','admin',1,'udah beres ya','2025-06-12 12:42:09'),(7,2,'completed','pending','admin',1,'tutup','2025-06-12 12:49:25'),(8,1,'cancelled','cancelled','admin',1,'','2025-06-12 14:47:51'),(9,2,'pending','confirmed','admin',1,'','2025-06-12 15:19:15'),(10,2,'confirmed','completed','admin',1,'','2025-06-13 03:03:37'),(11,2,'completed','completed','admin',1,'','2025-06-13 03:04:52'),(12,2,'completed','completed','admin',1,'','2025-06-13 15:46:21'),(13,2,'completed','pending','admin',1,'','2025-06-13 15:49:39'),(14,2,'pending','pending','admin',1,'','2025-06-13 15:55:25'),(15,2,'pending','pending','admin',1,'','2025-06-13 15:55:28'),(16,2,'pending','in_progress','admin',1,'abcd','2025-06-13 15:55:37'),(17,1,'cancelled','confirmed','admin',1,'abcd','2025-06-13 16:04:13'),(23,3,NULL,'pending','user',4,'New booking created','2025-06-13 17:40:01'),(24,3,'pending','in_progress','admin',1,'abcd','2025-06-13 17:41:40');
/*!40000 ALTER TABLE `booking_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookings` (
  `booking_id` int NOT NULL AUTO_INCREMENT,
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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`booking_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookings`
--

LOCK TABLES `bookings` WRITE;
/*!40000 ALTER TABLE `bookings` DISABLE KEYS */;
INSERT INTO `bookings` VALUES (1,2,1,1,2,'2025-06-12 12:08:56','2025-06-11 19:08:00','confirmed',50000.00,'unpaid','11','2025-06-12 12:08:56','2025-06-13 16:04:13'),(3,4,3,5,1,'2025-06-13 17:40:01','2025-06-06 09:20:00','in_progress',75000.00,'paid','apa yaa','2025-06-13 17:40:01','2025-06-13 17:41:40');
/*!40000 ALTER TABLE `bookings` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_booking_status_update` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    IF OLD.status != NEW.status THEN
        SET NEW.updated_at = CURRENT_TIMESTAMP;
        
        -- Auto update payment status based on booking status
        IF NEW.status = 'completed' AND NEW.payment_status = 'unpaid' THEN
            SET NEW.payment_status = 'paid';
        ELSEIF NEW.status = 'cancelled' AND NEW.payment_status = 'paid' THEN
            SET NEW.payment_status = 'refunded';
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_auto_create_payment` AFTER UPDATE ON `bookings` FOR EACH ROW BEGIN
    IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
        INSERT INTO payments (booking_id, amount, payment_method, status)
        VALUES (NEW.booking_id, NEW.total_price, 'cash', 'pending');
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `tr_update_schedule_on_delete` AFTER DELETE ON `bookings` FOR EACH ROW BEGIN
    UPDATE schedules 
    SET current_bookings = current_bookings - 1 
    WHERE schedule_id = OLD.schedule_id;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,2,'Booking #2 diubah menjadi \'pending\'. Catatan: tutup',0,'2025-06-12 12:49:25'),(2,2,'Booking #2 diubah menjadi \'pending\'.',0,'2025-06-13 15:55:25'),(3,2,'Booking #2 diubah menjadi \'pending\'.',0,'2025-06-13 15:55:28'),(4,2,'Booking #2 diubah menjadi \'in_progress\'. Catatan: abcd',0,'2025-06-13 15:55:37'),(5,2,'Booking #1 diubah menjadi \'confirmed\'. Catatan: abcd',0,'2025-06-13 16:04:13'),(6,4,'Booking #3 diubah menjadi \'in_progress\'. Catatan: abcd',0,'2025-06-13 17:41:40');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` enum('cash','transfer','card','ewallet') NOT NULL,
  `payment_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `transaction_id` varchar(100) DEFAULT NULL,
  `status` enum('pending','success','failed') DEFAULT 'pending',
  `notes` text,
  PRIMARY KEY (`payment_id`),
  KEY `payments_ibfk_1` (`booking_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,1,50000.00,'cash','2025-06-12 12:29:57',NULL,'pending',NULL),(3,1,50000.00,'cash','2025-06-13 16:04:13',NULL,'pending',NULL),(5,3,75000.00,'transfer','2025-06-13 17:40:21',NULL,'success',NULL);
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pets`
--

DROP TABLE IF EXISTS `pets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pets` (
  `pet_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `pet_name` varchar(100) NOT NULL,
  `pet_type` enum('dog','cat','bird','rabbit','other') NOT NULL,
  `breed` varchar(100) DEFAULT NULL,
  `age` int DEFAULT NULL,
  `weight` decimal(5,2) DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`pet_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pets`
--

LOCK TABLES `pets` WRITE;
/*!40000 ALTER TABLE `pets` DISABLE KEYS */;
INSERT INTO `pets` VALUES (1,1,'Buddy','dog','Golden Retriever',3,25.50,NULL,'2025-06-05 15:48:42'),(2,2,'sadsa','other',NULL,NULL,NULL,NULL,'2025-06-12 12:33:19'),(3,4,'cemong','other',NULL,NULL,NULL,NULL,'2025-06-13 17:40:01');
/*!40000 ALTER TABLE `pets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `schedules`
--

DROP TABLE IF EXISTS `schedules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schedules` (
  `schedule_id` int NOT NULL AUTO_INCREMENT,
  `service_id` int NOT NULL,
  `available_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `max_capacity` int DEFAULT '1',
  `current_bookings` int DEFAULT '0',
  `is_available` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`schedule_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `schedules`
--

LOCK TABLES `schedules` WRITE;
/*!40000 ALTER TABLE `schedules` DISABLE KEYS */;
INSERT INTO `schedules` VALUES (1,1,'2025-06-06','09:00:00','10:00:00',2,1,1,'2025-06-05 15:48:42'),(2,1,'2025-06-06','10:00:00','11:00:00',2,0,1,'2025-06-05 15:48:42'),(3,2,'2025-06-07','09:00:00','10:30:00',1,0,1,'2025-06-05 15:48:42'),(4,3,'2025-06-08','14:00:00','14:30:00',3,0,1,'2025-06-05 15:48:42'),(6,4,'2025-06-10','03:40:00','05:50:00',3,0,1,'2025-06-13 17:42:37');
/*!40000 ALTER TABLE `schedules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `services` (
  `service_id` int NOT NULL AUTO_INCREMENT,
  `service_name` varchar(100) NOT NULL,
  `service_type` enum('grooming','vaccination','consultation') NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `duration_minutes` int NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`service_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `services`
--

LOCK TABLES `services` WRITE;
/*!40000 ALTER TABLE `services` DISABLE KEYS */;
INSERT INTO `services` VALUES (1,'Basic Grooming','grooming','Mandi, potong kuku, bersihkan telinga',50000.00,60,1,'2025-06-05 15:48:41','2025-06-05 15:48:41'),(2,'Premium Grooming','grooming','Mandi, potong kuku, bersihkan telinga, styling bulu',100000.00,90,1,'2025-06-05 15:48:41','2025-06-05 15:48:41'),(3,'Vaksinasi Rabies','vaccination','Vaksin rabies untuk anjing dan kucing',150000.00,30,1,'2025-06-05 15:48:41','2025-06-05 15:48:41'),(4,'Vaksinasi 4in1','vaccination','Vaksin lengkap 4 in 1',200000.00,30,1,'2025-06-05 15:48:41','2025-06-05 15:48:41'),(5,'Konsultasi Kesehatan','consultation','Konsultasi dengan dokter hewan',75000.00,45,1,'2025-06-05 15:48:41','2025-06-05 15:48:41');
/*!40000 ALTER TABLE `services` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `role` enum('user','admin') DEFAULT 'user',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'user1','user1@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','John Doe','081234567892','Jl. Example No. 123','2025-06-05 15:48:41','2025-06-12 12:12:31','admin'),(2,'test','test@gmail.com','$2y$10$wFt2P9gp1Fhb0eVtqbj16.CV3Elq1nha2ACThiyCpiSpUdMdaMcO2','test','08888888888888','asdadasdas','2025-06-12 11:52:30','2025-06-12 11:52:30','user'),(3,'chacha','chacha@gmail.com','$2y$10$mDDKzf4PYneZaS1F7DukxeGbUsE8uTUGLGECuBc.JqO1zFbIAiuU.','Caca','0812345678911','Jl. Pajajaran','2025-06-13 15:58:57','2025-06-13 15:58:57','user'),(4,'abcd','abcd@gmail.com','$2y$10$sTAMY08yGUe4ueLFajk/lO5bcEuHGWt2W2KU5BbcmdE7RkRpNhxeK','abcd','0812345678','abcd','2025-06-13 17:37:50','2025-06-13 17:37:50','user'),(5,'abc','abc@example.com','$2y$10$WcKL2HUPIgJ5cyQmK82fhexk39AmDfsVlB8M0WFDvSEtpNhooSQFy','ABC','082345678901','Jl. Pajajaran','2025-06-13 17:47:30','2025-06-13 18:21:28','user');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_booking_summary`
--

DROP TABLE IF EXISTS `v_booking_summary`;
/*!50001 DROP VIEW IF EXISTS `v_booking_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_booking_summary` AS SELECT 
 1 AS `booking_id`,
 1 AS `customer_name`,
 1 AS `pet_name`,
 1 AS `pet_type`,
 1 AS `service_name`,
 1 AS `appointment_datetime`,
 1 AS `status`,
 1 AS `total_price`,
 1 AS `payment_status`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_daily_revenue`
--

DROP TABLE IF EXISTS `v_daily_revenue`;
/*!50001 DROP VIEW IF EXISTS `v_daily_revenue`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_daily_revenue` AS SELECT 
 1 AS `booking_date`,
 1 AS `total_bookings`,
 1 AS `completed_revenue`,
 1 AS `cancelled_amount`,
 1 AS `total_potential_revenue`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_service_performance`
--

DROP TABLE IF EXISTS `v_service_performance`;
/*!50001 DROP VIEW IF EXISTS `v_service_performance`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_service_performance` AS SELECT 
 1 AS `service_name`,
 1 AS `service_type`,
 1 AS `total_bookings`,
 1 AS `completed_bookings`,
 1 AS `avg_price`,
 1 AS `total_revenue`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `v_booking_summary`
--

/*!50001 DROP VIEW IF EXISTS `v_booking_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_booking_summary` AS select `b`.`booking_id` AS `booking_id`,`u`.`full_name` AS `customer_name`,`p`.`pet_name` AS `pet_name`,`p`.`pet_type` AS `pet_type`,`s`.`service_name` AS `service_name`,`b`.`appointment_datetime` AS `appointment_datetime`,`b`.`status` AS `status`,`b`.`total_price` AS `total_price`,`b`.`payment_status` AS `payment_status` from (((`bookings` `b` join `users` `u` on((`b`.`user_id` = `u`.`user_id`))) join `pets` `p` on((`b`.`pet_id` = `p`.`pet_id`))) join `services` `s` on((`b`.`service_id` = `s`.`service_id`))) order by `b`.`appointment_datetime` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_daily_revenue`
--

/*!50001 DROP VIEW IF EXISTS `v_daily_revenue`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_daily_revenue` AS select cast(`bookings`.`appointment_datetime` as date) AS `booking_date`,count(0) AS `total_bookings`,sum((case when (`bookings`.`status` = 'completed') then `bookings`.`total_price` else 0 end)) AS `completed_revenue`,sum((case when (`bookings`.`status` = 'cancelled') then `bookings`.`total_price` else 0 end)) AS `cancelled_amount`,sum(`bookings`.`total_price`) AS `total_potential_revenue` from `bookings` group by cast(`bookings`.`appointment_datetime` as date) order by `booking_date` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_service_performance`
--

/*!50001 DROP VIEW IF EXISTS `v_service_performance`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_service_performance` AS select `s`.`service_name` AS `service_name`,`s`.`service_type` AS `service_type`,count(`b`.`booking_id`) AS `total_bookings`,sum((case when (`b`.`status` = 'completed') then 1 else 0 end)) AS `completed_bookings`,avg(`s`.`price`) AS `avg_price`,sum((case when (`b`.`status` = 'completed') then `b`.`total_price` else 0 end)) AS `total_revenue` from (`services` `s` left join `bookings` `b` on((`s`.`service_id` = `b`.`service_id`))) group by `s`.`service_id`,`s`.`service_name`,`s`.`service_type` order by `total_revenue` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-06-14  1:24:41
