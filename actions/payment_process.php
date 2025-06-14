<?php
session_start();
include '../config/db.php';

if (!isset($_SESSION['user'])) {
    die("Unauthorized access.");
}

$booking_id = $_POST['booking_id'] ?? 0;
$amount     = $_POST['amount'] ?? 0;
$method     = $_POST['method'] ?? 'cash';
$user_id    = $_SESSION['user']['user_id'];

// Validasi booking
$check = $conn->prepare("SELECT status, payment_status FROM bookings WHERE booking_id = ? AND user_id = ?");
$check->bind_param("ii", $booking_id, $user_id);
$check->execute();
$res = $check->get_result();

if ($res->num_rows === 0) {
    die("Booking tidak valid atau bukan milik Anda.");
}

$data = $res->fetch_assoc();
if ($data['payment_status'] === 'paid') {
    header("Location: ../pages/payment_list.php?msg=Sudah dibayar");
    exit;
}

// Insert ke payments
$stmt = $conn->prepare("INSERT INTO payments (booking_id, amount, payment_method, status) VALUES (?, ?, ?, 'success')");
$stmt->bind_param("ids", $booking_id, $amount, $method);
$stmt->execute();

// Update status pembayaran
$conn->query("UPDATE bookings SET payment_status = 'paid' WHERE booking_id = $booking_id");

header("Location: ../pages/dashboard_user.php?message=Pembayaran berhasil");
exit;
?>
