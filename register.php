<?php session_start(); ?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Register - HiPet</title>
    <link rel="stylesheet" href="../assets/style_auth.css">
</head>
<body>
    <!-- Logo di pojok kiri atas -->
    <div class="logo-header">
        <img src="../assets/logo2.png" alt="HiPet Logo">
        <span>HiPet!</span>
    </div>

    <div class="auth-container">
        <h2>📝 Daftar Akun</h2>
        <form action="../actions/register_process.php" method="POST" class="auth-form">
            <label>Username</label>
            <input type="text" name="username" required placeholder="Masukkan username">

            <label>Nama Lengkap</label>
            <input type="text" name="full_name" required placeholder="Masukkan nama lengkap">

            <label>Email</label>
            <input type="email" name="email" required placeholder="Masukkan email aktif">

            <label>Password</label>
            <input type="password" name="password" required placeholder="Masukkan password">

            <label>No. Telepon</label>
            <input type="text" name="phone" placeholder="Contoh: 081234567890">

            <label>Alamat</label>
            <textarea name="address" rows="3" placeholder="Alamat lengkap..."></textarea>

            <button type="submit">Daftar</button>
            <p>Sudah punya akun? <a href="login.php">Login di sini</a></p>
        </form>
    </div>
</body>
</html>