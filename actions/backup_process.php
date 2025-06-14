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
