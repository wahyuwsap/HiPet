<?php
include '../config/db.php';

$user_id = $_POST['user_id'];
$pet_name = $_POST['pet_name'];
$service_id = $_POST['service_id'];
$schedule_id = $_POST['schedule_id'];
$datetime = $_POST['datetime'];
$notes = $_POST['notes'];

// Cek apakah pet sudah ada
$res = $conn->query("SELECT pet_id FROM pets WHERE user_id = $user_id AND pet_name = '$pet_name'");
if ($res->num_rows > 0) {
    $pet = $res->fetch_assoc();
    $pet_id = $pet['pet_id'];
} else {
    // Tambahkan pet baru
    $conn->query("INSERT INTO pets (user_id, pet_name, pet_type) VALUES ($user_id, '$pet_name', 'other')");
    $pet_id = $conn->insert_id;
}

// Call procedure
$stmt = $conn->prepare("CALL CreateBooking(?, ?, ?, ?, ?, ?, @booking_id, @result)");
$stmt->bind_param("iiiiss", $user_id, $pet_id, $service_id, $schedule_id, $datetime, $notes);
$stmt->execute();

$result = $conn->query("SELECT @booking_id AS booking_id, @result AS result");
$data = $result->fetch_assoc();
$message = $data['result'] ?? 'ERROR: Unknown result';


// Redirect jika sukses
if (str_starts_with($message, 'SUCCESS')) {
    header("Location: ../pages/dashboard_user.php?message=" . urlencode($message));
    exit;
} else {
    // Tampilkan pesan error jika gagal
    echo "<p>$message</p>";
    echo "<a href='../pages/booking_form.php'>Kembali</a>";
}
?>
