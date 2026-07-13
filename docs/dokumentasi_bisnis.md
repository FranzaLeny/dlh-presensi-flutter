# Dokumentasi Proses Bisnis & Panduan Penggunaan - Aplikasi Presensi DLH

Dokumen ini menjelaskan secara rinci alur kerja dan proses bisnis dari Aplikasi Presensi DLH berbasis seluler. Panduan ini dirancang agar pengguna dapat memahami dan mengoperasikan aplikasi dengan mudah tanpa kebingungan.

## Pengenalan Aplikasi
Aplikasi Presensi DLH adalah sistem pencatatan kehadiran digital yang dirancang khusus untuk memudahkan pegawai dalam mencatat jam masuk, jam pulang, serta memantau rekapitulasi kehadiran dan pengajuan absen secara *real-time* langsung dari ponsel.

## Unduh & Instalasi
- **Link Download (Google Drive):** [Unduh Aplikasi Presensi DLH](https://drive.google.com/drive/folders/1C1JlytzFO1GdVkcjUsRP4MO92x_EclEU?usp=sharing)

**PENTING: Panduan Memilih Versi Aplikasi (ARM64 vs ARMEABI)**
Di dalam folder Google Drive tersebut, mungkin terdapat beberapa file APK dengan nama berbeda. Pastikan Anda mengunduh versi yang tepat untuk tipe HP Anda agar aplikasi dapat diinstal:
1. **Versi `arm64-v8a` (ARM64):** Silakan unduh versi ini. Ini adalah versi 64-bit yang dikhususkan untuk **mayoritas HP Android modern masa kini** (keluaran tahun 2016 ke atas seperti seri Samsung, Oppo, Vivo, Xiaomi terbaru). Kinerjanya jauh lebih cepat dan stabil.
2. **Versi `armeabi-v7a` (ARM32 / ARM):** Unduh versi ini **hanya jika** HP Anda gagal menginstal versi ARM64. Versi 32-bit ini ditujukan untuk **HP Android keluaran lama** atau HP *entry-level* (kelas sangat bawah) versi lawas.

- **Cara Instalasi:** 
  Karena aplikasi belum diunggah ke Google Play Store, Anda perlu menginstalnya secara manual (sideload APK):
  1. Unduh file APK (pilih ARM64 terlebih dahulu) dari link Google Drive di atas.
  2. Buka file APK yang sudah diunduh.
  3. Jika muncul peringatan keamanan dari Android, izinkan **"Install from Unknown Sources"** (Instal dari sumber tidak dikenal) melalui Pengaturan perangkat Anda.
  4. Jika muncul peringatan dari **Google Play Protect**, abaikan pemblokiran tersebut dengan menekan **"More details"** (Detail selengkapnya) lalu pilih **"Install anyway"** (Tetap instal).

## Persyaratan Perangkat
- **Android:** Aplikasi ini dapat berjalan di perangkat Android (tidak ada batasan minimum versi OS secara khusus).
- **iOS / iPhone:** Saat ini, pengguna iPhone belum didukung dan tidak dapat menggunakan aplikasi ini.

---

## 1. Alur Autentikasi (Login, Lupa Password & Sesi)

**Tujuan:** Memastikan hanya pegawai yang terdaftar dan sah yang dapat mengakses sistem presensi.

### A. Melakukan Login
1. Saat pertama kali membuka aplikasi, pengguna akan disajikan halaman **Login**.
2. Pengguna wajib memasukkan **Email** yang terdaftar dan **Password**.
3. Saat tombol "Masuk" ditekan, aplikasi akan melakukan validasi ke server (akan muncul indikator *loading*).
4. Jika login berhasil, aplikasi akan melakukan sinkronisasi data awal. Jika gagal karena server gangguan atau kredensial salah, akan muncul pesan peringatan.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/01_login_halaman_awal.png" height="300" alt="Halaman Awal">
  <img src="screenshoot/02_login_form_terisi.png" height="300" alt="Form Terisi">
  <img src="screenshoot/03_login_loading.png" height="300" alt="Loading">
  <img src="screenshoot/04_login_berhasil_sinkronisasi.png" height="300" alt="Sinkronisasi Berhasil">
  <img src="screenshoot/07_login_gagal_server_gangguan.png" height="300" alt="Server Gangguan">
</div>

### B. Lupa Password
Jika pengguna melupakan password:
1. Tekan tombol "Lupa Password" di halaman login.
2. Masukkan alamat email yang terdaftar.
3. Sistem akan mengirimkan kode OTP ke email tersebut.
4. Masukkan kode OTP dan buat password baru. Setelah itu, pengguna dapat login kembali dengan password baru.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/05_lupa_password_form_kosong.png" height="300" alt="Form Lupa Password">
  <img src="screenshoot/06_lupa_password_loading.png" height="300" alt="Loading Lupa Password">
  <img src="screenshoot/08_lupa_password_form_otp.png" height="300" alt="Form OTP">
  <img src="screenshoot/09_lupa_password_form_terisi.png" height="300" alt="Password Baru">
  <img src="screenshoot/10_login_setelah_reset_password.png" height="300" alt="Login Pasca Reset">
</div>

---

## 2. Alur Presensi Kehadiran Harian (Masuk & Pulang)

**Tujuan:** Mencatat waktu dan lokasi kehadiran pegawai secara valid, *real-time*, dan mencegah manipulasi.

### A. Izin Akses Perangkat
Sebelum dapat melakukan presensi, aplikasi membutuhkan izin dari perangkat:
1. **Izin Kamera**: Digunakan untuk mengambil foto *selfie* sebagai bukti fisik kehadiran.
2. **Izin Lokasi (GPS)**: Digunakan untuk memvalidasi posisi pegawai apakah berada di dalam zona kantor (Geofence). Lokasi harus diatur ke tingkat akurasi tinggi (Location Accuracy).

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/11_presensi_izin_kamera.png" height="300" alt="Izin Kamera">
  <img src="screenshoot/12_presensi_izin_lokasi.png" height="300" alt="Izin Lokasi">
  <img src="screenshoot/13_presensi_location_accuracy.png" height="300" alt="Location Accuracy">
</div>

### B. Melakukan Presensi
1. Di halaman beranda, sistem akan menampilkan jarak pegawai ke titik kantor.
2. Jika posisi pegawai berada di luar area yang diizinkan, akan muncul peringatan teks merah "Lokasi terdeteksi diluar area kantor".
3. Tekan ikon **Sidik Jari** berwarna biru muda di bagian bawah tengah layar.
4. **Syarat Foto Selfie:** Pegawai **wajib mengambil foto selfie HANYA JIKA presensi dilakukan di luar area kantor**. Jika lokasi berada di dalam radius, presensi dapat langsung disubmit tanpa perlu foto. (Jika diminta foto, kamera depan akan terbuka otomatis untuk mengambil foto wajah).
5. Akan muncul dialog konfirmasi. Jika lokasi berada di luar area, konfirmasi juga akan mengingatkan hal tersebut.
6. Setelah konfirmasi, sistem akan mengirim data ke server. Notifikasi hijau (berhasil) akan muncul di bawah layar, dan status di beranda akan berubah dari "Menunggu Persetujuan" menjadi "Disetujui" (jika di dalam area) atau "WFA" (jika diizinkan dari luar area).

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/14_presensi_halaman_utama_pulang_luar_area.png" height="300" alt="Presensi Luar Area">
  <img src="screenshoot/15_presensi_kamera_selfie.png" height="300" alt="Kamera Selfie">
  <img src="screenshoot/16_presensi_konfirmasi_luar_area.png" height="300" alt="Konfirmasi Presensi">
</div>

---

## 3. Riwayat & Rekapitulasi Kehadiran

**Tujuan:** Memudahkan pegawai memantau daftar presensi harian dan rekap bulanan mereka sendiri.

1. **Riwayat Harian**: Dengan menekan tab riwayat (ikon jam terbalik), pegawai dapat melihat jam presensi Masuk dan Pulang hari ini, beserta status sinkronisasinya (contoh: *Synced*).
2. **Rekap Bulanan**: Dengan menekan tab kalender, pegawai dapat melihat rekap kehadiran dalam sebulan. Tanggal kalender ditandai dengan warna (Hijau = Lengkap, Merah muda = Tidak Lengkap, dll).
3. **Detail per Tanggal**: Jika pegawai menekan salah satu tanggal di kalender, detail jam masuk dan pulang pada hari tersebut akan muncul di bawah kalender.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/19_riwayat_presensi_list.png" height="300" alt="Riwayat Harian">
  <img src="screenshoot/17_rekap_presensi_bulanan.png" height="300" alt="Rekap Bulanan">
  <img src="screenshoot/18_rekap_detail_presensi_tanggal.png" height="300" alt="Detail Kehadiran">
</div>

---

## 4. Alur Pengajuan Absen (Cuti, Sakit, Tugas Luar)

**Tujuan:** Memfasilitasi pegawai yang berhalangan hadir secara fisik di kantor.

1. Pengguna masuk ke menu **Daftar Absen** (tab kalender berlogo tanda silang).
2. Jika belum ada pengajuan, layar akan tampak kosong. Jika sudah ada, akan tampil daftar riwayat pengajuan beserta statusnya (contoh: *Disetujui*).
3. Di halaman ini juga terdapat daftar hari libur nasional dan cuti bersama di bagian bawah layar.
4. Untuk mengajukan absen baru, tekan tombol **+ Ajukan** di sudut kanan atas.
5. *(Catatan: Form pengajuan absen belum dilampirkan dalam screenshot dokumentasi ini, pengguna diharapkan melengkapi form, mengunggah foto dokumen, dan mensubmit data)*. 

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/20_absen_daftar_kosong.png" height="300" alt="Daftar Absen Kosong">
  <img src="screenshoot/21_absen_daftar_berisi.png" height="300" alt="Daftar Absen Terisi">
  <img src="screenshoot/22_absen_hari_libur_cuti_bersama.png" height="300" alt="Daftar Hari Libur">
</div>

---

## 5. Profil Pegawai & Pengaturan Zona

**Tujuan:** Memastikan data diri pegawai sesuai dan menginformasikan titik presensi yang valid bagi pegawai tersebut.

1. Pada menu Profil (ikon orang di pojok kanan bawah), pengguna dapat melihat **Data Kepegawaian** (NIP, Jabatan, OPD, Unit Kerja). 
2. Jika ada perubahan data di server, pengguna dapat menyegarkan layar, dan notifikasi sinkronisasi sukses akan muncul.
3. Di bagian **Informasi & Zona Presensi**, pegawai dapat melihat jam kerja resmi dan lokasi/radius presensi (Geofence) yang ditetapkan untuk mereka.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/23_profil_data_kepegawaian.png" height="300" alt="Data Kepegawaian">
  <img src="screenshoot/24_profil_data_kepegawaian_synced.png" height="300" alt="Data Tersinkron">
  <img src="screenshoot/25_profil_info_zona_presensi.png" height="300" alt="Zona Presensi">
</div>

---

## 6. Keamanan Akun & Perangkat

**Tujuan:** Memberikan kendali kepada pengguna atas keamanan akun mereka, termasuk penggantian kata sandi dan manajemen perangkat yang terhubung.

Di halaman Profil, terdapat tombol **Keamanan Akun** yang berisi menu:
- **Ubah Password**: Form untuk memasukkan kata sandi lama dan kata sandi baru.
- **Ubah Email**: Form untuk mengubah alamat email. Sistem akan mengirimkan OTP ke email baru sebelum perubahan disimpan.
- **Sesi Aktif**: Menampilkan sesi login yang sedang berlangsung.
- **Perangkat Tertaut**: Menampilkan daftar HP/perangkat yang terhubung dengan akun ini. Pengguna dapat menghapus (logout jarak jauh) perangkat yang tidak dikenali demi keamanan.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/26_keamanan_akun_menu.png" height="300" alt="Menu Keamanan">
  <img src="screenshoot/27_keamanan_ubah_password_form.png" height="300" alt="Ubah Password">
</div>

**Proses Ubah Email:**
<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/28_keamanan_ubah_email_form_kosong.png" height="300" alt="Ubah Email Kosong">
  <img src="screenshoot/29_keamanan_ubah_email_form_terisi.png" height="300" alt="Ubah Email Terisi">
  <img src="screenshoot/30_keamanan_ubah_email_otp.png" height="300" alt="OTP Email">
  <img src="screenshoot/32_keamanan_ubah_email_otp_kirim.png" height="300" alt="Kirim OTP">
  <img src="screenshoot/31_keamanan_ubah_email_berhasil.png" height="300" alt="Email Berhasil">
</div>

**Manajemen Sesi & Perangkat:**
<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/34_keamanan_sesi_aktif.png" height="300" alt="Sesi Aktif">
  <img src="screenshoot/35_keamanan_perangkat_tertaut_list.png" height="300" alt="Perangkat Tertaut">
  <img src="screenshoot/36_keamanan_perangkat_hapus_konfirmasi.png" height="300" alt="Konfirmasi Hapus Perangkat">
  <img src="screenshoot/37_keamanan_perangkat_berhasil_dihapus.png" height="300" alt="Perangkat Dihapus">
</div>

---

## 7. Sinkronisasi Data (Offline ke Online)

**Tujuan:** Menjaga agar data aplikasi selalu *up-to-date* dengan server pusat dan mencegah data hilang saat tidak ada sinyal.

Jika terjadi perubahan data besar, atau pegawai baru saja kembali dari area tanpa sinyal, mereka dapat masuk ke menu **Sinkronisasi Data**. Terdapat tombol sinkronisasi mandiri untuk menyelaraskan:
1. **Profil**: Menyinkronkan data diri terbaru.
2. **Pengaturan Zona**: Menyinkronkan perubahan titik kordinat kantor/jam kerja.
3. **Data Absen**: Menyinkronkan status pengajuan cuti/sakit terbaru.
4. **Hari Libur**: Mengunduh kalender libur nasional terbaru.

Notifikasi hijau akan muncul setelah setiap proses sinkronisasi berhasil diselesaikan.

<div style="display: flex; gap: 10px; overflow-x: auto;">
  <img src="screenshoot/38_sinkronisasi_menu.png" height="300" alt="Menu Sinkronisasi">
  <img src="screenshoot/39_sinkronisasi_profil_berhasil.png" height="300" alt="Sync Profil">
  <img src="screenshoot/40_sinkronisasi_zona_berhasil.png" height="300" alt="Sync Zona">
  <img src="screenshoot/41_sinkronisasi_absen_berhasil.png" height="300" alt="Sync Absen">
  <img src="screenshoot/42_sinkronisasi_hari_libur_berhasil.png" height="300" alt="Sync Hari Libur">
</div>

---

## 8. Keluar dari Aplikasi (Logout)

Jika pengguna ingin mengganti akun atau mengakhiri sesi secara permanen di perangkat, mereka dapat menekan tombol **Keluar** (berwarna merah) di bagian bawah halaman profil. Akan muncul dialog konfirmasi sebelum aplikasi mengeluarkan sesi pengguna.

<img src="screenshoot/43_logout_konfirmasi.png" height="300" alt="Logout Konfirmasi">

---

## 9. Aturan Perhitungan Jam Kerja & Verifikasi

Untuk memastikan kedisiplinan, sistem menerapkan perhitungan jam kerja aktual sebagai berikut:
- **Alpa (Tidak Presensi):** Dihitung 0 (nol) jam kerja.
- **Presensi Tidak Lengkap (Hanya masuk/lupa pulang atau sebaliknya):** Dihitung 0 (nol) jam kerja. Pegawai wajib melengkapi siklus presensi (Masuk dan Pulang) dalam hari tersebut agar kehadirannya sah.
- **Cuti, Sakit, atau Tugas Luar:** Jika pengajuan telah disetujui, maka jam kerja pada hari tersebut akan dihitung otomatis memenuhi target jam kerja harian penuh.

**Verifikasi Presensi:**
Segala bentuk presensi dari luar area (WFA) maupun pengajuan Daftar Absen wajib diverifikasi dan disetujui oleh Atasan atau Admin agar diakui oleh sistem.

---

## 10. Akses Dashboard Admin

Bagi pihak manajemen (Admin), pengelolaan presensi, verifikasi absen, dan laporan tidak dilakukan melalui aplikasi seluler, melainkan melalui **Dashboard Web**.
Silakan akses tautan berikut untuk masuk ke dashboard pengurus:
👉 **[demo.lembata.site](http://demo.lembata.site)**
