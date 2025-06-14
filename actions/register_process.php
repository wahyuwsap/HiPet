<?php
include '../config/db.php';

$username = $_POST['username'];
$full_name = $_POST['full_name'];
$email = $_POST['email'];
$password = password_hash($_POST['password'], PASSWORD_BCRYPT);
$phone = $_POST['phone'];
$address = $_POST['address'];

$stmt = $conn->prepare("INSERT INTO users (username, email, password, full_name, phone, address) VALUES (?, ?, ?, ?, ?, ?)");
$stmt->bind_param("ssssss", $username, $email, $password, $full_name, $phone, $address);

if ($stmt->execute()) {
    // Redirect ke halaman login setelah sukses daftar
    header("Location: ../pages/login.php");
    exit;
} else {
    echo "Gagal mendaftar.";
}
?>
