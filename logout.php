<?php
//destroy session

require('./config.inc.php');

$_SESSION = array();
session_destroy();

redirect_invalid_user();

include('./includes/header.html');

echo '<h3>You are now logged out.</h3>';

include('./includes/footer.html');
?>
