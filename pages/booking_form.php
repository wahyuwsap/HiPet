<?php
session_start();
if (!isset($_SESSION['user']) || $_SESSION['role'] !== 'user') {
    die("Unauthorized access.");
}
include '../config/db.php';

$user_id = $_SESSION['user']['user_id'];

// Ambil data layanan aktif
$services = $conn->query("SELECT service_id, service_name FROM services WHERE is_active = 1");

// Ambil data peliharaan user
$pets = $conn->query("SELECT pet_id, pet_name FROM pets WHERE user_id = $user_id");

// Ambil semua schedule yang tersedia
$schedules = $conn->query("
    SELECT s.schedule_id, s.available_date, s.start_time, s.end_time, sv.service_name 
    FROM schedules s
    JOIN services sv ON s.service_id = sv.service_id
    WHERE s.is_available = 1 AND s.current_bookings < s.max_capacity
");
?>
<!DOCTYPE html>
<html>
<head>
    <title>Booking Baru</title>
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
    <div class="card2">
        <h2 style="text-align: center;">🗓️ Layanan Pemesanan</h2>
        <h3 style="text-align: center;">+ Tambah Booking</h3>

        <form method="POST" action="../actions/booking_process.php">
            <input type="hidden" name="user_id" value="<?= $user_id ?>">

            <!-- Input Nama Peliharaan -->
            <label for="pet_name">Nama Peliharaan</label>
            <input type="text" name="pet_name" id="pet_name" placeholder="Contoh: Bubu" required>


            <!-- Pilih Layanan -->
            <label for="service_id">Layanan</label>
            <select name="service_id" id="service_id" required>
                <option value="">-- Pilih Layanan --</option>
                <?php while ($sv = $services->fetch_assoc()): ?>
                    <option value="<?= $sv['service_id'] ?>"><?= $sv['service_name'] ?></option>
                <?php endwhile; ?>
            </select>

            <!-- Pilih Jadwal -->
            <label for="schedule_id">Jadwal Tersedia</label>
            <select name="schedule_id" id="schedule_id" required>
                <option value="">-- Pilih Jadwal --</option>
                <?php while ($sch = $schedules->fetch_assoc()): ?>
                    <option value="<?= $sch['schedule_id'] ?>">
                        <?= htmlspecialchars($sch['service_name']) ?> - <?= $sch['available_date'] ?> (<?= $sch['start_time'] ?> - <?= $sch['end_time'] ?>)
                    </option>
                <?php endwhile; ?>
            </select>


            <!-- Pilih Tanggal & Waktu Janji -->
            <label for="datetime">Waktu Janji</label>
            <input type="datetime-local" name="datetime" id="datetime" required>

            <!-- Deskripsi / Catatan -->
            <label for="notes">Deskripsi / Catatan Tambahan</label>
            <textarea name="notes" id="notes" rows="3" placeholder="Catatan tambahan..."></textarea>

            <button type="submit">Kirim Booking</button>
        </form>
    </div>
</div>

</body>
</html>
