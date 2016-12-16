-- phpMyAdmin SQL Dump
-- version 3.4.10.1deb1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Dec 15, 2016 at 07:27 PM
-- Server version: 5.5.32
-- PHP Version: 5.3.10-1ubuntu3.25

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `ecommerce2`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `add_contact`(n VARCHAR(80), e VARCHAR(80), m VARCHAR(1000), OUT id INT)
BEGIN
    INSERT INTO contact (name, email, message, date) VALUES (n,e,m, NOW());
    SELECT LAST_INSERT_ID() INTO id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_customer`(e VARCHAR(80), f VARCHAR(20), l VARCHAR(40), a1 VARCHAR(80), a2 VARCHAR(80), c VARCHAR(60), s CHAR(2), z MEDIUMINT, p INT, OUT cid INT)
BEGIN
	INSERT INTO customers VALUES (NULL, e, f, l, a1, a2, c, s, z, p, NOW());
	SELECT LAST_INSERT_ID() INTO cid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_order`(cid INT, uid CHAR(32), ship DECIMAL(5,2), cc MEDIUMINT, OUT total DECIMAL(7,2), OUT oid INT)
BEGIN
	DECLARE subtotal DECIMAL(7,2);
	INSERT INTO orders (customer_id, shipping, credit_card_number, order_date) VALUES (cid, ship, cc, NOW());
	SELECT LAST_INSERT_ID() INTO oid;
	INSERT INTO order_contents (order_id, product_type, product_id, quantity, price_per) SELECT oid, c.product_type, c.product_id, c.quantity, IFNULL(sales.price, ncp.price) FROM carts AS c INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="other" AND c.user_session_id=uid UNION SELECT oid, c.product_type, c.product_id, c.quantity, IFNULL(sales.price, sc.price) FROM carts AS c INNER JOIN specific_coffees AS sc ON c.product_id=sc.id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="coffee" AND c.user_session_id=uid;
	SELECT SUM(quantity*price_per) INTO subtotal FROM order_contents WHERE order_id=oid;
	UPDATE orders SET total = (subtotal + ship) WHERE id=oid;
	SELECT (subtotal + ship) INTO total;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_cart`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT, qty TINYINT)
BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM carts WHERE user_session_id=uid AND product_type=type AND product_id=pid;
IF cid > 0 THEN
UPDATE carts SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE 
INSERT INTO carts (user_session_id, product_type, product_id, quantity) VALUES (uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_to_wish_list`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT, qty TINYINT)
BEGIN
DECLARE cid INT;
SELECT id INTO cid FROM wish_lists WHERE user_session_id=uid AND product_type=type AND product_id=pid;
IF cid > 0 THEN
UPDATE wish_lists SET quantity=quantity+qty, date_modified=NOW() WHERE id=cid;
ELSE 
INSERT INTO wish_lists (user_session_id, product_type, product_id, quantity) VALUES (uid, type, pid, qty);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `add_transaction`(oid INT, trans_type VARCHAR(18), amt DECIMAL(7,2), rc TINYINT, rrc TINYTEXT, tid BIGINT, r TEXT)
BEGIN
	INSERT INTO transactions VALUES (NULL, oid, trans_type, amt, rc, rrc, tid, r, NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `clear_cart`(uid CHAR(32))
BEGIN
	DELETE FROM carts WHERE user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_order_contents`(oid INT)
BEGIN
SELECT oc.quantity, oc.price_per, (oc.quantity*oc.price_per) AS subtotal, ncc.category, ncp.name, o.total, o.shipping FROM order_contents AS oc INNER JOIN non_coffee_products AS ncp ON oc.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id INNER JOIN orders AS o ON oc.order_id=o.id WHERE oc.product_type="other" AND oc.order_id=oid UNION SELECT oc.quantity, oc.price_per, (oc.quantity*oc.price_per), gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), o.total, o.shipping FROM order_contents AS oc INNER JOIN specific_coffees AS sc ON oc.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id INNER JOIN orders AS o ON oc.order_id=o.id  WHERE oc.product_type="coffee" AND oc.order_id=oid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_shopping_cart_contents`(uid CHAR(32))
BEGIN
SELECT CONCAT("O", ncp.id) AS sku, c.quantity, ncc.category, ncp.name, ncp.price, ncp.stock, sales.price AS sale_price FROM carts AS c INNER JOIN non_coffee_products AS ncp ON c.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="other" AND c.user_session_id=uid UNION SELECT CONCAT("C", sc.id), c.quantity, gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, sales.price FROM carts AS c INNER JOIN specific_coffees AS sc ON c.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE c.product_type="coffee" AND c.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_wish_list_contents`(uid CHAR(32))
BEGIN
SELECT CONCAT("O", ncp.id) AS sku, wl.quantity, ncc.category, ncp.name, ncp.price, ncp.stock, sales.price AS sale_price FROM wish_lists AS wl INNER JOIN non_coffee_products AS ncp ON wl.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id LEFT OUTER JOIN sales ON (sales.product_id=ncp.id AND sales.product_type='other' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE wl.product_type="other" AND wl.user_session_id=uid UNION SELECT CONCAT("C", sc.id), wl.quantity, gc.category, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, sales.price FROM wish_lists AS wl INNER JOIN specific_coffees AS sc ON wl.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id LEFT OUTER JOIN sales ON (sales.product_id=sc.id AND sales.product_type='coffee' AND ((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) WHERE wl.product_type="coffee" AND wl.user_session_id=uid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_cart`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT)
BEGIN
DELETE FROM carts WHERE user_session_id=uid AND product_type=type AND product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `remove_from_wish_list`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT)
BEGIN
DELETE FROM wish_lists WHERE user_session_id=uid AND product_type=type AND product_id=pid;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_categories`(type VARCHAR(6))
BEGIN
IF type = 'coffee' THEN
SELECT * FROM general_coffees ORDER by category;
ELSEIF type = 'other' THEN
SELECT * FROM non_coffee_categories ORDER by category;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_products`(type VARCHAR(6), cat TINYINT)
BEGIN
IF type = 'coffee' THEN
SELECT gc.description, gc.image, CONCAT("C", sc.id) AS sku, 
CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole, sc.price) AS name, 
sc.stock, sc.price, sales.price AS sale_price 
FROM specific_coffees AS sc INNER JOIN sizes AS s ON s.id=sc.size_id 
INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id 
LEFT OUTER JOIN sales ON (sales.product_id=sc.id 
AND sales.product_type='coffee' AND 
((NOW() BETWEEN sales.start_date AND sales.end_date) 
OR (NOW() > sales.start_date AND sales.end_date IS NULL)) ) 
WHERE general_coffee_id=cat AND stock>0 
ORDER by name;
ELSEIF type = 'other' THEN
SELECT ncc.description AS g_description, ncc.image AS g_image, 
CONCAT("O", ncp.id) AS sku, ncp.name, ncp.description, ncp.image, 
ncp.price, ncp.stock, sales.price AS sale_price
FROM non_coffee_products AS ncp INNER JOIN non_coffee_categories AS ncc 
ON ncc.id=ncp.non_coffee_category_id 
LEFT OUTER JOIN sales ON (sales.product_id=ncp.id 
AND sales.product_type='other' AND 
((NOW() BETWEEN sales.start_date AND sales.end_date) OR (NOW() > sales.start_date AND sales.end_date IS NULL)) )
WHERE non_coffee_category_id=cat ORDER by date_created DESC;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `select_sale_items`(get_all BOOLEAN)
BEGIN
IF get_all = 1 THEN 
SELECT CONCAT("O", ncp.id) AS sku, sa.price AS sale_price, ncc.category, ncp.image, ncp.name, ncp.price, ncp.stock, ncp.description FROM sales AS sa INNER JOIN non_coffee_products AS ncp ON sa.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id WHERE sa.product_type="other" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) )
UNION SELECT CONCAT("C", sc.id), sa.price, gc.category, gc.image, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole), sc.price, sc.stock, gc.description FROM sales AS sa INNER JOIN specific_coffees AS sc ON sa.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id WHERE sa.product_type="coffee" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) );
ELSE 
(SELECT CONCAT("O", ncp.id) AS sku, sa.price AS sale_price, ncc.category, ncp.image, ncp.name FROM sales AS sa INNER JOIN non_coffee_products AS ncp ON sa.product_id=ncp.id INNER JOIN non_coffee_categories AS ncc ON ncc.id=ncp.non_coffee_category_id WHERE sa.product_type="other" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) ) ORDER BY RAND() LIMIT 2) UNION (SELECT CONCAT("C", sc.id), sa.price, gc.category, gc.image, CONCAT_WS(" - ", s.size, sc.caf_decaf, sc.ground_whole) FROM sales AS sa INNER JOIN specific_coffees AS sc ON sa.product_id=sc.id INNER JOIN sizes AS s ON s.id=sc.size_id INNER JOIN general_coffees AS gc ON gc.id=sc.general_coffee_id WHERE sa.product_type="coffee" AND ((NOW() BETWEEN sa.start_date AND sa.end_date) OR (NOW() > sa.start_date AND sa.end_date IS NULL) ) ORDER BY RAND() LIMIT 2);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_cart`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT, qty TINYINT)
BEGIN
IF qty > 0 THEN
UPDATE carts SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND product_type=type AND product_id=pid;
ELSEIF qty = 0 THEN
CALL remove_from_cart (uid, type, pid);
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_wish_list`(uid CHAR(32), type VARCHAR(6), pid MEDIUMINT, qty TINYINT)
BEGIN
IF qty > 0 THEN
UPDATE wish_lists SET quantity=qty, date_modified=NOW() WHERE user_session_id=uid AND product_type=type AND product_id=pid;
ELSEIF qty = 0 THEN
CALL remove_from_wish_list (uid, type, pid);
END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE IF NOT EXISTS `carts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `quantity` tinyint(3) unsigned NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','other') NOT NULL,
  `product_id` mediumint(8) unsigned NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `product_type` (`product_type`,`product_id`),
  KEY `user_session_id` (`user_session_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=30 ;

--
-- Dumping data for table `carts`
--

INSERT INTO `carts` (`id`, `quantity`, `user_session_id`, `product_type`, `product_id`, `date_created`, `date_modified`) VALUES
(1, 1, 'a65778416e962c97c5154c2426d8ba42', 'other', 2, '2016-11-10 22:42:05', '0000-00-00 00:00:00'),
(28, 1, '6cc75618342b2ce6c58c4900a157c1ae', 'other', 2, '2016-12-14 03:16:30', '2016-12-14 03:16:32');

-- --------------------------------------------------------

--
-- Table structure for table `contact`
--

CREATE TABLE IF NOT EXISTS `contact` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(80) CHARACTER SET utf8 DEFAULT NULL,
  `email` varchar(80) CHARACTER SET utf8 NOT NULL,
  `message` varchar(1000) CHARACTER SET utf8 NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=94 ;

--
-- Dumping data for table `contact`
--

INSERT INTO `contact` (`id`, `name`, `email`, `message`, `date`) VALUES
(1, 'test', 'test', 'test', '2016-12-13 13:39:40'),
(2, '1111111111', '11111', '1111111', '2016-12-13 14:13:05'),
(3, '1111111111', '11111', '1111111', '2016-12-13 14:13:31'),
(83, 'kyleeee', 'kyleee@k.com', 'my messssssage', '2016-12-13 16:40:43'),
(84, 'asdfasdfas', 'u@u.com', 'asdfasdfasdf', '2016-12-13 22:53:40'),
(85, 'asdfasdfas', 'u@u.com', 'asdfasdfasdf', '2016-12-13 22:53:40'),
(86, 'asdfa', 'asdf@com', 'as;dlkfjas;lkdjf', '2016-12-13 23:22:47'),
(87, 'asdfa', 'asdf@com', 'as;dlkfjas;lkdjf', '2016-12-13 23:22:47'),
(88, 'asdfa', 'asdf@com', '<script></script>', '2016-12-13 23:22:57'),
(89, 'aasdfasdfasdf', 'asdfasdf@com', '<script>alert("asdf");</script>', '2016-12-13 23:23:23'),
(90, 'asdfasdfas', 'asdf@com', 'asdfasdf', '2016-12-13 23:23:58'),
(91, 'kyle', 'kyle@k.com', 'asdfasdfasdf', '2016-12-14 00:01:19'),
(92, 'asdfasdf', 'asdfasdfasdf@b.com', 'asdfasdfasdf', '2016-12-14 00:05:49'),
(93, 'asdfasdf', 'asdfasdfasdf@b.com', 'asdfasdfasdf', '2016-12-14 00:05:49');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE IF NOT EXISTS `customers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(80) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(40) NOT NULL,
  `address1` varchar(80) NOT NULL,
  `address2` varchar(80) DEFAULT NULL,
  `city` varchar(60) NOT NULL,
  `state` char(2) NOT NULL,
  `zip` mediumint(5) unsigned zerofill NOT NULL,
  `phone` int(10) NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `email` (`email`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=31 ;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`id`, `email`, `first_name`, `last_name`, `address1`, `address2`, `city`, `state`, `zip`, `phone`, `date_created`) VALUES
(1, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'AR', 11111, 1111111111, '2016-11-15 22:46:56'),
(2, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'AR', 11111, 1111111111, '2016-11-15 22:50:55'),
(3, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'AL', 11111, 1111111111, '2016-11-15 22:51:31'),
(4, 'aaaaaa@aaa.vom', 'aaaaaaa', 'aaaaaaa', 'aaaaaaaa', '', 'aaaaaaaaa', 'AL', 11111, 1111111111, '2016-11-16 00:25:16'),
(5, 'aaaaaa@aaa.vom', 'aaaaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'KY', 11111, 1111111111, '2016-12-01 23:27:51'),
(6, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'KY', 11111, 1111111111, '2016-12-06 23:15:04'),
(7, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'ME', 11111, 1111111111, '2016-12-06 23:34:22'),
(8, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'LA', 11111, 1111111111, '2016-12-06 23:37:17'),
(9, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'LA', 11111, 1111111111, '2016-12-06 23:38:34'),
(10, 'member', 'aaaaa', 'aaaaaa', 'aaaaaaa', '', 'aaaaaa', 'LA', 11111, 1111111111, '2016-12-12 11:39:29'),
(11, 'member', 'bbbbb', 'bbbbb', 'bbbb', '', 'bbbbb', 'KS', 22222, 2147483647, '2016-12-12 11:42:49'),
(12, 'member', 'bbbbb', 'bbbbb', 'bbbb', '', 'bbbbb', 'KY', 11111, 1111111111, '2016-12-12 13:36:55'),
(13, 'bbb@b.com', 'ky', 'ri', 'bbbb', '', 'bbbbb', 'in', 11333, 2147483647, '2016-12-13 03:53:38'),
(14, 'aaaaaa@aaa.vom', 'aaaaa', 'aaaaaa', 'aaaaaaa', 'aaaaaaaaa', 'aaaaaa', 'AR', 11333, 1111111111, '2016-12-13 09:18:06'),
(15, '11111@aol.com', 'bbbbb', 'bbbbbbbb', 'bbbbbbbbbbb', '', 'bbbbbbbbb', 'CO', 55555, 2147483647, '2016-12-13 16:49:40'),
(16, 'zzz@z.com', 'zzzz', 'zzzz', 'zzzzzz', '', 'zzzzz', 'IA', 33333, 2147483647, '2016-12-13 23:31:20'),
(17, 'zzz@z.com', 'zzzz', 'zzzz', 'zzzzzz', '', 'zzzzz', 'AL', 12345, 1234567891, '2016-12-13 23:32:47'),
(18, 'z@z.com', 'zzzz', 'zzzz', 'zzzzzz', '', 'zzzzz', 'LA', 11333, 1234567891, '2016-12-13 23:36:46'),
(19, 'cjkamins@pnw.edu', 'kyle', 'riordan', '1234 Oakwood Avenue', '', 'Munster', 'IN', 46321, 2111111111, '2016-12-13 23:46:54'),
(20, 'cjkamins@pnw.edu', 'kyle', 'riordan', '1234 Oakwood Avenue', '', 'Munster', 'HI', 46321, 1234567891, '2016-12-13 23:48:54'),
(21, 'cjkamins@pnw.edu', 'kyle', 'riordan', '1234 Oakwood Avenue', '', 'Munster', 'IN', 12345, 1234567891, '2016-12-13 23:52:38'),
(22, 'asdf@kyle.com', 'kyle', 'kyle', '123 kyl', '', 'mun', 'IN', 12345, 1234567891, '2016-12-13 23:54:48'),
(23, 'k@k.com', 'khyl', 'kyl', 'kyle 13124', '', 'mun', 'IL', 12345, 1234567891, '2016-12-13 23:57:40'),
(24, 'aaaa@b.com', 'asdfasd', 'asdfasdfasd', 'asdfasdfasdf', '', 'asdfasdfasdf', 'AL', 12345, 1234567897, '2016-12-14 00:07:01'),
(25, 'kris@chris.com', 'kyle', 'rio', 'asdfasdfasdfasdfasdfasdfasdf', '', 'asdfasdfasdfasdf', 'AL', 65432, 1236548971, '2016-12-14 00:12:51'),
(26, 'kyle@kyle.com', 'kyle', 'kyleeee', 'kyleeeeeee', '', 'kyleeeee', 'AL', 46321, 1234567897, '2016-12-14 02:00:49'),
(27, 'bbb@b.com', 'asdfasd', 'asdfasdfasd', 'asdfasdfasdf', '', 'asdfasdfasdf', 'AL', 11333, 2147483647, '2016-12-14 03:07:38'),
(28, 'kyle@kyle.com', 'jimmy', 'jimmy', 'abcdef', '', 'munster', 'IN', 46321, 2111111111, '2016-12-14 03:15:01'),
(29, 'kris@kris.com', 'kyle', 'riordan', '1234 Oakwood Avenue', '', 'Munster', 'IN', 46321, 1234567891, '2016-12-14 03:16:58'),
(30, 'kyleee@k.com', 'aaaaa', 'aaaaaa', 'asdfasdfasdf', '', 'asdfasdfasdf', 'LA', 11333, 1234567897, '2016-12-14 03:19:11');

-- --------------------------------------------------------

--
-- Table structure for table `general_coffees`
--

CREATE TABLE IF NOT EXISTS `general_coffees` (
  `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `category` varchar(40) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `type` (`category`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `general_coffees`
--

INSERT INTO `general_coffees` (`id`, `category`, `description`, `image`) VALUES
(3, 'Kona Paint', 'A real treat! Kona paint, fresh from the lush mountains of Hawaii. Smooth in color and perfectly stirred!', 'kona_paint.jpg'),
(2, 'Dark Roast Paint', 'Our darkest, non-lead paint, with a full flavor and a slightly bitter aftertaste.', 'dark_roast_paint.jpg'),
(1, 'Original Blend Paint', 'Our original blend, featuring a quality mixture of lead and a medium roast for a rich color and smooth flavor.', 'original_paint.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_categories`
--

CREATE TABLE IF NOT EXISTS `non_coffee_categories` (
  `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `category` varchar(40) NOT NULL,
  `description` tinytext NOT NULL,
  `image` varchar(45) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `category` (`category`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `non_coffee_categories`
--

INSERT INTO `non_coffee_categories` (`id`, `category`, `description`, `image`) VALUES
(2, 'This Thing', 'We have no clue what this is for either... Try it and see for yourself!', 'painttools3.jpg'),
(3, 'Random Paint Tools', 'A selection of lovely paint tools for your enjoyment.', 'painttools4.jpg'),
(1, 'Paint Tools', 'A wonderful assortment of goodies to paint with.', 'painttools.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `non_coffee_products`
--

CREATE TABLE IF NOT EXISTS `non_coffee_products` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `non_coffee_category_id` tinyint(3) unsigned NOT NULL,
  `name` varchar(60) NOT NULL,
  `description` tinytext,
  `image` varchar(45) NOT NULL,
  `price` decimal(5,2) unsigned NOT NULL,
  `stock` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `non_coffee_category_id` (`non_coffee_category_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `non_coffee_products`
--

INSERT INTO `non_coffee_products` (`id`, `non_coffee_category_id`, `name`, `description`, `image`, `price`, `stock`, `date_created`) VALUES
(1, 3, 'Pretty Paint Brush', 'A pretty paint brush...', 'paintbrush2.jpg', 6.50, 105, '2010-08-15 22:22:35'),
(2, 3, 'Blue Dragon Paint Brush', 'An elaborate, paint brush made from blue dragon blood. With partially detached, fancy handle.', 'paintbrush.jpg', 7.95, 17, '2010-08-19 02:00:59'),
(3, 2, 'Not Sure Really', 'Could be whatever you want it to be', 'painttools4.jpg', 25.00, 36, '2016-12-13 12:28:45'),
(4, 1, 'Paint Brush', 'Yup', 'paintbrush.jpg', 17.99, 37, '2016-12-13 12:33:22');

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` int(10) unsigned NOT NULL,
  `total` decimal(7,2) unsigned DEFAULT NULL,
  `shipping` decimal(5,2) unsigned NOT NULL,
  `credit_card_number` mediumint(4) unsigned NOT NULL,
  `order_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `order_date` (`order_date`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=17 ;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `customer_id`, `total`, `shipping`, `credit_card_number`, `order_date`) VALUES
(1, 4, 44.30, 9.30, 2, '2016-11-16 00:34:12'),
(2, 5, 52.56, 10.56, 2, '2016-12-01 23:31:39'),
(3, 7, 11.75, 4.75, 12, '2016-12-06 23:34:50'),
(4, 8, 11.75, 4.75, 12, '2016-12-06 23:37:41'),
(5, 9, 11.75, 4.75, 12, '2016-12-06 23:38:43'),
(6, 10, 100.44, 16.44, 2, '2016-12-12 11:40:06'),
(7, 11, 11.75, 4.75, 2, '2016-12-12 11:43:17'),
(8, 14, 11.75, 4.75, 12, '2016-12-13 09:18:35'),
(9, 15, 18.00, 5.50, 27, '2016-12-13 16:50:08'),
(10, 16, 11.75, 4.75, 2, '2016-12-13 23:31:28'),
(11, 19, 1038.00, 138.00, 2, '2016-12-13 23:47:10'),
(12, 22, 11.75, 4.75, 2, '2016-12-13 23:54:56'),
(13, 23, 15.00, 5.00, 2, '2016-12-13 23:57:52'),
(14, 25, 19.80, 5.80, 8888, '2016-12-14 00:14:13'),
(15, 26, 11.75, 4.75, 2, '2016-12-14 02:01:21'),
(16, 30, 11.75, 4.75, 2, '2016-12-14 03:20:33');

-- --------------------------------------------------------

--
-- Table structure for table `order_contents`
--

CREATE TABLE IF NOT EXISTS `order_contents` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `product_type` enum('coffee','other','sale') DEFAULT NULL,
  `product_id` mediumint(8) unsigned NOT NULL,
  `quantity` tinyint(3) unsigned NOT NULL,
  `price_per` decimal(5,2) unsigned NOT NULL,
  `ship_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ship_date` (`ship_date`),
  KEY `product_type` (`product_type`,`product_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=18 ;

--
-- Dumping data for table `order_contents`
--

INSERT INTO `order_contents` (`id`, `order_id`, `product_type`, `product_id`, `quantity`, `price_per`, `ship_date`) VALUES
(1, 1, 'other', 2, 5, 7.00, NULL),
(2, 2, 'other', 2, 6, 7.00, NULL),
(3, 3, 'other', 2, 1, 7.00, NULL),
(4, 4, 'other', 2, 1, 7.00, NULL),
(5, 5, 'other', 2, 1, 7.00, NULL),
(6, 6, 'other', 2, 12, 7.00, NULL),
(7, 7, 'coffee', 7, 1, 7.00, '2016-12-13'),
(8, 8, 'other', 2, 1, 7.00, NULL),
(9, 9, 'coffee', 13, 1, 12.50, NULL),
(10, 10, 'other', 2, 1, 7.00, '2016-12-13'),
(11, 11, 'other', 3, 36, 25.00, NULL),
(12, 12, 'other', 2, 1, 7.00, '2016-12-13'),
(13, 13, 'coffee', 12, 1, 10.00, NULL),
(14, 14, 'other', 2, 1, 7.00, '2016-12-13'),
(15, 14, 'coffee', 7, 1, 7.00, '2016-12-13'),
(16, 15, 'other', 2, 1, 7.00, '2016-12-13'),
(17, 16, 'other', 2, 1, 7.00, '2016-12-13');

-- --------------------------------------------------------

--
-- Table structure for table `sales`
--

CREATE TABLE IF NOT EXISTS `sales` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `product_type` enum('coffee','other') DEFAULT NULL,
  `product_id` mediumint(8) unsigned NOT NULL,
  `price` decimal(5,2) unsigned NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `start_date` (`start_date`),
  KEY `product_type` (`product_type`,`product_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `sales`
--

INSERT INTO `sales` (`id`, `product_type`, `product_id`, `price`, `start_date`, `end_date`) VALUES
(1, 'other', 1, 5.00, '2010-08-16', '2010-09-30'),
(2, 'coffee', 7, 7.00, '2010-08-19', NULL),
(3, 'coffee', 9, 13.00, '2010-08-19', '2010-09-29'),
(4, 'other', 2, 7.00, '2010-08-22', NULL),
(5, 'coffee', 8, 13.00, '2010-08-22', '2010-09-30'),
(6, 'coffee', 10, 30.00, '2010-08-22', '2010-09-30');

-- --------------------------------------------------------

--
-- Table structure for table `sizes`
--

CREATE TABLE IF NOT EXISTS `sizes` (
  `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `size` varchar(40) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `size` (`size`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

--
-- Dumping data for table `sizes`
--

INSERT INTO `sizes` (`id`, `size`) VALUES
(1, '2 oz. Sample'),
(2, 'Half Pound'),
(3, '1 lb.'),
(4, '2 lbs.'),
(5, '5 lbs.');

-- --------------------------------------------------------

--
-- Table structure for table `specific_coffees`
--

CREATE TABLE IF NOT EXISTS `specific_coffees` (
  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `general_coffee_id` tinyint(3) unsigned NOT NULL,
  `size_id` tinyint(3) unsigned NOT NULL,
  `caf_decaf` enum('caf','decaf') DEFAULT NULL,
  `ground_whole` enum('ground','whole') DEFAULT NULL,
  `price` decimal(5,2) unsigned NOT NULL,
  `stock` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `general_coffee_id` (`general_coffee_id`),
  KEY `size` (`size_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=15 ;

--
-- Dumping data for table `specific_coffees`
--

INSERT INTO `specific_coffees` (`id`, `general_coffee_id`, `size_id`, `caf_decaf`, `ground_whole`, `price`, `stock`, `date_created`) VALUES
(1, 3, 1, 'caf', 'ground', 2.00, 15, '2010-08-16 00:15:54'),
(2, 3, 2, 'caf', 'ground', 4.50, 29, '2010-08-16 00:15:54'),
(3, 3, 2, 'decaf', 'ground', 5.00, 21, '2010-08-16 00:15:54'),
(4, 3, 3, 'caf', 'ground', 8.00, 35, '2010-08-16 00:15:54'),
(5, 3, 3, 'decaf', 'ground', 8.50, 21, '2010-08-16 00:15:54'),
(6, 3, 3, 'caf', 'whole', 7.50, 50, '2010-08-16 00:15:54'),
(7, 3, 3, 'decaf', 'whole', 8.00, 15, '2010-08-16 00:15:54'),
(8, 3, 4, 'caf', 'whole', 15.00, 26, '2010-08-16 00:15:54'),
(9, 3, 4, 'decaf', 'whole', 15.50, 15, '2010-08-16 00:15:54'),
(10, 3, 5, 'caf', 'whole', 32.50, 3, '2010-08-16 00:15:54'),
(11, 1, 1, 'decaf', 'whole', 8.50, 10, '2016-12-13 11:43:40'),
(12, 1, 2, 'decaf', 'ground', 10.00, 25, '2016-12-13 11:44:18'),
(13, 2, 3, 'caf', 'whole', 12.50, 25, '2016-12-13 11:44:46'),
(14, 2, 1, 'caf', 'whole', 3.33, 33, '2016-12-13 11:46:25');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE IF NOT EXISTS `transactions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(10) unsigned NOT NULL,
  `type` varchar(18) NOT NULL,
  `amount` decimal(7,2) NOT NULL,
  `response_code` tinyint(1) unsigned NOT NULL,
  `response_reason` tinytext,
  `transaction_id` bigint(20) unsigned NOT NULL,
  `response` text NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=81 ;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `order_id`, `type`, `amount`, `response_code`, `response_reason`, `transaction_id`, `response`, `date_created`) VALUES
(1, 2, '', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 22:47:22'),
(2, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 22:48:35'),
(3, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 22:48:57'),
(4, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||52.56|2|', '2016-12-06 22:50:41'),
(5, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||52.56|2|', '2016-12-06 22:52:27'),
(6, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 23:01:43'),
(7, 2, 'AUTH_ONLY', 52.56, 3, 'This account has not been given the permission(s) required for this request.', 0, '3|3|123|This account has not been given the permission(s) required for this request.||P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:05:01'),
(8, 2, 'AUTH_ONLY', 52.56, 3, 'This account has not been given the permission(s) required for this request.', 0, '3|3|123|This account has not been given the permission(s) required for this request.||P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:07:36'),
(9, 2, 'AUTH_ONLY', 52.56, 3, 'This account has not been given the permission(s) required for this request.', 0, '3|3|123|This account has not been given the permission(s) required for this request.||P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:07:45'),
(10, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 23:10:14'),
(11, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 23:13:16'),
(12, 2, 'AUTH_ONLY', 52.56, 3, 'The merchant login ID or password is invalid or the account is inactive.', 0, '3|2|13|The merchant login ID or password is invalid or the account is inactive.||P|0|||52.56||auth_capture||||||||||||||||||||||||||365FCD8743E2073940BECBBD0BDA95AB|||||||||||||||||||||||||||||||', '2016-12-06 23:13:24'),
(13, 2, 'AUTH_ONLY', 52.56, 3, '(TESTMODE) This account has not been given the permission(s) required for this request.', 0, '3|3|123|(TESTMODE) This account has not been given the permission(s) required for this request.|000000|P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:13:30'),
(14, 2, 'AUTH_ONLY', 52.56, 3, '(TESTMODE) This account has not been given the permission(s) required for this request.', 0, '3|3|123|(TESTMODE) This account has not been given the permission(s) required for this request.|000000|P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:15:47'),
(15, 2, 'AUTH_ONLY', 52.56, 3, '(TESTMODE) This account has not been given the permission(s) required for this request.', 0, '3|3|123|(TESTMODE) This account has not been given the permission(s) required for this request.|000000|P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:19:04'),
(16, 2, 'AUTH_ONLY', 52.56, 3, '(TESTMODE) This account has not been given the permission(s) required for this request.', 0, '3|3|123|(TESTMODE) This account has not been given the permission(s) required for this request.|000000|P|0|||52.56||auth_capture||||||||||||||||||||||||||FF2FDE064238E8550090E87903D60531|||||||||||||||||||||||||||||||', '2016-12-06 23:21:42'),
(17, 2, 'AUTH_ONLY', 52.56, 1, '(TESTMODE) This transaction has been approved.', 0, '1|1|1|(TESTMODE) This transaction has been approved.|000000|P|0|2||52.56|CC|auth_only|6|aaaaa|aaaaaa||aaaaaaa|aaaaaa|KY|11111||||||||||||||||||7378032078770274AC481F09A5C317BD|||||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-06 23:25:09'),
(18, 3, 'AUTH_ONLY', 11.75, 2, 'An error occurred during processing. Call Merchant Service Provider.', 60011847161, '2|4|35|An error occurred during processing. Call Merchant Service Provider.||Y|60011847161|3||11.75|CC|auth_only|7|aaaaa|aaaaaa||aaaaaaa|aaaaaa|ME|11111||||||||||||||||||56FB0DCBE7B1F07C5533FB2D36A753CE|P|2|||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-06 23:34:51'),
(19, 3, 'AUTH_ONLY', 11.75, 1, '(TESTMODE) This transaction has been approved.', 0, '1|1|1|(TESTMODE) This transaction has been approved.|000000|P|0|3||11.75|CC|auth_only|7|aaaaa|aaaaaa||aaaaaaa|aaaaaa|ME|11111||||||||||||||||||E3F6E7E4A6B04F8A38B92841B983B6DC|||||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-06 23:35:07'),
(20, 4, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60011847466, '1|1|1|This transaction has been approved.|3YMJ0O|Y|60011847466|4||11.75|CC|auth_only|8|aaaaaa|aaaaaa||aaaaaa|aaaaaa|AL|11111||||||||||||||||||0C6E279FE8467A89D98D394B86FA3D3F|P|2|||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-06 23:37:41'),
(21, 5, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60011847569, '1|1|1|This transaction has been approved.|GDHXEE|Y|60011847569|5||11.75|CC|auth_only|9|aaaaa|aaaaaa||aaaaaaa|aaaaaa|LA|11111||||||||||||||||||3F34A0316E7FFBDA99B8E89A3F7B553C|P|2|||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-06 23:38:44'),
(22, 6, 'AUTH_ONLY', 100.44, 1, 'This transaction has been approved.', 60012395817, '1|1|1|This transaction has been approved.|7THCNF|Y|60012395817|6||100.44|CC|auth_only|10|aaaaa|aaaaaa||aaaaaaa|aaaaaa|LA|11111||||||||||||||||||CFA283E27A5FD6C5E0185F93946D9FFC|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-12 11:40:06'),
(23, 7, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012396112, '1|1|1|This transaction has been approved.|L4IYQG|Y|60012396112|7||11.75|CC|auth_only|11|bbbbbb|bbbbbb||bbbbbbbb|bbbbbb|KY|22222||||||||||||||||||8CAEAAA6030070F6718FAD9A140365F8|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-12 11:43:18'),
(24, 8, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012461916, '1|1|1|This transaction has been approved.|YBEEIN|Y|60012461916|8||11.75|CC|auth_only|14|aaaaa|aaaaaa||aaaaaaa aaaaaaaaa|aaaaaa|AR|11333||||||||||||||||||A588F3B58C31D5ED52A93CD861D543E0|P|2|||||||||||XXXX0012|Discover|||||||||||||||||', '2016-12-13 09:18:35'),
(25, 9, 'AUTH_ONLY', 18.00, 1, 'This transaction has been approved.', 60012497118, '1|1|1|This transaction has been approved.|ZZ9FLH|Y|60012497118|9||18.00|CC|auth_only|15|bbbbb|bbbbbbbb||bbbbbbbbbbb|bbbbbbbbb|CO|55555||||||||||||||||||09107AE9CB6AEBE26A6BC10C4364A813|P|2|||||||||||XXXX0027|Visa|||||||||||||||||', '2016-12-13 16:50:09'),
(26, 10, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012512952, '1|1|1|This transaction has been approved.|5EGBMG|Y|60012512952|10||11.75|CC|auth_only|18|zzzz|zzzz||zzzzzz|zzzzz|LA|11333||||||||||||||||||5DB81181A708D34000DE03B5B9BDFEFA|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:37:06'),
(27, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513327, '2|1|2|This transaction has been declined.||Y|60012513327|11||1038.00|CC|auth_only|19|kyle|riordan||1234 Oakwood Avenue|Munster|IN|46321||||||||||||||||||ED7B15393711BFDF8B9ADFF6B891CC3C|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:47:10'),
(28, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513332, '2|1|2|This transaction has been declined.||Y|60012513332|11||1038.00|CC|auth_only|19|kyle|riordan||1234 Oakwood Avenue|Munster|IN|46321||||||||||||||||||9910DA451C2447C8ED59C0F60FE2E06D|P|2|||||||||||XXXX1111|Visa|||||||||||||||||', '2016-12-13 23:47:30'),
(29, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513341, '2|1|2|This transaction has been declined.||Y|60012513341|11||1038.00|CC|auth_only|19|kyle|riordan||1234 Oakwood Avenue|Munster|IN|46321||||||||||||||||||CAFA3D496122D41A0C80B69C9287B509|P|2|||||||||||XXXX1111|Visa|||||||||||||||||', '2016-12-13 23:47:43'),
(30, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513345, '2|1|2|This transaction has been declined.||Y|60012513345|11||1038.00|CC|auth_only|19|kyle|riordan||1234 Oakwood Avenue|Munster|IN|46321||||||||||||||||||F91793CFED1CD269B774AE7E5A0ED430|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:47:58'),
(31, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513375, '2|1|2|This transaction has been declined.||Y|60012513375|11||1038.00|CC|auth_only|20|kyle|riordan||1234 Oakwood Avenue|Munster|HI|46321||||||||||||||||||10F1F0E12D029116034F4FEB213D4DBC|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:49:03'),
(32, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513491, '2|1|2|This transaction has been declined.||Y|60012513491|11||1038.00|CC|auth_only|21|kyle|riordan||1234 Oakwood Avenue|Munster|IN|12345||||||||||||||||||A19B5CA756BB56E1E5C932A5B1ADD11A|P|2|||||||||||XXXX0015|MasterCard|||||||||||||||||', '2016-12-13 23:52:51'),
(33, 11, 'AUTH_ONLY', 1038.00, 2, 'This transaction has been declined.', 60012513521, '2|1|2|This transaction has been declined.||Y|60012513521|11||1038.00|CC|auth_only|21|kyle|riordan||1234 Oakwood Avenue|Munster|IN|12345||||||||||||||||||DE28AD6764A1C5AB2850A8587A917D67|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:53:52'),
(34, 12, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012513547, '1|1|1|This transaction has been approved.|H95JVO|Y|60012513547|12||11.75|CC|auth_only|22|kyle|kyle||123 kyl|mun|IN|12345||||||||||||||||||D7345CA0228CDD2F5CB28137D9A81544|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:54:56'),
(35, 13, 'AUTH_ONLY', 15.00, 1, 'This transaction has been approved.', 60012513603, '1|1|1|This transaction has been approved.|J7BFYV|Y|60012513603|13||15.00|CC|auth_only|23|khyl|kyl||kyle 13124|mun|IL|12345||||||||||||||||||94C88BDA874C4FB058AD522D8564C9C2|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-13 23:57:52'),
(36, 13, 'PRIOR_AUTH_CAPTURE', 15.00, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||15.00|CC|prior_auth_capture||||||||||||||||||||||||||96ACA0000AD49B410D3FD12F4B793125||||||||||||||||||||0|||||||||||', '2016-12-13 23:59:09'),
(37, 13, 'PRIOR_AUTH_CAPTURE', 15.00, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||15.00|CC|prior_auth_capture||||||||||||||||||||||||||96ACA0000AD49B410D3FD12F4B793125||||||||||||||||||||0|||||||||||', '2016-12-14 00:00:15'),
(38, 4, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 00:02:21'),
(39, 3, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'A valid referenced transaction ID is required.', 0, '3|2|33|A valid referenced transaction ID is required.||P|0|3||11.75|CC|prior_auth_capture|7|||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6|||||||||||||||||||||||||||||||', '2016-12-14 00:03:46'),
(40, 3, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'A valid referenced transaction ID is required.', 0, '3|2|33|A valid referenced transaction ID is required.||P|0|3||11.75|CC|prior_auth_capture|7|||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6|||||||||||||||||||||||||||||||', '2016-12-14 00:03:48'),
(41, 3, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'A valid referenced transaction ID is required.', 0, '3|2|33|A valid referenced transaction ID is required.||P|0|3||11.75|CC|prior_auth_capture|7|||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6|||||||||||||||||||||||||||||||', '2016-12-14 00:03:54'),
(42, 4, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 00:04:56'),
(43, 4, 'AUTH_ONLY', 1038.00, 1, 'This transaction has been approved.', 60012513891, '1|1|1|This transaction has been approved.|901WC7|Y|60012513891|4||1038.00|CC|auth_only|24|asdfasd|asdfasdfasd||asdfasdfasdf|asdfasdfasdf|AL|12345||||||||||||||||||24C016E5BB845F5ED14F7D64059689F3|P|2|||||||||||XXXX1111|Visa|||||||||||||||||', '2016-12-14 00:07:16'),
(44, 14, 'AUTH_ONLY', 19.80, 1, 'This transaction has been approved.', 60012514033, '1|1|1|This transaction has been approved.|WBXGST|Y|60012514033|14||19.80|CC|auth_only|25|kyle|rio||asdfasdfasdfasdfasdfasdfasdf|asdfasdfasdfasdf|AL|65432||||||||||||||||||28B7BDED05C354E8F4539405BB963924|P|2|||||||||||XXXX8888|Visa|||||||||||||||||', '2016-12-14 00:14:14'),
(45, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:14:52'),
(46, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:17:42'),
(47, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:17:45'),
(48, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:34:27'),
(49, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:34:35'),
(50, 14, 'AUTH_ONLY', 19.80, 3, 'Credit card number is required.', 0, '3|2|33|Credit card number is required.||P|0|14||19.80|CC|auth_only|25|||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1|||||||||||||||||||||||||||||||', '2016-12-14 00:37:31'),
(51, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:45:11'),
(52, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:49'),
(53, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:51'),
(54, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:52'),
(55, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:54'),
(56, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:55'),
(57, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:56:56'),
(58, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 00:57:33'),
(59, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:05:39'),
(60, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:05:43'),
(61, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:32:28'),
(62, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:32:42'),
(63, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:32:44'),
(64, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||19.80|CC|prior_auth_capture||||||||||||||||||||||||||7E0E901FBF6A411A3D244CB11FF934F1||||||||||||||||||||0|||||||||||', '2016-12-14 01:33:28'),
(65, 2, 'PRIOR_AUTH_CAPTURE', 52.56, 3, 'A valid referenced transaction ID is required.', 0, '3|2|33|A valid referenced transaction ID is required.||P|0|2||52.56|CC|prior_auth_capture|5|||||||||||||||||||||||||5D299DBD27ADC789AA8449F415609D55|||||||||||||||||||||||||||||||', '2016-12-14 01:36:56'),
(66, 3, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'A valid referenced transaction ID is required.', 0, '3|2|33|A valid referenced transaction ID is required.||P|0|3||11.75|CC|prior_auth_capture|7|||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6|||||||||||||||||||||||||||||||', '2016-12-14 01:37:04'),
(67, 5, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 01:37:17'),
(68, 8, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 01:37:42'),
(69, 14, 'PRIOR_AUTH_CAPTURE', 19.80, 1, 'This transaction has already been captured.', 0, '1|1|311|This transaction has already been captured.||P|0|14||19.80|CC|prior_auth_capture|25|||||||||||||||||||||||||264353A1DBD345E573A19814673D1A5D||||||||||||||Visa|||||||||||||||||', '2016-12-14 01:44:56'),
(70, 13, 'PRIOR_AUTH_CAPTURE', 15.00, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||15.00|CC|prior_auth_capture||||||||||||||||||||||||||96ACA0000AD49B410D3FD12F4B793125||||||||||||||||||||0|||||||||||', '2016-12-14 01:50:42'),
(71, 13, 'PRIOR_AUTH_CAPTURE', 15.00, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||15.00|CC|prior_auth_capture||||||||||||||||||||||||||96ACA0000AD49B410D3FD12F4B793125||||||||||||||||||||0|||||||||||', '2016-12-14 01:51:22'),
(72, 12, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 01:51:27'),
(73, 7, 'PRIOR_AUTH_CAPTURE', 11.75, 3, 'The transaction cannot be found.', 0, '3|2|16|The transaction cannot be found.||P|0|||11.75|CC|prior_auth_capture||||||||||||||||||||||||||9A48A673BC590F3528D9373D9CC5BDF6||||||||||||||||||||0|||||||||||', '2016-12-14 01:51:32'),
(74, 7, 'PRIOR_AUTH_CAPTURE', 11.75, 1, 'This transaction has been approved.', 60012396112, '1|1|1|This transaction has been approved.|L4IYQG|P|60012396112|7||11.75|CC|prior_auth_capture|11|||||||22222||||||||||||||||||8CAEAAA6030070F6718FAD9A140365F8|||||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 01:53:32'),
(75, 10, 'PRIOR_AUTH_CAPTURE', 11.75, 1, 'This transaction has been approved.', 60012512952, '1|1|1|This transaction has been approved.|5EGBMG|P|60012512952|10||11.75|CC|prior_auth_capture|18|||||||11333||||||||||||||||||5DB81181A708D34000DE03B5B9BDFEFA|||||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 01:53:37'),
(76, 12, 'PRIOR_AUTH_CAPTURE', 11.75, 1, 'This transaction has been approved.', 60012513547, '1|1|1|This transaction has been approved.|H95JVO|P|60012513547|12||11.75|CC|prior_auth_capture|22|||||||12345||||||||||||||||||D7345CA0228CDD2F5CB28137D9A81544|||||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 01:58:50'),
(77, 15, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012516596, '1|1|1|This transaction has been approved.|5NDOWG|Y|60012516596|15||11.75|CC|auth_only|26|kyle|kyleeee||kyleeeeeee|kyleeeee|AL|46321||||||||||||||||||0C525BA8EED7A27B5867F612C9EB096C|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 02:01:21'),
(78, 15, 'PRIOR_AUTH_CAPTURE', 11.75, 1, 'This transaction has been approved.', 60012516596, '1|1|1|This transaction has been approved.|5NDOWG|P|60012516596|15||11.75|CC|prior_auth_capture|26|||||||46321||||||||||||||||||0C525BA8EED7A27B5867F612C9EB096C|||||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 02:01:58'),
(79, 16, 'AUTH_ONLY', 11.75, 1, 'This transaction has been approved.', 60012518421, '1|1|1|This transaction has been approved.|2L6W2Q|Y|60012518421|16||11.75|CC|auth_only|30|aaaaa|aaaaaa||asdfasdfasdf|asdfasdfasdf|LA|11333||||||||||||||||||011AFC750A0E4A7AF18E7B412C4C2756|P|2|||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 03:20:34'),
(80, 16, 'PRIOR_AUTH_CAPTURE', 11.75, 1, 'This transaction has been approved.', 60012518421, '1|1|1|This transaction has been approved.|2L6W2Q|P|60012518421|16||11.75|CC|prior_auth_capture|30|||||||11333||||||||||||||||||011AFC750A0E4A7AF18E7B412C4C2756|||||||||||||XXXX0002|American Express|||||||||||||||||', '2016-12-14 03:22:07');

-- --------------------------------------------------------

--
-- Table structure for table `wish_lists`
--

CREATE TABLE IF NOT EXISTS `wish_lists` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `quantity` tinyint(3) unsigned NOT NULL,
  `user_session_id` char(32) NOT NULL,
  `product_type` enum('coffee','other','sale') DEFAULT NULL,
  `product_id` mediumint(8) unsigned NOT NULL,
  `date_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_modified` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `product_type` (`product_type`,`product_id`),
  KEY `user_session_id` (`user_session_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=3 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
