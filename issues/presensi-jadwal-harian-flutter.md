# Perencanaan Penyesuaian API: Jadwal Harian Fleksibel (Mobile App)

Berdasarkan pembaruan backend terkait fitur "Presensi Jadwal Harian Fleksibel", berikut adalah rencana penyesuaian yang perlu diimplementasikan pada aplikasi *Mobile* (Flutter).

## 1. Pembaruan Model Data
- **File Target**: `lib/data/models/pengaturan_presensi.dart`
- **Tugas**:
  - Tambahkan class model `JadwalHarian` (berisi field: `hari`, `jamMasuk`, `jamPulang`, `jamIstirahatMulai`, `jamIstirahatSelesai`, `isLibur`).
  - Tambahkan properti `List<JadwalHarian>? jadwalHarian` ke dalam class `PengaturanPresensi`.
  - Sesuaikan *factory* `fromJson` dan logika *parsing* untuk membaca array jadwal harian dari respons JSON.

## 2. Penyesuaian Schema Database Lokal
- **File Target**: `lib/data/local/database.dart`
- **Tugas**:
  - Karena SQLite tidak secara otomatis mendukung array dari JSON, ada dua pendekatan yang bisa diimplementasikan:
    1. **Tabel Baru**: Buat tabel `pengaturan_jadwal_harian` dan lakukan relasi ke tabel `pengaturan_presensi`.
    2. **Field JSON (Disarankan)**: Tambahkan satu kolom baru `jadwal_harian_json` (bertipe `TEXT`) di dalam tabel `pengaturan_presensi` untuk menyimpan hasil *serialize/encode* data array ke string JSON.
  - Tambahkan *migration* versi database (ubah konstanta `_dbVersion`). Karena saat ini masih mode *drop & create*, tabel cukup di-drop dan di-create ulang sesuai definisi baru.
  - Update method `fromRow` dan `toRow` di model `PengaturanPresensi` untuk menangani *encode* dan *decode* field jadwal harian.

## 3. Pembaruan Proses Sinkronisasi (Sync Engine)
- **File Target**: `lib/services/sync/sync_settings.dart` atau file sync pengaturan terkait.
- **Tugas**:
  - Pastikan tidak ada *error* saat membaca response baru yang mengandung field `jadwalHarian`. 
  - Pastikan list jadwal tersimpan rapi pada SQLite lokal setelah proses *fetch* pengaturan presensi berhasil.

## 4. Penyesuaian UI & Logika Presensi (Profil/Dashboard)
- **Tugas**:
  - Jika aplikasi menampilkan *Jam Kerja* atau target *Masuk/Pulang* pada UI Profil atau Dashboard, pastikan aplikasi mengecek hari saat ini (menggunakan `DateTime.now().weekday`).
  - Ambil jam masuk/pulang harian dari `jadwalHarian` (sesuai *index* hari ini: 0=Minggu, 6=Sabtu) alih-alih menampilkan nilai `jamMasuk` global, sehingga pengguna dapat melihat waktu kerja tepat untuk hari tersebut.
  - Jika `isLibur == 1`, berikan keterangan visual pada aplikasi bahwa hari tersebut adalah "Hari Libur" / tidak ada jadwal masuk kerja.

## 5. Sinkronisasi Logika Perhitungan Jam Kerja & Efektif
- **Tugas**:
  - Pastikan perhitungan `jamKerja` (aktual) dan `jamKerjaEfektif` (target) pada _mobile_ (seperti dalam `rekap_screen` atau report lokal) sejalan dengan fungsi `hitungJamKerjaHarian` di backend (`presensi-report.service.ts`).
  - **Algoritma `jamKerjaEfektif`**:
    - Hitung selisih dalam menit antara `jamPulang` dan `jamMasuk` harian.
    - Kurangi dengan durasi istirahat harian (selisih `jamIstirahatSelesai` - `jamIstirahatMulai`).
    - Jika hari tersebut diset sebagai hari libur (dari _override_ `jadwalHarian` atau libur nasional/weekend standar), maka `jamKerjaEfektif` harus **dianggap 0**.
  - **Algoritma `jamKerja` (Aktual)**:
    - Jika status `tugas` atau `cuti/sakit` di hari kerja, anggap `jamKerja` bernilai sama dengan `jamKerjaEfektif`.
    - Jika hadir, hitung selisih waktu _log_ pulang dan masuk.
    - Kurangi dengan durasi istirahat (menggunakan durasi istirahat aktual jika ada log mulai/selesai istirahat, atau jika tidak ada, gunakan durasi istirahat efektif **hanya jika** rentang kerja mencakup jam istirahat).
  - Terapkan perbaikan algoritma ini pada _helper_ fungsi waktu yang mungkin ada di `lib/core/utils/` atau logika pada UI rekap, sehingga kalkulasi di _mobile_ akurat 100% dengan backend.
