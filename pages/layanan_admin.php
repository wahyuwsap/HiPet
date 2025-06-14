<?php
session_start();
if (!isset($_SESSION['user']) || $_SESSION['role'] !== 'admin') {
    die("Unauthorized access.");
}
include '../config/db.php';

$bookings = $conn->query("SELECT * FROM v_booking_summary ORDER BY appointment_datetime DESC");

// proses delete booking
if (isset($_GET['delete'])) {
    $id = intval($_GET['delete']);
    $conn->query("DELETE FROM bookings WHERE booking_id = $id");
    header("Location: dashboard_admin.php");
    exit;
}

// proses update status booking + notifikasi
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_booking_id'])) {
    $booking_id = intval($_POST['update_booking_id']);
    $new_status = $_POST['status'];
    $admin_id = $_SESSION['user']['user_id'];
    $reason = trim($_POST['reason'] ?? '');

    // jalankan prosedur update status
    $stmt = $conn->prepare("CALL UpdateBookingStatus(?, ?, 'admin', ?, ?)");
    $stmt->bind_param("isis", $booking_id, $new_status, $admin_id, $reason);
    $stmt->execute();
    $conn->next_result(); // penting!

    // ambil user_id dari bookings
    $result = $conn->query("SELECT user_id FROM bookings WHERE booking_id = $booking_id");
    if ($result && $result->num_rows > 0) {
        $user_id = $result->fetch_assoc()['user_id'];

        // buat isi pesan
        $message = "Booking #$booking_id diubah menjadi '$new_status'.";
        if (!empty($reason)) {
            $message .= " Catatan: $reason";
        }

        // simpan ke tabel notifikasi
        $notif = $conn->prepare("INSERT INTO notifications (user_id, message) VALUES (?, ?)");
        $notif->bind_param("is", $user_id, $message);
        if (!$notif->execute()) {
            echo "Gagal simpan notifikasi: " . $conn->error;
        }
    }

    header("Location: dashboard_admin.php");
    exit;
}


// proses CRUD schedule
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add_schedule') {
    $service_id = $_POST['service_id'];
    $available_date = $_POST['available_date'];
    $start_time = $_POST['start_time'];
    $end_time = $_POST['end_time'];
    $max_capacity = $_POST['max_capacity'];

    $stmt = $conn->prepare("INSERT INTO schedules (service_id, available_date, start_time, end_time, max_capacity) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("isssi", $service_id, $available_date, $start_time, $end_time, $max_capacity);
    $stmt->execute();
    header("Location: dashboard_admin.php");
    exit;
}

if (isset($_GET['delete_schedule'])) {
    $id = intval($_GET['delete_schedule']);
    $conn->query("DELETE FROM schedules WHERE schedule_id = $id");
    header("Location: dashboard_admin.php");
    exit;
}

// Ambil daftar service & jadwal
$all_services = $conn->query("SELECT * FROM services");
$schedules = $conn->query("SELECT s.*, sv.service_name FROM schedules s JOIN services sv ON s.service_id = sv.service_id ORDER BY available_date, start_time");
?>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="../assets/style.css">
</head>
<body>
<header>
    <div style="display: flex; align-items: center;">
        <img src="../assets/logo2.png" alt="HiPet Logo" style="height: 40px; margin-right: 10px;">
        <span style="font-weight: bold; font-size: 1.2em;color: #00ffff;">HiPet!</span>
    </div>
    <nav style="display: flex; gap: 20px; align-items: center;">
        <a href="dashboard_admin.php" style="font-weight: bold; color: #00ffff;">Dashboard</a>
        <a href="layanan_admin.php" style="font-weight: bold; color: #00ffff;">Jadwal Layanan</a>
        <a href="../logout.php" class="logout">Logout</a>
    </nav>
</header>


<div class="container">
    <div class="card2">
    <h2 style="text-align: center;">📆 Jadwal Layanan</h2>

    <h3 style="text-align: center;">➕ Tambah Jadwal Baru</h3>
    <form method="POST">
        <input type="hidden" name="action" value="add_schedule">
        <label>Layanan</label>
        <select name="service_id" required>
            <?php while ($svc = $all_services->fetch_assoc()): ?>
                <option value="<?= $svc['service_id'] ?>"><?= $svc['service_name'] ?></option>
            <?php endwhile; ?>
        </select>
        <label>Tanggal</label>
        <input type="date" name="available_date" required>
        <label>Jam Mulai</label>
        <input type="time" name="start_time" required>
        <label>Jam Selesai</label>
        <input type="time" name="end_time" required>
        <label>Kuota Maksimal</label>
        <input type="number" name="max_capacity" required>
        <button type="submit">Tambah Jadwal</button>
    </form>
</div>

    
</div>
</body>
</html>
