<?php
session_start();
include '../config/db.php';

$email = $_POST['email'];
$password = $_POST['password'];

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $data = $result->fetch_assoc();
    if (password_verify($password, $data['password'])) {
        $_SESSION['user'] = $data;
        $_SESSION['role'] = $data['role']; // 'admin' atau 'user'

        // Redirect berdasarkan role
        if ($data['role'] === 'admin') {
            header("Location: ../pages/dashboard_admin.php");
        } else {
            header("Location: ../pages/dashboard_user.php");
        }
        exit;
    }
}

echo "Login gagal: Email atau password salah.";
?>
