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
               <title> Paint - Contact Page </title>
		<h2> Contact Us!</h2>
		<p align = "left"> If you would like to contact us, please enter your name, email, and message below! </p>
		<?php
		if (!isset($_POST['getInfo']))
		{		
		?>
		<form method="POST">
			Name: <input type="text" name ="name"><br/>
			Email: <input type="text" name = "email"></br>
			Message: <br/><textarea rows="50" name = "message"></textarea></br>
			Would you like to view what you entered? <input type="checkbox" name="getInfo" value="yes"> Yes, view what I entered<br>
			<input type="submit" value="Submit">
		</form>
		<?php
		}else
		{	
			if($_SERVER['REQUEST_METHOD'] =='POST')
			{
				$n = $_POST['name'];
				$e = $_POST['email'];
				$_SESSION['email'] = $e;
				$m = $_POST['message'];
				if (isset($_POST['getInfo']))
				{
					$yes = $_POST['getInfo'];
				}

				if($e == null || $n == null || $m == null)
				{
			  		echo "Missing field(s) in contact form.";
					include('./includes/footer.html');
			  		exit();
				}

				if(get_magic_quotes_gpc())
		   		{
					$e = stripslashes($e);
					$n = stripslashes($n);
					$m = stripslashes($m);
		   	 	}

				if (preg_match ('/^[A-Z \'.-]{2,80}$/i', $_POST['name'])) {
					$n = addslashes($_POST['name']);
				} else {
					$contact_errors['name'] = 'Please enter your name!';
				}
				if (preg_match ('/^[A-Z \'.-]{2,1000}$/i', $_POST['email'])) {
					$e = addslashes($_POST['email']);
				} else {
					$contact_errors['email'] = 'Please enter your name!';
				}
				if (filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
					$e = $_POST['email'];
					$_SESSION['email'] = $_POST['email'];
				} else {
				$contact_errors['email'] = 'Please enter a valid email address!';
				}
				if (strpos($e, '@') === false)
				{
					echo "You need to enter a valid email.";
					include('./includes/footer.html');
					exit();
				}
		
				$q1 = mysqli_query($dbc, "CALL add_contact('$n', '$e', '$m', @id)");
				if (mysqli_affected_rows($dbc) == 1)
				{
					echo "You have successfully submitted a message";
					
				}
				else
				{
					echo "Message not submitted.";
				}
				$row = mysqli_fetch_array(mysqli_query($dbc, "SELECT name, email, message FROM contact WHERE email ='$e'"));
			
			$name = $row["name"];
			$email = $row["email"];
			$message = $row["message"];
			}
				
		?>
		
			<form method="POST">
			Name: <input type="text" name ="name" value = "<?php echo $name;?>"><br/>
			Email: <input type="text" name = "email" value = "<?php echo $email;?>"></br>
			Message: <br/><textarea rows="50" name = "message"><?php echo $message;?></textarea></br>
			Would you like to view what you entered? <input type="checkbox" name="getInfo" value="yes"> Yes, view what I entered<br>
			<input type="submit" value="Submit">
		</form>
		<?php 
		}
		?>
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
	if($_SERVER['REQUEST_METHOD'] =='POST')
	{
		$n = $_POST['name'];
		$e = $_POST['email'];
		$m = $_POST['message'];
		if (isset($_POST['getInfo']))
		{
			$yes = $_POST['getInfo'];
		}
			if($e == null || $n == null || $m == null)
		{
	  		echo "Missing field(s) in contact form.";
			include('./includes/footer.html');
	  		exit();
		}
			if(get_magic_quotes_gpc())
   		{
			$e = stripslashes($e);
			$n = stripslashes($n);
			$m = stripslashes($m);
   	 	}
			if (preg_match ('/^[A-Z \'.-]{2,80}$/i', $_POST['name'])) {
			$n = addslashes($_POST['name']);
			} else {
				$contact_errors['name'] = 'Please enter your name!';
			}
			if (preg_match ('/^[A-Z \'.-]{2,1000}$/i', $_POST['email'])) {
				$e = addslashes($_POST['email']);
			} else {
				$contact_errors['email'] = 'Please enter your name!';
			}
			if (filter_var($_POST['email'], FILTER_VALIDATE_EMAIL)) {
				$e = $_POST['email'];
				$_SESSION['email'] = $_POST['email'];
			} else {
			$contact_errors['email'] = 'Please enter a valid email address!';
			}
			if (strpos($e, '@') === false)
			{
				echo "You need to enter a valid email.";
				include('./includes/footer.html');
				exit();
			}
	
			$q3 = mysqli_query($dbc, "CALL add_contact('$n', '$e', '$m', @id)");
			if (mysqli_affected_rows($dbc) == 1)
			{
				echo "You have successfully submitted a message";
				include ('./includes/footer.html');
				exit();
			}
			else
			{
				echo "Message not submitted.";
			}
	}

	exit();
// Include the footer file:
include ('./includes/footer.html');
?>
