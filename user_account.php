<?php 
  require('./includes/config.inc.php');
  require(MYSQL);
  if($_SERVER['REQUEST_METHOD']=='POST'){
	include('./includes/login.inc.php');
  }
	include("./includes/header.html");
 ?>


<?php
  require("./includes/footer.html");
 ?>
