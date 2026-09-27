-- ClassicX Database Schema & Seed Data for MariaDB

SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS bd_classicx CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bd_classicx;
SET NAMES utf8mb4;

-- Drop existing tables if re-initializing
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS bookmarks;
DROP TABLE IF EXISTS retweets;
DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS follows;
DROP TABLE IF EXISTS tweets;
DROP TABLE IF EXISTS trends;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

-- Users table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    handle VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    bio VARCHAR(280) DEFAULT '',
    location VARCHAR(100) DEFAULT '',
    website VARCHAR(100) DEFAULT '',
    avatar_url VARCHAR(255) DEFAULT '',
    banner_url VARCHAR(255) DEFAULT '',
    is_verified TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tweets / Posts table
CREATE TABLE tweets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(255) DEFAULT NULL,
    parent_id INT DEFAULT NULL,
    repost_id INT DEFAULT NULL,
    likes_count INT DEFAULT 0,
    retweets_count INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    views_count INT DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_parent (parent_id),
    INDEX idx_repost (repost_id),
    INDEX idx_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Likes table
CREATE TABLE likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tweet_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_tweet (user_id, tweet_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (tweet_id) REFERENCES tweets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Retweets table
CREATE TABLE retweets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tweet_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_retweet (user_id, tweet_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (tweet_id) REFERENCES tweets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bookmarks table
CREATE TABLE bookmarks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    tweet_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_bookmark (user_id, tweet_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (tweet_id) REFERENCES tweets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Follows table
CREATE TABLE follows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_follower_following (follower_id, following_id),
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Notifications table
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    actor_id INT NOT NULL,
    type VARCHAR(20) NOT NULL,
    tweet_id INT DEFAULT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trends table
CREATE TABLE trends (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(50) DEFAULT 'Trending',
    topic VARCHAR(100) NOT NULL,
    post_count VARCHAR(50) DEFAULT '12.5K posts'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seed Data: Users
-- Passwords default to "123456"
INSERT INTO users (id, username, handle, email, password_hash, name, bio, location, website, avatar_url, banner_url, is_verified, created_at) VALUES
(1, 'classicx', 'classicx', 'team@classicx.local', '123456', 'ClassicX Official', 'The everything app rebuilt from the ground up on Classic ASP (VBScript), MariaDB, and Alpine.js. 𝕏', 'Cyberspace', 'https://classicx.local', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=1200&auto=format&fit=crop&q=80', 1, NOW() - INTERVAL 10 DAY),
(2, 'elonmusk', 'elonmusk', 'elon@x.com', '123456', 'Elon Musk', 'Owner of ClassicX. Let that sink in. Optimizing server latency down to the microsecond.', 'Starbase, TX', 'https://x.com', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200&auto=format&fit=crop&q=80', 1, NOW() - INTERVAL 9 DAY),
(3, 'satyanadella', 'satyanadella', 'satya@microsoft.com', '123456', 'Satya Nadella', 'Chairman and CEO, Microsoft. Excited to see Classic ASP and VBScript alive and thriving on modern cloud containers!', 'Redmond, WA', 'https://microsoft.com', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1200&auto=format&fit=crop&q=80', 1, NOW() - INTERVAL 8 DAY),
(4, 'davecan', 'davecan', 'dave@saneasp.com', '123456', 'David Canfield', 'Creator of the Sane MVC Framework for Classic ASP. Turning legacy VBScript into clean enterprise MVC architectures.', 'Austin, TX', 'https://github.com/davecan/Sane', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1200&auto=format&fit=crop&q=80', 1, NOW() - INTERVAL 7 DAY),
(5, 'retrodev', 'retrodev', 'retro@developer.io', '123456', 'Retro Dev', 'Pair programming in 2026 with ASP 3.0, MariaDB 10, Bootstrap 5.3 and Alpine.js. Pure engineering joy!', 'San Francisco, CA', 'https://github.com', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80', 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=1200&auto=format&fit=crop&q=80', 0, NOW() - INTERVAL 6 DAY);

-- Seed Data: Tweets
INSERT INTO tweets (id, user_id, content, image_url, parent_id, repost_id, likes_count, retweets_count, replies_count, views_count, created_at) VALUES
(1, 1, 'Welcome to ClassicX! 🚀\n\nA full Twitter/X clone running on Classic ASP (VBScript), Sane MVC Architecture, MariaDB, Docker AXONASP, Bootstrap 5.3, and Alpine.js. Nostalgia meets modern agility.', 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80', NULL, NULL, 42, 18, 4, 3842, NOW() - INTERVAL 5 HOUR),
(2, 2, 'Running ClassicX entirely on AXONASP in Docker with MariaDB. Bytecode compilation is blazing fast. Who said Classic ASP cannot scale to millions of users? ⚡', NULL, NULL, NULL, 128, 56, 12, 12450, NOW() - INTERVAL 4 HOUR),
(3, 4, 'Seeing Sane MVC powering ClassicX brings back great memories. Controllers, Domain Models, Automapper and clean Separation of Concerns in pure VBScript. #ClassicASP #SaneMVC', NULL, NULL, NULL, 29, 9, 3, 1890, NOW() - INTERVAL 3 HOUR),
(4, 3, 'Incredible tribute to Microsoft Active Server Pages! Combined with modern Alpine.js micro-reactivity and Bootstrap 5.3 dark theme, it feels as responsive as the original X.', NULL, NULL, NULL, 75, 23, 5, 5420, NOW() - INTERVAL 2 HOUR),
(5, 5, 'Just tested posting, liking, and retweeting on ClassicX. The UI fidelity to Twitter/X is mind-blowing. Dark mode is on point! 🖤', NULL, NULL, NULL, 15, 3, 2, 850, NOW() - INTERVAL 45 MINUTE),
-- Reply to Tweet 1
(6, 2, 'Great work team! Server response time is under 15ms.', NULL, 1, NULL, 19, 2, 1, 1200, NOW() - INTERVAL 3 HOUR),
(7, 4, 'The MariaDB integration via G3DB is seamless.', NULL, 1, NULL, 12, 1, 0, 780, NOW() - INTERVAL 2 HOUR);

-- Update reply counts
UPDATE tweets SET replies_count = 2 WHERE id = 1;

-- Seed Data: Follows
INSERT INTO follows (follower_id, following_id, created_at) VALUES
(1, 2, NOW()),
(1, 3, NOW()),
(1, 4, NOW()),
(2, 1, NOW()),
(3, 1, NOW()),
(4, 1, NOW()),
(5, 1, NOW()),
(5, 2, NOW());

-- Seed Data: Likes
INSERT INTO likes (user_id, tweet_id, created_at) VALUES
(1, 1, NOW()),
(1, 2, NOW()),
(2, 1, NOW()),
(3, 1, NOW()),
(4, 1, NOW()),
(5, 1, NOW()),
(5, 2, NOW());

-- Seed Data: Retweets
INSERT INTO retweets (user_id, tweet_id, created_at) VALUES
(2, 1, NOW()),
(4, 1, NOW()),
(5, 1, NOW());

-- Seed Data: Trends
INSERT INTO trends (category, topic, post_count) VALUES
('Technology · Trending', '#ClassicASP', '84.2K posts'),
('Web Development · Trending', '#AlpineJS', '45.1K posts'),
('Software Architecture · Trending', '#SaneMVC', '28.9K posts'),
('Database · Trending', '#MariaDB', '67.4K posts'),
('Technology · Trending', '#AxonASP', '19.8K posts'),
('Entertainment · Trending', 'ClassicX Clone', '102K posts');
