<?php

// This file is the home page. 
// This script is begun in Chapter 8.

// Require the configuration before any PHP code:
require ('./config.inc.php');

// Include the header file:
$page_title = 'Paint - Wouldn\'t You Love a Gallon Right Now?';
include ('./includes/header.html');
?>


<!-- box begin -->
<div class="box alt">
	<div class="left-top-corner">
   	<div class="right-top-corner">
      	<div class="border-top"></div>
      </div>
   </div>
   <div class="border-left">
   	<div class="border-right">
      	<div class="inner">
         	<div class="wrapper">
               <title> Paint - Sitemap </title>
		<h2> Sitemap </h2>
			<p><a href="/shop/paint/">Paint</a></p>
			<p><a href="/shop/goodies/">More Paint</a></li>
			<p><a href="/shop/sales/">Sales</a></li>
			<p><a href="/wishlist.php">Wish List</a></li>
			<p><a href="/cart.php">Cart</a></li>
         	</div>
         </div>
      </div>
   </div>
   <div class="left-bot-corner">
   	<div class="right-bot-corner">
      	<div class="border-bot"></div>
      </div>
   </div>
</div>
<!-- box end -->

<?php


// Include the footer file:
include ('./includes/footer.html');
?>
