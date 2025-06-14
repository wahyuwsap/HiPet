<h1>🐾 HiPet! – Sistem Booking Grooming Hewan</h1>

<h2>Deskripsi Umum Sistem</h2>
HiPet! merupakan aplikasi berbasis web yang dikembangkan untuk memfasilitasi proses pemesanan layanan grooming hewan peliharaan secara efisien dan terintegrasi. Sistem ini dibangun menggunakan bahasa pemrograman PHP, HTML, dan CSS dengan basis data MySQL, dan memanfaatkan fitur-fitur pemrosesan data tingkat lanjut seperti stored procedure, trigger, transaction, dan stored function.

Penggunaan fitur-fitur ini ditujukan untuk memastikan bahwa seluruh proses bisnis yang terjadi di dalam sistem memiliki konsistensi, keandalan, dan integritas data, terutama dalam konteks sistem multi-user atau terdistribusi.

![Screenshot 2025-06-13 232852](https://github.com/user-attachments/assets/94b49ce8-9855-4eaa-a78a-98057eb8ef36)
![Screenshot 2025-06-13 232917](https://github.com/user-attachments/assets/5f2130ee-8782-4bf0-beb3-b31fb45677c2)
![Screenshot 2025-06-13 232925](https://github.com/user-attachments/assets/00d0dba4-6f01-4827-8b59-16cd3e92ebda)


<h2>Komponen Utama</h2>

<h2>Stored Procedure</h2>  
Stored procedure dalam sistem HiPet! bertindak sebagai alur otomatisasi operasi penting yang disimpan di dalam database. Dengan begitu, sistem dapat menjamin konsistensi data, efisiensi proses, dan keamanan integritas informasi, bahkan saat digunakan oleh banyak pengguna secara bersamaan.

![Screenshot 2025-06-14 111913](https://github.com/user-attachments/assets/7b02979c-a5d6-4489-98c6-a12629de4c04)

Beberapa Procedure yang kami gunakan adalah:

**1. CreateBooking**  
Membuat data booking baru, mengecek ketersediaan jadwal, menghitung harga layanan, mengupdate kapasitas, dan mencatat histori booking.  
```
// Call the CreateBooking stored procedure
$stmt = $conn->prepare("CALL CreateBooking(?, ?, ?, ?, ?, ?, @p_booking_id, @p_result)");
$stmt->execute([
    $userId,
    $petId,
    $serviceId,
    $scheduleId,
    $appointmentDatetime,
    $notes
]);  

// Get output result
$result = $conn->query("SELECT @p_booking_id AS booking_id, @p_result AS result")->fetch();
```  

**2. CreateDatabaseBackup**  
Membuat salinan data penting (backup) dari beberapa tabel utama secara otomatis.
```
// Call the CreateDatabaseBackup stored procedure
$stmt = $conn->prepare("CALL CreateDatabaseBackup(?)");
$stmt->execute([$backupName]);
```

**3. GetAvailableSchedules**  
Mengambil daftar jadwal yang tersedia berdasarkan layanan dan tanggal.  
```
// Call the GetAvailableSchedules stored procedure
$stmt = $conn->prepare("CALL GetAvailableSchedules(?, ?)");
$stmt->execute([$serviceId, $date]);
```

**4. UpdateBookingStatus**  
Mengubah status booking, mengupdate kapasitas jadwal jika dibatalkan, dan mencatat histori perubahan status.  
```
// Call the UpdateBookingStatus stored procedure
$stmt = $conn->prepare("CALL UpdateBookingStatus(?, ?, ?, ?, ?)");
$stmt->execute([
    $bookingId,
    $newStatus,
    $changedByType, // 'user' atau 'admin'
    $changedById,
    $reason
]);
```

Dengan menyimpan logic ini langsung di dalam database, sistem HiPet! dapat menjaga integritas transaksi meskipun terjadi error di aplikasi. Semua perubahan krusial terjadi dalam satu transaksi atomik, memastikan sistem tetap reliable dan robust.  
___  

<h2>Trigger</h2>

![Screenshot 2025-06-14 122921](https://github.com/user-attachments/assets/553cbe29-76ce-41cb-9f8e-304ecae05666)

Trigger pada sistem HiPet! berfungsi sebagai pengaman otomatis yang aktif ketika terjadi aksi tertentu pada tabel—baik sebelum (BEFORE) maupun sesudah (AFTER) peristiwa seperti INSERT, UPDATE, atau DELETE. Seperti palang pintu digital, trigger memastikan hanya data yang valid dan sesuai aturan yang diizinkan masuk atau keluar.

Trigger
Beberapa trigger berikut berperan krusial dalam menjaga integritas dan konsistensi sistem HiPet!:  

**1. tr_auto_create_payment**  
Aktif Saat: AFTER UPDATE pada tabel bookings  
Fungsi: Secara otomatis membuat data pembayaran jika status booking berubah menjadi confirmed.  
```
-- Otomatis membuat pembayaran ketika booking dikonfirmasi
IF OLD.status != 'confirmed' AND NEW.status = 'confirmed' THEN
    INSERT INTO payments (booking_id, amount, payment_method, status)
    VALUES (NEW.booking_id, NEW.total_price, 'cash', 'pending');
END IF;
```

**2. tr_booking_status_update**  
Aktif Saat: BEFORE UPDATE pada tabel bookings  
Fungsi:  
Memperbarui kolom updated_at setiap kali status booking berubah, dan secara otomatis:  
1. Menandai payment_status = 'paid' jika booking selesai.
2. Menandai payment_status = 'refunded' jika dibatalkan dan sudah dibayar.
```
-- Update waktu dan status pembayaran otomatis saat status booking berubah
IF OLD.status != NEW.status THEN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
    
    IF NEW.status = 'completed' AND NEW.payment_status = 'unpaid' THEN
        SET NEW.payment_status = 'paid';
    ELSEIF NEW.status = 'cancelled' AND NEW.payment_status = 'paid' THEN
        SET NEW.payment_status = 'refunded';
    END IF;
END IF;
```

**3. tr_update_schedule_on_delete**   
Aktif Saat: AFTER DELETE pada tabel bookings   
Fungsi: Setelah booking dihapus, kapasitas jadwal (schedule) dikurangi otomatis agar kembali tersedia.  
```
-- Kembalikan slot jadwal jika booking dihapus
UPDATE schedules 
SET current_bookings = current_bookings - 1 
WHERE schedule_id = OLD.schedule_id;
```


**Catatan**   
Walaupun tidak ada trigger eksplisit bernama validate_transaction dalam sistem ini seperti pada template perbankan, fungsi-fungsi validasi dilakukan melalui:   
1. Stored Procedure (CreateBooking) → Mengecek ketersediaan jadwal, validasi kapasitas, dan harga layanan.
2. Trigger → Menjaga integritas data booking, pembayaran, dan jadwal.
3. Dengan sistem trigger yang ditanam langsung di database, HiPet! menjamin bahwa validasi dan automasi tetap berjalan meskipun terjadi bug atau kelalaian dari sisi aplikasi.



<h2>Transaction</h2>
Setiap proses penting seperti pembuatan pemesanan (booking) dan perubahan status pemesanan dilakukan secara atomik menggunakan mekanisme transaksi (transaction). Tujuannya adalah untuk menjamin konsistensi dan integritas data, terutama dalam kondisi multi-user atau jika terjadi gangguan saat eksekusi. Fitur transaction diimplementasikan dengan kombinasi antara perintah START TRANSACTION, COMMIT, ROLLBACK, serta dukungan stored procedure di sisi database MySQL.

Untuk itu, digunakan prosedur tersimpan (stored procedure) bernama CreateBooking yang dibungkus dalam satu transaksi. Implementasi PHP yang memanggil prosedur tersebut:
```
try {
$conn->beginTransaction();
$stmt = $conn->prepare("CALL CreateBooking(?, ?, ?, ?, ?, ?, @booking_id, @result)");
$stmt->execute([$user_id, $pet_id, $service_id, $schedule_id, $datetime, $notes]);
$conn->commit();
} catch (PDOException $e) {
$conn->rollBack();
// Penanganan error
}
```
Dengan implementasi ini, sistem memastikan bahwa proses booking hanya berhasil jika semua langkah dijalankan dengan sukses. Jika salah satu gagal (misalnya kapasitas jadwal penuh), maka semua perubahan akan dibatalkan.

Perubahan status pemesanan (misalnya dari 'confirmed' menjadi 'cancelled') memiliki konsekuensi penting, seperti:
1. Menyesuaikan kapasitas jadwal.
2. Mencatat riwayat perubahan (audit trail).
3. Mencegah pembatalan ganda.
Untuk itu, digunakan stored procedure UpdateBookingStatus yang berisi transaksi SQL seperti berikut:
```
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
START TRANSACTION;
-- Ambil data lama
-- Update status booking
-- Update jadwal jika dibatalkan
-- Simpan histori perubahan
COMMIT;
END;
```


<h2>Stored Function</h2>  
Stored function dalam sistem HiPet! digunakan untuk mengambil data tanpa mengubah isi database. Ibaratnya seperti layar monitor: hanya menampilkan informasi penting, bukan mengubahnya.  

![Screenshot 2025-06-14 113912](https://github.com/user-attachments/assets/244a44e2-4a30-46b2-94f6-463950023580)  

Dengan stored function, logika pengambilan data tertentu menjadi konsisten dan terpusat, baik saat digunakan oleh aplikasi maupun oleh stored procedure lain. Beberapa Function yang kami gunakan adalah:  

**1. GetTotalRevenue(start_date, end_date)**  
Mengembalikan total pemasukan dari semua booking yang telah selesai dan dibayar, dalam rentang tanggal tertentu.  

```
Contoh penggunaan di aplikasi (PHP):  
$stmt = $conn->prepare("SELECT GetTotalRevenue(?, ?) AS revenue");
$stmt->execute([$startDate, $endDate]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);  

Contoh penggunaan di procedure atau query:  
SELECT GetTotalRevenue('2025-06-01', '2025-06-10');
```

**2. GetUserBookingCount(p_user_id, p_status)**  
Mengembalikan jumlah booking user berdasarkan status tertentu (misalnya: pending, completed, dll). Jika p_status bernilai NULL, maka akan dihitung semua status.  
```
Contoh penggunaan:
$stmt = $conn->prepare("SELECT GetUserBookingCount(?, ?) AS booking_count");
$stmt->execute([$userId, 'completed']);  

Di database:
SELECT GetUserBookingCount(2, 'completed');
```

**3. IsScheduleAvailable(p_schedule_id)**  
Memeriksa apakah suatu jadwal masih tersedia untuk booking. Mengembalikan nilai TRUE atau FALSE.  
```
Contoh penggunaan:
$stmt = $conn->prepare("SELECT IsScheduleAvailable(?) AS available");
$stmt->execute([$scheduleId]);

Dalam procedure CreateBooking:
IF v_is_active = TRUE AND v_current_bookings < v_max_capacity THEN
    SET is_available = TRUE;
END IF;
```

_Manfaat Penggunaan Stored Function_
1. Pusat logika bisnis baca-tulis: tidak perlu mengulang kode di tiap tempat.
2. Konsistensi antar sistem: baik aplikasi maupun procedure mengacu pada fungsi yang sama.
3. Cocok untuk sistem terdistribusi: logika tidak bergantung pada client, semua dikontrol oleh database layer.

<h2>Backup</h2>   
Sistem dilengkapi dengan fitur backup otomatis yang dijalankan secara terjadwal menggunakan task scheduler. Backup dilakukan menggunakan utilitas mysqldump, dan disimpan ke direktori storage/backups/.

```
<?php
$host = 'localhost';
$user = 'root';
$pass = ''; // Jika ada password isi di sini
$db   = 'hipet_db';

$filename = "backup_{$db}_" . date('Ymd_His') . ".sql";
$backup_path = __DIR__ . "/../backups/$filename";

// Buat folder jika belum ada
if (!is_dir(dirname($backup_path))) {
    mkdir(dirname($backup_path), 0777, true);
}

// Path lengkap ke mysqldump di Laragon
$mysqldump = "D:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqldump.exe";

// Bangun perintah backup
$command = "\"$mysqldump\" -h $host -u $user $db > \"$backup_path\"";

exec($command, $output, $result);

if ($result === 0) {
    echo "✅ Backup berhasil: <a href='../backups/$filename' download>Download Backup</a>";
} else {
    echo "❌ Gagal backup. Periksa path mysqldump dan hak akses folder.";
}
?>
```

<h2>Relevansi dengan Pemrosesan Data Terdistribusi</h2> 
HiPet! dirancang untuk memenuhi prinsip-prinsip dasar Pemrosesan Data Terdistribusi:   

1. **Konsistensi**  
   Dicapai melalui penggunaan prosedur dan fungsi terpusat di dalam basis data.

2. **Reliabilitas**  
   Sistem tetap dapat menjaga integritas data meskipun terdapat gangguan di sisi aplikasi.

3. **Integritas**  
   Dengan adanya trigger dan validasi di level database, sistem tetap aman dari manipulasi data yang tidak sah.
 
