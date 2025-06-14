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
    try {
        $conn->query("DELETE FROM bookings WHERE booking_id = $id");
        header("Location: dashboard_admin.php?msg=deleted");
        exit;
    } catch (mysqli_sql_exception $e) {
        $errorMsg = urlencode("Gagal menghapus booking: " . $e->getMessage());
        header("Location: dashboard_admin.php?error=$errorMsg");
        exit;
    }
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

<?php if (isset($_GET['error'])): ?>
    <div style="color: red; font-weight: bold;"><?= htmlspecialchars($_GET['error']) ?></div>
<?php endif; ?>


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
        <form action="../actions/backup_process.php" method="POST">
            <button type="submit">🔄 Buat Backup</button>
        </form>

        <a href="dashboard_admin.php" style="font-weight: bold; color: #00ffff;">Dashboard</a>
        <a href="layanan_admin.php" style="font-weight: bold; color: #00ffff;">Jadwal Layanan</a>
        <a href="../logout.php" class="logout">Logout</a>
    </nav>
</header>


<div class="container">
    <div class="card" style="vertical-align: top; width: 70%;">
        <h2>📋 Booking List</h2>
        <div class="table-wrapper">
            <table class="booking-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Customer</th>
                        <th>Pet</th>
                        <th>Service</th>
                        <th>Time</th>
                        <th>Status</th>
                        <th>Payment</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php while ($row = $bookings->fetch_assoc()): ?>
                    <tr>
                        <td><span class="id-badge"><?= $row['booking_id'] ?></span></td>
                        <td class="customer-cell">
                            <strong><?= htmlspecialchars($row['customer_name']) ?></strong>
                        </td>
                        <td class="pet-cell">
                            <div class="pet-info">
                                <span class="pet-name"><?= htmlspecialchars($row['pet_name']) ?></span>
                                <span class="pet-type">(<?= $row['pet_type'] ?>)</span>
                            </div>
                        </td>
                        <td class="service-cell"><?= htmlspecialchars($row['service_name']) ?></td>
                        <td class="time-cell"><?= $row['appointment_datetime'] ?></td>
                        <td>
                            <span class="status-badge status-<?= $row['status'] ?>">
                                <?= ucfirst($row['status']) ?>
                            </span>
                        </td>
                        <td>
                            <span class="payment-badge payment-<?= $row['payment_status'] ?>">
                                <?= ucfirst($row['payment_status']) ?>
                            </span>
                        </td>
                        <td class="actions-cell">
                            <div class="action-form">
                                <form method="POST" class="update-form">
                                    <input type="hidden" name="update_booking_id" value="<?= $row['booking_id'] ?>">
                                    <div class="form-group">
                                        <select name="status" class="status-select">
                                            <option <?= $row['status'] === 'pending' ? 'selected' : '' ?>>pending</option>
                                            <option <?= $row['status'] === 'confirmed' ? 'selected' : '' ?>>confirmed</option>
                                            <option <?= $row['status'] === 'in_progress' ? 'selected' : '' ?>>in_progress</option>
                                            <option <?= $row['status'] === 'completed' ? 'selected' : '' ?>>completed</option>
                                            <option <?= $row['status'] === 'cancelled' ? 'selected' : '' ?>>cancelled</option>
                                        </select>
                                    </div>
                                    <div class="form-group">
                                        <input type="text" name="reason" placeholder="Reason (optional)" class="reason-input">
                                    </div>
                                    <div class="form-group">
                                        <button type="submit" class="update-btn">Update</button>
                                        <a href="?delete=<?= $row['booking_id'] ?>" class="delete-btn" onclick="return confirm('Delete booking?')">🗑️</a>
                                    </div>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <?php endwhile; ?>
                </tbody>
            </table>
        </div>
    </div>

    <div class="card schedule-card"style="vertical-align: top; width: 70%;margin-top: 40px;">
        <h3>📅 Daftar Jadwal</h3>
        <div class="table-wrapper" >
            <table class="schedule-table">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Service</th>
                        <th>Tanggal</th>
                        <th>Waktu</th>
                        <th>Kuota</th>
                        <th>Booked</th>
                        <th>Status</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    <?php while ($s = $schedules->fetch_assoc()): ?>
                    <tr>
                        <td><span class="id-badge"><?= $s['schedule_id'] ?></span></td>
                        <td class="service-cell"><?= $s['service_name'] ?></td>
                        <td class="date-cell"><?= $s['available_date'] ?></td>
                        <td class="time-cell"><?= $s['start_time'] ?> - <?= $s['end_time'] ?></td>
                        <td class="capacity-cell">
                            <span class="capacity-info"><?= $s['max_capacity'] ?></span>
                        </td>
                        <td class="booked-cell">
                            <span class="booked-count"><?= $s['current_bookings'] ?></span>
                        </td>
                        <td>
                            <span class="availability-badge <?= $s['is_available'] ? 'active' : 'inactive' ?>">
                                <?= $s['is_available'] ? 'Aktif' : 'Tidak Aktif' ?>
                            </span>
                        </td>
                        <td class="actions-cell">
                            <a href="?delete_schedule=<?= $s['schedule_id'] ?>" class="delete-btn" onclick="return confirm('Hapus jadwal ini?')">🗑️</a>
                        </td>
                    </tr>
                    <?php endwhile; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

    
</div>
</body>
</html>
