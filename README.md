**🐾 HiPet! – Sistem Booking Grooming Hewan**
___

_Deskripsi Umum Sistem_  
HiPet! merupakan aplikasi berbasis web yang dikembangkan untuk memfasilitasi proses pemesanan layanan grooming hewan peliharaan secara efisien dan terintegrasi. Sistem ini dibangun menggunakan bahasa pemrograman PHP, HTML, dan CSS dengan basis data MySQL, dan memanfaatkan fitur-fitur pemrosesan data tingkat lanjut seperti stored procedure, trigger, transaction, dan stored function.

Penggunaan fitur-fitur ini ditujukan untuk memastikan bahwa seluruh proses bisnis yang terjadi di dalam sistem memiliki konsistensi, keandalan, dan integritas data, terutama dalam konteks sistem multi-user atau terdistribusi.

![Screenshot 2025-06-13 232852](https://github.com/user-attachments/assets/94b49ce8-9855-4eaa-a78a-98057eb8ef36)
![Screenshot 2025-06-13 232917](https://github.com/user-attachments/assets/5f2130ee-8782-4bf0-beb3-b31fb45677c2)
![Screenshot 2025-06-13 232925](https://github.com/user-attachments/assets/00d0dba4-6f01-4827-8b59-16cd3e92ebda)

___

**Komponen Utama**
___

_Stored Procedure_  
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
