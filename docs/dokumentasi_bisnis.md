# Dokumentasi Proses Bisnis - Aplikasi Presensi DLH

Dokumen ini menjelaskan alur kerja dan proses bisnis (SOP) dari Aplikasi Presensi DLH berbasis seluler.

## 1. Alur Autentikasi (Login & Sesi)
**Tujuan:** Memastikan hanya pegawai terdaftar yang dapat masuk dan menggunakan aplikasi.
- **Proses:**
  1. Pengguna membuka aplikasi dan disajikan layar Login.
  2. Pengguna memasukkan **Email** dan **Password**.
  3. Aplikasi mengirim data ke server (API) untuk validasi.
  4. Jika berhasil, server mengembalikan data profil pegawai beserta token akses. Aplikasi menyimpan data ini secara lokal menggunakan enkripsi (*secure storage*).
  5. Pengguna diarahkan ke **Beranda (Home Screen)**.

> *[Tambahkan Screenshot Halaman Login di sini]*

## 2. Alur Presensi Kehadiran Harian (Masuk & Pulang)
**Tujuan:** Mencatat waktu dan lokasi kehadiran pegawai secara valid dan *real-time*.
- **Proses:**
  1. Di halaman utama, pengguna memilih menu **Presensi** (ikon sidik jari).
  2. Aplikasi akan mengaktifkan GPS untuk mengambil **titik koordinat lokasi (Latitude & Longitude)** pegawai.
  3. Aplikasi mengecek apakah titik koordinat tersebut berada dalam radius yang diizinkan (Geofencing) berdasarkan titik pusat kantor (SKPD).
  4. Pengguna mengambil foto *selfie* sebagai bukti fisik kehadiran.
  5. Pengguna menekan tombol **Presensi Masuk** atau **Presensi Pulang**.
  6. Data waktu (mengambil waktu dari server untuk menghindari manipulasi jam HP), lokasi, dan foto dikirim ke *backend*.
  7. Jika koneksi internet terputus, data akan disimpan sementara di database lokal HP (Offline Mode).

> *[Tambahkan Screenshot Halaman Presensi dan Kamera Selfie di sini]*

## 3. Alur Pengajuan Absen (Cuti, Sakit, Tugas Luar)
**Tujuan:** Memfasilitasi pegawai yang berhalangan hadir secara fisik di kantor.
- **Proses:**
  1. Pengguna masuk ke menu **Daftar Absen** dan menekan tombol **+ Ajukan**.
  2. Pengguna memilih jenis absen (Sakit, Cuti, atau Tugas Luar).
  3. Pengguna menentukan rentang tanggal (Mulai s/d Selesai).
  4. Pengguna mengunggah foto dokumen pendukung (Surat Dokter, Surat Tugas, dll) dari galeri atau kamera.
  5. Data diajukan ke atasan/admin melalui sistem. 
  6. Selama statusnya "Disetujui" (*Approved*), sistem presensi akan otomatis menganggap pegawai tersebut sah tidak melakukan absen harian di tanggal tersebut.

> *[Tambahkan Screenshot Form Pengajuan Absen di sini]*

## 4. Alur Sinkronisasi Data (Offline to Online)
**Tujuan:** Menjaga keutuhan data apabila pegawai melakukan presensi di wilayah susah sinyal (Blank Spot).
- **Proses:**
  1. Aplikasi mendeteksi setiap presensi yang hanya tersimpan di lokal (belum terkirim ke server).
  2. Ketika HP mendeteksi adanya jaringan internet yang stabil, **Sync Engine** akan berjalan di latar belakang (Background Process).
  3. Pengguna juga dapat menekan ikon **Refresh/Sinkronisasi** di pojok kanan atas layar Beranda atau Profil secara manual.
  4. Data yang berhasil terkirim akan ditandai dengan status "*Synced*" dan dihapus dari antrean tunda (*pending queue*).

## 5. Alur Pemantauan Rekapitulasi (Laporan Bulanan)
**Tujuan:** Transparansi jam kerja dan persentase kehadiran pegawai.
- **Proses:**
  1. Pengguna membuka menu **Rekap**.
  2. Terdapat kalender bulanan dengan indikator warna (Hijau = Hadir, Merah = Tidak Lengkap, Kuning = Sakit, dll).
  3. Sistem mengkalkulasi **Target Jam Kerja** (berdasarkan pengaturan jadwal dinas) dikurangi waktu istirahat.
  4. Sistem mengkalkulasi **Total Jam Kerja Aktual** dari jam presensi pulang dikurangi jam presensi masuk pegawai.
  5. Pengguna dapat melihat detail kehadiran per tanggal dengan menekan tanggal spesifik di kalender.

> *[Tambahkan Screenshot Halaman Rekap Bulanan di sini]*
