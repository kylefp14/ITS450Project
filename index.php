<?php

// This file is the home page. 
// This script is begun in Chapter 8.

// Require the configuration before any PHP code:
require ('./config.inc.php');

// Include the header file:
$page_title = 'Paint - Wouldn\'t You Love a Gallon Right Now?';
include ('./includes/header.html');

// Require the database connection:
require (MYSQL);
if($_SERVER['REQUEST_METHOD']=='POST')
{
  include('./login.inc.php');
}

// Invoke the stored procedure:
$r = mysqli_query ($dbc, "CALL select_sale_items(false)");

// Include the view:
include('./views/home.html');

// Include the footer file:
include ('./includes/footer.html');
?>
