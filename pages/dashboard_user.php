<?php
session_start();
include '../config/db.php'; // pastikan file koneksi ini ada

if (!isset($_SESSION['user'])) {
    header("Location: login.php");
    exit;
}

$user_id = $_SESSION['user']['user_id'];
$username = $_SESSION['user']['username'];

// Ambil Jadwal
$jadwal = mysqli_query($conn, "SELECT s.*, sv.service_name 
    FROM schedules s 
    JOIN services sv ON s.service_id = sv.service_id 
    WHERE s.is_available = 1 AND s.available_date >= CURDATE()
    ORDER BY s.available_date ASC LIMIT 5");

// Ambil Riwayat Booking
$riwayat = mysqli_query($conn, "SELECT b.*, p.pet_name, s.service_name 
    FROM bookings b 
    JOIN pets p ON b.pet_id = p.pet_id 
    JOIN services s ON b.service_id = s.service_id 
    WHERE b.user_id = $user_id 
    ORDER BY b.pet_id ASC");


// Ambil Notifikasi
$notif = mysqli_query($conn, "SELECT * FROM notifications WHERE user_id = $user_id ORDER BY created_at DESC");
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>HiPet - Dashboard</title>
    <link rel="stylesheet" href="../assets/style.css">
</head>
<body>

<header>
    <div style="display: flex; align-items: center;">
        <img src="../assets/logo2.png" alt="HiPet Logo" style="height: 40px; margin-right: 10px;">
        <span style="font-weight: bold; font-size: 1.2em;color: #00ffff;">HiPet!</span>
    </div>
    <nav style="display: flex; gap: 20px; align-items: center;">
        <a href="#" style="font-weight: bold; color: #00ffff;">Dashboard</a>
        <a href="payment_list.php" style="font-weight: bold; color: #00ffff;">Pembayaran</a>
        <a href="booking_form.php" style="font-weight: bold; color: #00ffff;">Booking</a>
        <a href="profile.php" style="font-weight: bold; color: #00ffff;">Profil</a>
        <a href="../logout.php" class="logout">Logout</a>
    </nav>
</header>

<main style="padding: 30px;">
    <h2 style="margin-bottom: 0; color: #00ffff;">Selamat datang, <?= htmlspecialchars($username) ?></h2>

    <div class="container">
        <!-- Jadwal -->
        <table>
            <tbody>
                <tr>
                    <td style="vertical-align: top; width: 70%;">
                        <div class="card">
                            <h3>📅 Jadwal Tersedia</h3>
                            <table>
                                <thead>
                                    <tr>
                                        <th>Tanggal</th>
                                        <th>Jam</th>
                                        <th>Layanan</th>
                                        <th>Slot</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php while ($row = mysqli_fetch_assoc($jadwal)): ?>
                                        <tr>
                                            <td><?= $row['available_date'] ?></td>
                                            <td><?= substr($row['start_time'], 0, 5) ?> - <?= substr($row['end_time'], 0, 5) ?></td>
                                            <td><?= $row['service_name'] ?></td>
                                            <td><?= $row['current_bookings'] ?>/<?= $row['max_capacity'] ?></td>
                                        </tr>
                                    <?php endwhile; ?>
                                </tbody>
                            </table>
                        </div>
                    </td>

                    <td rowspan="2" style="vertical-align: top; width: 30%;">
                        <div class="card">
                            <h3>🔔 Notifikasi</h3>
                            <ul class="notif-list">
                                <?php while ($n = mysqli_fetch_assoc($notif)): ?>
                                    <li class="notif-item">
                                        <div class="notif-content">
                                            <?= htmlspecialchars($n['message']) ?>
                                            <span class="notif-time"><?= date('d M Y H:i', strtotime($n['created_at'])) ?></span>
                                        </div>
                                    </li>
                                <?php endwhile; ?>
                            </ul>
                        </div>
                    </td>
                </tr>

                <tr>
                    <td style="vertical-align: top;">
                        <div class="card">
                            <h3>📋 Riwayat Booking</h3>
                            <table>
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Peliharaan</th>
                                        <th>Layanan</th>
                                        <th>Waktu</th>
                                        <th>Status</th>
                                        <th>Pembayaran</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php while ($r = mysqli_fetch_assoc($riwayat)): ?>
                                        <tr>
                                            <td><?= $r['booking_id'] ?></td>
                                            <td><?= htmlspecialchars($r['pet_name']) ?></td>
                                            <td><?= htmlspecialchars($r['service_name']) ?></td>
                                            <td><?= date('d M Y H:i', strtotime($r['appointment_datetime'])) ?></td>
                                            <td><?= ucfirst($r['status']) ?></td>
                                            <td>
                                                <?php if ($r['payment_status'] === 'paid'): ?>
                                                    <span style="color: green; font-weight: bold;">✔ Sudah dibayar</span>
                                                <?php else: ?>
                                                    <span style="color: red; font-weight: bold;">❌ Belum dibayar</span>
                                                <?php endif; ?>
                                            </td>
                                        </tr>
                                    <?php endwhile; ?>
                                </tbody>
                            </table>
                        </div>
                    </td>
                </tr>
            </tbody>
        </table>

    </div>
</main>

</body>
</html>
