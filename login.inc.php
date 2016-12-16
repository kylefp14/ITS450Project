<?php
function get_password_hash($password){

	$password = crypt($password, "420");
	return $password;
}

$error = "";

$e = $_POST['email'];
$p = $_POST['password'];

$q = "SELECT id, first_name, type FROM customers WHERE (email='$e' AND password ='" . get_password_hash($p) . "')";

$r = mysqli_query($dbc, $q);

if (mysqli_num_rows($r) == 1) //a match has been found
{
	$row = mysqli_fetch_array($r, MYSQLI_NUM);
	$_SESSION['user_id'] = $row[0];
	$_SESSION['first_name'] = $row[1];
	$_SESSION['email'] = $e;
}
else
{
	echo"no match";
}
?>
