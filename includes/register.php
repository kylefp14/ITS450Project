<?php

require('./includes/config.inc.php');
include('./includes/header.html');
require(MYSQL);

if($_SERVER['REQUEST_METHOD'] =='POST')
{
	$fn = $_POST['first_name'];
	$ln = $_POST['last_name'];
	$e = $_POST['email'];
	$u = $_POST['username'];
	$p = $_POST['pass1'];
	$q = "SELECT * FROM users WHERE email='$e' OR username='$u'";
	$r = mysqli_query($dbc,$q);
	$rows = mysqli_num_rows($r);
	if ($rows== 0)
	{
		$q1 = "INSERT INTO users (username, email, pass, first_name, last_name, date_expires) VALUES ('$u', '$e','" . get_password_hash($p) . "' , '$fn', '$ln', NOW() )";
		$r1 = mysqli_query($dbc,$q1);
		if (mysqli_affected_rows($dbc) == 1)
		{
			echo "User created";
			include('./includes/footer.html');
			exit();
		}
		else
		{
			echo "error";
		}
	}
}

?>

<h3> Register </h3>
<form action="register.php" method = "post">
First Name <br/> <input type="text" name="first_name"/><br/>
Last Name <br/> <input type="text" name="last_name"/><br/>
User Name <br/> <input type="text" name="username"/><br/>
Email <br/> <input type="text" name="email"/><br/>
Password <br/> <input type="password" name="pass1"/><br/>
Confirm Password <br/> <input type="password" name="pass2"/><br/>
<br/>
<input type="submit" name="submit_button" id="submit_button"/>
</form>

<?php

include('./includes/footer.html');

?>
