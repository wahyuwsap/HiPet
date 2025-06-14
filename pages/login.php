<?php session_start(); ?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Login - HiPet</title>
    <link rel="stylesheet" href="../assets/style_auth.css">
</head>
<body>
    <!-- Logo di pojok kiri atas -->
    <div class="logo-header" >
        <img src="../assets/logo2.png" alt="HiPet Logo" >
        <span>HiPet!</span>
    </div>

    <div class="auth-container">
        <h2>🔐 Login</h2>
        <form action="../actions/login_process.php" method="POST" class="auth-form">
            <label>Email</label>
            <input type="email" name="email" required placeholder="Masukkan email">

            <label>Password</label>
            <input type="password" name="password" required placeholder="Masukkan password">

            <button type="submit">Login</button>
            <p>Belum punya akun? <a href="register.php">Daftar di sini</a></p>
        </form>
    </div>
</body>
</html>
