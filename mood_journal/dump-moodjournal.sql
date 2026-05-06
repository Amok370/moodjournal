-- MySQL dump 10.13  Distrib 8.0.45, for Linux (x86_64)
--
-- Host: localhost    Database: moodjournal
-- ------------------------------------------------------
-- Server version	8.0.45-0ubuntu0.24.04.1

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
-- Table structure for table `ai_suggestions`
--

DROP TABLE IF EXISTS `ai_suggestions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_suggestions` (
  `suggestion_id` int NOT NULL AUTO_INCREMENT,
  `mood_category` varchar(50) DEFAULT NULL,
  `suggestion_text` text NOT NULL,
  `priority_level` int DEFAULT '1',
  PRIMARY KEY (`suggestion_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_suggestions`
--

LOCK TABLES `ai_suggestions` WRITE;
/*!40000 ALTER TABLE `ai_suggestions` DISABLE KEYS */;
INSERT INTO `ai_suggestions` VALUES (1,'Düşük','Şu an çok zorlanıyor olabilirsin, seni anlıyorum. Çevrene odaklanmayı dene.',1),(2,'Düşük','Eğer bu düşük ruh hali bir süredir devam ediyorsa birileriyle konuşmak sana iyi gelebilir.',1),(3,'Düşük','Derin bir nefes al ve gözlerini kapat, rahatlamaya çalış.',2),(4,'Orta','Kafanı dağıtmak için sevdiğin bir şarkıyı açıp kısa bir yürüyüş yapmaya ne dersin?',2),(5,'Orta','Bugün seni tetikleyen şeyi yazmak ister misin?',2),(6,'Orta','Bir bardak su iç ve yükünü bırak.',3),(7,'Yüksek','Harikasın! Bu enerjiyi bugün bir arkadaşına teşekkür ederek paylaşmaya ne dersin?',3),(8,'Yüksek','Günün en güzel anını not etmek ister misin?.',3),(9,'Yüksek','Kendini bu kadar iyi hissederken uzun zamandır ertelediğin o yaratıcı işe başlamanın tam sırası!',3);
/*!40000 ALTER TABLE `ai_suggestions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `content_reports`
--

DROP TABLE IF EXISTS `content_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `content_reports` (
  `report_id` int NOT NULL AUTO_INCREMENT,
  `target_type` enum('post','comment') NOT NULL,
  `target_id` int NOT NULL,
  `reporter_user_id` char(36) NOT NULL,
  `reason` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  UNIQUE KEY `unq_report` (`target_type`,`target_id`,`reporter_user_id`),
  KEY `fk_report_user` (`reporter_user_id`),
  KEY `idx_content_reports_target` (`target_type`,`target_id`),
  CONSTRAINT `fk_report_user` FOREIGN KEY (`reporter_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `content_reports`
--

LOCK TABLES `content_reports` WRITE;
/*!40000 ALTER TABLE `content_reports` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_reports` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `journal_entries`
--

DROP TABLE IF EXISTS `journal_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `journal_entries` (
  `entry_id` int NOT NULL AUTO_INCREMENT,
  `user_id` char(36) NOT NULL,
  `mood_score` int DEFAULT NULL,
  `content` text,
  `trigger_factor` varchar(255) DEFAULT NULL,
  `coping_strategy_used` varchar(255) DEFAULT NULL,
  `ai_sentiment_label` varchar(50) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`entry_id`),
  KEY `fk_journal_user` (`user_id`),
  CONSTRAINT `fk_journal_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `journal_entries_chk_1` CHECK ((`mood_score` between 1 and 10))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `journal_entries`
--

LOCK TABLES `journal_entries` WRITE;
/*!40000 ALTER TABLE `journal_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `journal_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motivation_messages`
--

DROP TABLE IF EXISTS `motivation_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `motivation_messages` (
  `message_id` int NOT NULL AUTO_INCREMENT,
  `day_of_week` varchar(50) DEFAULT NULL,
  `message_text` text NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`message_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motivation_messages`
--

LOCK TABLES `motivation_messages` WRITE;
/*!40000 ALTER TABLE `motivation_messages` DISABLE KEYS */;
INSERT INTO `motivation_messages` VALUES (1,'Pazartesi','Yeni bir hafta, yeni bir başlangıç. Bugün kendine nazik davranmayı ve küçük adımların gücüne inanmayı unutma.','2026-04-28 13:26:27'),(2,'Salı','Duyguların bir deniz gibidir; bazen dalgalı, bazen durgun. Her iki hali de kabul etmek büyümenin bir parçasıdır.','2026-04-28 13:26:27'),(3,'Çarşamba','Haftanın ortasındasın. Şimdiye kadar başardıklarını fark et ve kendine bir mola vermek için alan tanı.','2026-04-28 13:26:27'),(4,'Perşembe','İçindeki güç, karşılaştığın zorluklardan çok daha büyüktür. Bugün sadece nefes al ve anda kalmaya odaklan.','2026-04-28 13:26:27'),(5,'Cuma','Haftayı bitirirken kendine şu soruyu sor: Bugün ruhuma iyi gelecek ne yapabilirim? Küçük bir yürüyüş ya da sıcak bir çay?','2026-04-28 13:26:27'),(6,'Cumartesi','Dinlenmek bir lüks değil, bir ihtiyaçtır. Bugün zihnini sustur ve sadece var olmanın tadını çıkar.','2026-04-28 13:26:27'),(7,'Pazar','Yeni haftaya hazırlanırken geçmiş günlerin yorgunluğunu bırak. Sen her halinle değerlisin.','2026-04-28 13:26:27');
/*!40000 ALTER TABLE `motivation_messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_comments`
--

DROP TABLE IF EXISTS `post_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_comments` (
  `comment_id` char(36) NOT NULL,
  `post_id` int NOT NULL,
  `user_id` char(36) NOT NULL,
  `content` varchar(500) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `is_flagged` tinyint(1) NOT NULL DEFAULT '0',
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `flagged_at` datetime DEFAULT NULL,
  `flagged_reason` text,
  PRIMARY KEY (`comment_id`),
  KEY `fk_comment_post` (`post_id`),
  KEY `fk_comment_user` (`user_id`),
  CONSTRAINT `fk_comment_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_comment_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_comments`
--

LOCK TABLES `post_comments` WRITE;
/*!40000 ALTER TABLE `post_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `post_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `post_likes`
--

DROP TABLE IF EXISTS `post_likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `post_likes` (
  `like_id` int NOT NULL AUTO_INCREMENT,
  `post_id` int NOT NULL,
  `user_id` char(36) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`like_id`),
  UNIQUE KEY `post_id` (`post_id`,`user_id`),
  KEY `fk_like_user` (`user_id`),
  CONSTRAINT `fk_like_post` FOREIGN KEY (`post_id`) REFERENCES `posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_like_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `post_likes`
--

LOCK TABLES `post_likes` WRITE;
/*!40000 ALTER TABLE `post_likes` DISABLE KEYS */;
/*!40000 ALTER TABLE `post_likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `posts`
--

DROP TABLE IF EXISTS `posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `posts` (
  `post_id` int NOT NULL AUTO_INCREMENT,
  `user_id` char(36) NOT NULL,
  `content` varchar(280) NOT NULL,
  `is_private` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `like_count` int NOT NULL DEFAULT '0',
  `comment_count` int NOT NULL DEFAULT '0',
  `is_flagged` tinyint(1) NOT NULL DEFAULT '0',
  `is_hidden` tinyint(1) NOT NULL DEFAULT '0',
  `flagged_at` datetime DEFAULT NULL,
  `flagged_reason` text,
  PRIMARY KEY (`post_id`),
  KEY `fk_post_user` (`user_id`),
  CONSTRAINT `fk_post_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `posts`
--

LOCK TABLES `posts` WRITE;
/*!40000 ALTER TABLE `posts` DISABLE KEYS */;
/*!40000 ALTER TABLE `posts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_notification_settings`
--

DROP TABLE IF EXISTS `user_notification_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_notification_settings` (
  `setting_id` int NOT NULL AUTO_INCREMENT,
  `user_id` char(36) NOT NULL,
  `notification_hour` int DEFAULT '12',
  `notification_minute` int DEFAULT '0',
  `motivational_enabled` tinyint(1) DEFAULT '1',
  `ai_suggestions_enabled` tinyint(1) DEFAULT '1',
  `timezone` varchar(50) DEFAULT 'UTC',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`setting_id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_notification_settings`
--

LOCK TABLES `user_notification_settings` WRITE;
/*!40000 ALTER TABLE `user_notification_settings` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_notification_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` char(36) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password_hash` text NOT NULL,
  `avatar_color` varchar(7) DEFAULT '#808080',
  `is_anonymous` tinyint(1) DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('1','dogukan','dogukangulumsek@gmail.com','test_hash_123','#808080',0,'2026-04-28 13:40:40');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'moodjournal'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-05 15:56:01
