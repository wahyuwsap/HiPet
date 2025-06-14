<?php
session_start();
include '../config/db.php';

if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit;
}

$user_id = $_SESSION['user']['user_id'];
$username = $_SESSION['user']['username'];

// Ambil daftar booking yang belum dibayar
$unpaid = $conn->query("
    SELECT b.booking_id, b.appointment_datetime, b.total_price, b.status,
           p.pet_name, s.service_name
    FROM bookings b
    JOIN pets p ON b.pet_id = p.pet_id
    JOIN services s ON b.service_id = s.service_id
    WHERE b.user_id = $user_id AND b.payment_status = 'unpaid'
    ORDER BY b.appointment_datetime DESC
");
?>

<!DOCTYPE html>
<html>
<head>
    <title>HiPet - Pembayaran</title>
    <link rel="stylesheet" href="../assets/style.css">
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
    <h2>Pembayaran Booking</h2>

    <?php if ($unpaid->num_rows === 0): ?>
        <p>Tidak ada booking yang perlu dibayar.</p>
    <?php else: ?>
        <table>
            <thead>
                <tr>
                    <th>ID Booking</th>
                    <th>Peliharaan</th>
                    <th>Layanan</th>
                    <th>Waktu</th>
                    <th>Total</th>
                    <th>Aksi</th>
                </tr>
            </thead>
            <tbody>
                <?php while ($b = $unpaid->fetch_assoc()): ?>
                    <tr>
                        <td><?= $b['booking_id'] ?></td>
                        <td><?= htmlspecialchars($b['pet_name']) ?></td>
                        <td><?= htmlspecialchars($b['service_name']) ?></td>
                        <td><?= date('d M Y H:i', strtotime($b['appointment_datetime'])) ?></td>
                        <td>Rp<?= number_format($b['total_price'], 0, ',', '.') ?></td>
                        <td>
                            <form method="POST" action="../actions/payment_process.php">
                                <input type="hidden" name="booking_id" value="<?= $b['booking_id'] ?>">
                                <input type="hidden" name="amount" value="<?= $b['total_price'] ?>">
                                <select name="method" required>
                                    <option value="cash">Cash</option>
                                    <option value="transfer">Transfer</option>
                                    <option value="card">Kartu</option>
                                    <option value="ewallet">E-Wallet</option>
                                </select>
                                <button type="submit">💵 Bayar</button>
                            </form>
                        </td>
                    </tr>
                <?php endwhile; ?>
            </tbody>
        </table>
    <?php endif; ?>
</div>

</body>
</html>
