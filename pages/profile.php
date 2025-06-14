<?php
session_start();
include '../config/db.php';

if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit;
}

$user_id = $_SESSION['user']['user_id'];
$mode_edit = isset($_GET['edit']) && $_GET['edit'] == '1';

// Proses update profil
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $full_name = $_POST['full_name'] ?? '';
    $email     = $_POST['email'] ?? '';
    $phone     = $_POST['phone'] ?? '';
    $address   = $_POST['address'] ?? '';

    $stmt = $conn->prepare("UPDATE users SET full_name = ?, email = ?, phone = ?, address = ? WHERE user_id = ?");
    $stmt->bind_param("ssssi", $full_name, $email, $phone, $address, $user_id);
    $stmt->execute();

    header("Location: profile.php?success=1");
    exit;
}

// Ambil data user
$stmt = $conn->prepare("SELECT username, full_name, email, phone, address, role, created_at FROM users WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();
?>

<!DOCTYPE html>
<html>
<head>
    <title>HiPet - Profil Pengguna</title>
    <link rel="stylesheet" href="../assets/style.css">
    <style>
    table.profile-table {
        width: 100%;
        max-width: 600px;
        border-collapse: collapse;
        margin: 20px auto;
        font-family: Arial, sans-serif;
    }

    .profile-table td {
        padding: 8px 12px;
        vertical-align: top;
    }

    .profile-table td:first-child {
        font-weight: bold;
        width: 35%;
        white-space: nowrap;
    }

    .profile-table input[type="text"],
    .profile-table input[type="email"],
    .profile-table textarea {
        width: 100%;
        padding: 6px;
        box-sizing: border-box;
        font-family: inherit;
    }

    .profile-table textarea {
        resize: vertical;
    }

    .profile-actions {
        text-align: right;
        padding-top: 10px;
    }

    .profile-actions button,
    .profile-actions a button {
        padding: 8px 14px;
        font-size: 14px;
        margin-left: 6px;
        cursor: pointer;
    }

    .profile-actions a {
        text-decoration: none;
    }
</style>
</head>
<body>

<header>
    <div style="display: flex; align-items: center;">
        <img src="../assets/logo2.png" alt="HiPet Logo" style="height: 40px; margin-right: 10px;">
        <span style="font-weight: bold; font-size: 1.2em;color: #00ffff;">HiPet!</span>
    </div>
    <nav style="display: flex; gap: 20px; align-items: center;">
        <a href="dashboard_user.php" style="font-weight: bold; color: #00ffff;">Dashboard</a>
        <a href="payment_list.php" style="font-weight: bold; color: #00ffff;">Pembayaran</a>
        <a href="booking_form.php" style="font-weight: bold; color: #00ffff;">Booking</a>
        <a href="profile.php" style="font-weight: bold; color: #00ffff;">Profil</a>
        <a href="../logout.php" class="logout">Logout</a>
    </nav>
</header>

<div class="container">
    <div class="card2">
        <h2>👤 Profil Pengguna</h2>

        <?php if (isset($_GET['success'])): ?>
            <div style="color: green; font-weight: bold;">✅ Profil berhasil diperbarui.</div>
        <?php endif; ?>

        <form method="post" action="profile.php">
            <table class="profile-table">
                <tr>
                    <td>Nama Lengkap</td>
                    <td>
                        <input type="text" name="full_name" value="<?= htmlspecialchars($user['full_name']) ?>" <?= $mode_edit ? '' : 'disabled' ?> required>
                    </td>
                </tr>
                <tr>
                    <td>Email</td>
                    <td>
                        <input type="email" name="email" value="<?= htmlspecialchars($user['email']) ?>" <?= $mode_edit ? '' : 'disabled' ?> required>
                    </td>
                </tr>
                <tr>
                    <td>Telepon</td>
                    <td>
                        <input type="text" name="phone" value="<?= htmlspecialchars($user['phone']) ?>" <?= $mode_edit ? '' : 'disabled' ?>>
                    </td>
                </tr>
                <tr>
                    <td>Alamat</td>
                    <td>
                        <textarea name="address" rows="3" <?= $mode_edit ? '' : 'disabled' ?>><?= htmlspecialchars($user['address']) ?></textarea>
                    </td>
                </tr>
                <tr>
                    <td>Terdaftar Sejak</td>
                    <td><?= date('d M Y H:i', strtotime($user['created_at'])) ?></td>
                </tr>
                <tr>
                    <td colspan="2" class="profile-actions">
                        <?php if ($mode_edit): ?>
                            <button type="submit">💾 Simpan Perubahan</button>
                            <a href="profile.php"><button type="button">❌ Batal</button></a>
                        <?php else: ?>
                            <a href="profile.php?edit=1"><button type="button">✏ Edit Profil</button></a>
                        <?php endif; ?>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

</body>
</html>
