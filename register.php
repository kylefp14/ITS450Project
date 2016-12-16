<?php

require('./includes/config.inc.php');
include('./includes/header.html');
require(MYSQL);

if($_SERVER['REQUEST_METHOD'] =='POST')
{
	$e = $_POST['email'];
	$fn = $_POST['first_name'];
	$ln = $_POST['last_name'];
	$pass = $_POST['pass1'];
	$pass2 = $_POST['pass2'];
	$a1 = $_POST['address1'];
	$a2 = $_POST['address2'];
	$c = $_POST['city'];
	$s = $_POST['state'];
	$z = $_POST['zip'];
	$p = $_POST['phone'];
	$q = "SELECT * FROM customers WHERE email='$e' OR first_name='$fn'";
	$r = mysqli_query($dbc,$q);
	$rows = mysqli_num_rows($r);

	if($e == null || $fn == null || $ln == null || $pass == null || $a1 == null || $c == null || $s == null || $z == null || $p == null)
	{
	  echo "Missing field(s) in user registration.";
	  exit();
	}

	 if(get_magic_quotes_gpc())
   	 {
    	  $email = stripslashes($email);
     	  $first_name = stripslashes($first_name);
     	  $last_name = stripslashes($last_name);
     	  $pass1 = stripslashes($pass1);
     	  $pass2 = stripslashes($pass2);
     	  $address1 = stripslashes($address1);
     	  $address2 = stripslashes($address2);
     	  $city = stripslashes($city);
     	  $state = stripslashes($state);
     	  $zip = stripslashes($zip);
     	  $phone = stripslashes($phone);
   	 }

	function get_password_hash($password)
	{
  	  $password = crypt($password, "420");
  	  return $password;
	}

	if ($rows== 0)
	{
		$q1 = "INSERT INTO customers (email, first_name, last_name, password, address1, address2, city, state, zip, phone) VALUES ('$e', '$fn', '$ln', '" .get_password_hash($pass)."' , '$a1', '$a2', '$c', '$s', '$z', '$p')";
		$r1 = mysqli_query($dbc,$q1);
		if (mysqli_affected_rows($dbc) == 1)
		{
			echo "User created.";
			include('./includes/footer.html');
			exit();
		}
		else
		{
			echo "User not created.";
		}
	}
} 
 


?>

<h3> Register </h3>
<form action="register.php" method = "post">
Email <br/> <input type="text" name="email"/><br/>
First Name <br/> <input type="text" name="first_name"/><br/>
Last Name <br/> <input type="text" name="last_name"/><br/>
Password <br/> <input type="password" name="pass1"/><br/>
Confirm Password <br/> <input type="password" name="pass2"/><br/>
Address 1 <br/> <input type="text" name="address1"/><br/>
Address 2 (Optional) <br/> <input type="text" name="address2"/><br/>
City <br/> <input type="text" name="city"/><br/>
State <br/> <input type="text" name="state"/><br/>
Zip <br/> <input type="text" name="zip"/><br/>
Phone <br/> <input type="text" name="phone"/><br/>
<br/>
<input type="submit" name="submit_button" id="submit_button"/>
</form>

<?php

include('./includes/footer.html');

?>
