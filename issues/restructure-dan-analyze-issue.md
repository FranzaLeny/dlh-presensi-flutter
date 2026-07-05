# Issue: Restrukturisasi File & Dart Analyze

> **Prioritas**: Medium
> **Estimasi Waktu**: 4–6 jam
> **Tanggal Dibuat**: 2026-07-05

---

## 1. Latar Belakang

Beberapa file di project `presensi-dlh-flutter` memiliki ukuran yang terlalu besar
(ratusan hingga >1000 baris). Hal ini menyulitkan pembacaan, maintenance, dan review.
Dokumen ini menjadi panduan bagi **junior programmer** atau **model AI** untuk
memecah file-file tersebut menjadi unit yang lebih kecil, terfokus, dan mudah dikelola.

---

## 2. Hasil `dart analyze`

```
$ dart analyze lib
Analyzing lib...
No issues found!
```

**Status: ✅ Bersih — 0 issue.**
Pastikan setiap selesai refactor, jalankan kembali `dart analyze lib` dan hasilnya
tetap **"No issues found!"**.

---

## 3. Inventaris Ukuran File (Terbesar → Terkecil)

| # | Lines | KB | File |
|---|------:|---:|------|
| 1 | **1233** | 41.7 | `lib/presentation/screens/presensi/presensi_screen.dart` |
| 2 | **640** | 23.4 | `lib/presentation/screens/absen/absen_form_screen.dart` |
| 3 | **521** | 17.5 | `lib/presentation/screens/rekap/rekap_screen.dart` |
| 4 | **480** | 16.9 | `lib/presentation/screens/profil/profil_screen.dart` |
| 5 | **433** | 13.8 | `lib/presentation/screens/absen/absen_screen.dart` |
| 6 | **372** | 11.8 | `lib/services/sync_engine.dart` |
| 7 | **335** | 13.2 | `lib/presentation/screens/auth/login_screen.dart` |
| 8 | **309** | 12.3 | `lib/presentation/screens/riwayat/riwayat_screen.dart` |
| 9 | 256 | 8.3 | `lib/presentation/widgets/app_shell.dart` |
| 10 | 241 | 8.7 | `lib/presentation/widgets/timeline_widget.dart` |
| 11 | 232 | 7.1 | `lib/data/models/presensi_log.dart` |
| 12 | 218 | 7.9 | `lib/services/auth_service.dart` |
| 13 | 207 | 5.5 | `lib/data/local/presensi_dao.dart` |
| 14 | 191 | 5.3 | `lib/providers/providers.dart` |
| 15 | 179 | 5.0 | `lib/data/models/pegawai.dart` |
| 16 | 167 | 3.8 | `lib/data/models/sync_response.dart` |
| 17 | 162 | 6.1 | `lib/services/time_service.dart` |

> **Target**: Setiap file idealnya ≤ **300 baris**. File > 300 baris **wajib** dipecah.

---

## 4. Rencana Restrukturisasi Per File

### 4.1. `presensi_screen.dart` (1233 baris) — 🔴 Prioritas Tertinggi

File ini adalah yang terbesar dan paling kompleks. Berisi **business logic, kamera +
face detection, UI utama, dan modal overlay** dalam satu file.

#### Struktur Pemecahan:

```
lib/presentation/screens/presensi/
├── presensi_screen.dart              ← Main screen (state + build method ~200 baris)
├── widgets/
│   ├── presensi_time_card.dart       ← Widget card jam + tanggal (L577–L715)
│   ├── presensi_action_buttons.dart  ← Tombol absen + redo button (L783–L944)
│   ├── presensi_geofence_card.dart   ← Info lokasi geofence (L946–L1038)
│   ├── presensi_timeline_section.dart← Section timeline wrapper (L732–L769)
│   ├── presensi_camera_view.dart     ← Fullscreen camera + selfie UI (L1112–L1233)
│   └── time_mismatch_overlay.dart    ← Modal perbedaan waktu (L1040–L1110)
└── presensi_controller.dart          ← Business logic yang di-extract:
                                         - _loadData() (L120–L175)
                                         - _handleAbsen() (L177–L220)
                                         - _initCamera() + _processCameraImage()
                                           (L222–L319)
                                         - _handleTakeSelfie() (L323–L378)
                                         - _savePresensi() (L380–L457)
                                         - _handleRetryTimeSync() (L459–L483)
                                         - _handleRedoPresensi() (L485–L528)
```

#### Langkah-langkah:

1. **Buat `presensi_controller.dart`**
   - Pindahkan semua method logika bisnis (non-build method) dari `_PresensiScreenState`.
   - Gunakan pattern **mixin** atau **separate controller class** agar `_PresensiScreenState`
     tetap bisa memanggil method-method ini.
   - Contoh pendekatan **mixin**:
     ```dart
     // presensi_controller.dart
     mixin PresensiController on State<PresensiScreen> {
       // Semua business logic methods di sini
       Future<void> loadData() async { ... }
       Future<void> handleAbsen(TipePresensi jenis) async { ... }
       // dst.
     }
     ```
   - Lalu di screen utama:
     ```dart
     class _PresensiScreenState extends ConsumerState<PresensiScreen>
         with WidgetsBindingObserver, PresensiController {
       // Hanya build() + state fields
     }
     ```

2. **Buat widget-widget terpisah** (`widgets/` folder)
   - Setiap method `_buildXxx()` di-extract menjadi widget `StatelessWidget` tersendiri.
   - Kirim data yang diperlukan melalui constructor parameters.
   - Contoh:
     ```dart
     // widgets/presensi_action_buttons.dart
     class PresensiActionButtons extends StatelessWidget {
       final PresensiLog? masukLog;
       final PresensiLog? mulaiIstirahatLog;
       final PresensiLog? selesaiIstirahatLog;
       final PresensiLog? pulangLog;
       final List<PresensiLog> todayLogs;
       final bool loading;
       final VoidCallback onAbsen;
       final VoidCallback onRedo;
       // ...
     }
     ```

3. **Extract camera view ke file terpisah**
   - `presensi_camera_view.dart` berisi UI kamera dan face detection indicator.
   - Terima `CameraController`, `isFaceDetected`, callback `onTakeSelfie`, dan `onCancel`
     sebagai parameter.

---

### 4.2. `absen_form_screen.dart` (640 baris) — 🟡 Prioritas Tinggi

File ini berisi form pengajuan absen **dan** widget kalender inline kustom.

#### Struktur Pemecahan:

```
lib/presentation/screens/absen/
├── absen_form_screen.dart            ← Form utama (state + build ~250 baris)
└── widgets/
    ├── inline_multi_calendar.dart    ← Extract class _InlineMultiCalendar (L470–L641)
    ├── absen_type_section.dart       ← Section dropdown tipe absen (L262–L307)
    ├── absen_keterangan_section.dart  ← Section keterangan + lampiran (L337–L426)
    └── attachment_picker.dart        ← Bottom sheet + pick logic (L76–L153)
```

#### Langkah-langkah:

1. **Extract `_InlineMultiCalendar`** menjadi file sendiri `inline_multi_calendar.dart`.
   - Ganti prefix `_` menjadi public class `InlineMultiCalendar`.
   - File asli cukup import dari file baru.

2. **Extract section-section form** menjadi widget terpisah.
   - Setiap section (tipe, tanggal, keterangan+lampiran) jadi 1 widget.
   - Kirim state dan callback lewat constructor.

3. **Extract attachment picker logic** ke `attachment_picker.dart`.
   - Berisi `showAttachmentPicker()`, `pickImage()`, `pickPdf()`.

---

### 4.3. `rekap_screen.dart` (521 baris) — 🟡 Prioritas Tinggi

#### Struktur Pemecahan:

```
lib/presentation/screens/rekap/
├── rekap_screen.dart                 ← State + build utama (~150 baris)
└── widgets/
    ├── rekap_month_selector.dart     ← Navigasi bulan (prev/next)
    ├── rekap_calendar_grid.dart      ← Grid kalender bulanan dengan status per hari
    └── rekap_detail_card.dart        ← Card detail log presensi per tanggal terpilih
```

#### Langkah-langkah:

1. Extract widget grid kalender (yang menampilkan status dot per hari) ke
   `rekap_calendar_grid.dart`.
2. Extract card detail yang muncul ketika tanggal dipilih ke `rekap_detail_card.dart`.
3. Screen utama hanya menyimpan state pemilihan bulan/tanggal dan memanggil widget-widget ini.

---

### 4.4. `profil_screen.dart` (480 baris) — 🟡 Prioritas Tinggi

#### Struktur Pemecahan:

```
lib/presentation/screens/profil/
├── profil_screen.dart                ← State + build utama (~150 baris)
└── widgets/
    ├── profil_header_card.dart       ← Avatar + nama + NIP
    ├── profil_info_section.dart      ← Informasi detail pegawai (jabatan, pangkat, SKPD)
    ├── profil_pengaturan_card.dart   ← Tampilan pengaturan presensi SKPD
    └── profil_action_buttons.dart    ← Tombol sync + logout
```

#### Langkah-langkah:

1. Extract bagian header (avatar, nama, NIP) ke `profil_header_card.dart`.
2. Extract bagian informasi detail ke `profil_info_section.dart`.
3. Extract kartu pengaturan presensi ke `profil_pengaturan_card.dart`.
4. Extract tombol-tombol aksi (sync, logout) ke `profil_action_buttons.dart`.

---

### 4.5. `absen_screen.dart` (433 baris) — 🟡 Prioritas Sedang

#### Struktur Pemecahan:

```
lib/presentation/screens/absen/
├── absen_screen.dart                 ← State + build utama (~150 baris)
└── widgets/
    ├── absen_list_item.dart          ← Card item pengajuan absen individu
    └── absen_empty_state.dart        ← Widget state kosong
```

#### Langkah-langkah:

1. Extract card list item (yang menampilkan per pengajuan) ke `absen_list_item.dart`.
2. Extract empty state ke widget terpisah.

---

### 4.6. `sync_engine.dart` (372 baris) — 🟢 Prioritas Sedang

File ini berisi banyak fungsi top-level. Meskipun tidak memiliki class besar, namun bisa
dipecah berdasarkan domain fungsional.

#### Struktur Pemecahan:

```
lib/services/sync/
├── sync_engine.dart                  ← Re-export + fungsi utama (runFullSync, isSyncRunning)
├── sync_settings.dart               ← syncSettings(), syncPengaturan()
├── sync_presensi.dart               ← syncUnsyncedLogs(), syncLogsBulanan(), _syncLogBatch()
├── sync_hari_libur.dart             ← syncHariLibur()
├── sync_absen.dart                  ← syncAbsenPegawai()
└── sync_upload.dart                 ← _uploadPendingPhotos(), _uploadFoto()
```

#### Langkah-langkah:

1. Buat folder `lib/services/sync/`.
2. Pecah fungsi-fungsi berdasarkan domain:
   - Settings sync → `sync_settings.dart`
   - Presensi log sync (push + pull) → `sync_presensi.dart`
   - Hari libur sync → `sync_hari_libur.dart`
   - Absen sync → `sync_absen.dart`
   - Upload foto → `sync_upload.dart`
3. File `sync_engine.dart` utama menjadi **barrel file** yang re-export semua + fungsi
   `runFullSync()` yang memanggil sub-sync.
4. **UPDATE semua import** di file lain yang menggunakan `sync_engine.dart`.

---

### 4.7. `login_screen.dart` (335 baris) — 🟢 Prioritas Rendah

Mendekati batas 300 baris. Bisa dipecah jika ingin konsisten.

#### Opsional:

```
lib/presentation/screens/auth/
├── login_screen.dart                 ← State + build utama
└── widgets/
    └── login_form_card.dart          ← Card form input (username, password, tombol login)
```

---

### 4.8. `riwayat_screen.dart` (309 baris) — 🟢 Prioritas Rendah

Sedikit di atas 300 baris. Bisa dipecah jika ingin konsisten.

#### Opsional:

```
lib/presentation/screens/riwayat/
├── riwayat_screen.dart               ← State + build utama
└── widgets/
    └── riwayat_log_item.dart         ← Card item log riwayat
```

---

### 4.9. `sync_response.dart` (167 baris) — 🟢 Prioritas Rendah

File ini berisi **5 class** yang berbeda domain dalam satu file:
`SyncResponse`, `SyncedItem`, `PresignedUrlResponse`, `Coordinates`, `GeofenceResult`,
`SyncStatus`, `SyncLogItem`.

#### Opsional:

```
lib/data/models/
├── sync_response.dart                ← SyncResponse + SyncedItem
├── presigned_url_response.dart       ← PresignedUrlResponse (pindah dari sync_response.dart)
├── geofence.dart                     ← Coordinates + GeofenceResult (pindah dari sync_response.dart)
├── sync_status.dart                  ← SyncStatus (pindah dari sync_response.dart)
└── sync_log_item.dart                ← SyncLogItem (pindah dari sync_response.dart)
```

---

### 4.10. `providers.dart` (191 baris) — 🟢 Prioritas Rendah

File ini berisi 3 provider berbeda. Bisa dipecah jika ingin konsisten.

#### Opsional:

```
lib/providers/
├── providers.dart                    ← Barrel file (re-export semua)
├── pegawai_provider.dart             ← pegawaiProvider
├── geofence_provider.dart            ← GeofenceState, GeofenceNotifier, geofenceProvider
└── sync_status_provider.dart         ← SyncStatusNotifier, syncStatusProvider
```

---

## 5. Aturan Restrukturisasi

### 5.1. Aturan Umum

1. **Setiap file ≤ 300 baris** (hard limit). Target ideal: 150–250 baris.
2. **1 file = 1 tanggung jawab utama** (Single Responsibility Principle).
3. **Jangan mengubah logic/behavior sama sekali** — ini murni refactoring struktural.
4. **Pertahankan semua komentar/docstring** yang sudah ada.
5. **Jangan rename class/function** kecuali yang private `_` perlu dijadikan public.

### 5.2. Aturan Pemecahan Widget

1. Setiap method `_buildXxx()` yang > 50 baris sebaiknya menjadi widget terpisah.
2. Widget baru ditempatkan di subfolder `widgets/` di dalam folder screen masing-masing.
3. Widget menerima data via **constructor parameters**, bukan akses langsung ke state parent.
4. Callback dikirim via **VoidCallback** atau **Function** parameter.

### 5.3. Aturan Import

1. Gunakan **relative imports** untuk file di dalam folder yang sama.
2. Gunakan **relative imports dengan `../`** untuk akses antar folder dalam project.
3. Setelah pemecahan, pastikan semua file yang tadinya import file lama sudah di-update.

### 5.4. Aturan Barrel File (Opsional)

Jika diperlukan untuk menjaga kompatibilitas import:

```dart
// sync_engine.dart (barrel file)
export 'sync/sync_settings.dart';
export 'sync/sync_presensi.dart';
export 'sync/sync_hari_libur.dart';
export 'sync/sync_absen.dart';
export 'sync/sync_upload.dart';
```

---

## 6. Urutan Pengerjaan

Kerjakan berdasarkan prioritas dan dependency:

| Tahap | File | Prioritas | Estimasi |
|-------|------|-----------|----------|
| 1 | `presensi_screen.dart` | 🔴 Tertinggi | 1.5–2 jam |
| 2 | `absen_form_screen.dart` | 🟡 Tinggi | 45–60 menit |
| 3 | `rekap_screen.dart` | 🟡 Tinggi | 30–45 menit |
| 4 | `profil_screen.dart` | 🟡 Tinggi | 30–45 menit |
| 5 | `absen_screen.dart` | 🟡 Sedang | 20–30 menit |
| 6 | `sync_engine.dart` | 🟢 Sedang | 30–45 menit |
| 7 | File-file opsional (login, riwayat, providers, models) | 🟢 Rendah | 30 menit |

---

## 7. Checklist Verifikasi

Setelah **setiap** file selesai di-refactor, jalankan:

```bash
# 1. Pastikan tidak ada error analyzer
dart analyze lib

# 2. Pastikan tidak ada file > 300 baris (PowerShell)
Get-ChildItem -Path 'lib' -Recurse -File -Filter '*.dart' | ForEach-Object {
    $lines = [System.IO.File]::ReadAllLines($_.FullName).Count
    if ($lines -gt 300) { Write-Output "$lines | $($_.FullName)" }
}

# 3. Build test (pastikan compile berhasil)
flutter build apk --debug
```

---

## 8. Catatan Penting

- **JANGAN** mengubah business logic — ini adalah refactoring struktural saja.
- **JANGAN** menambahkan atau menghapus fitur.
- **JANGAN** mengubah nama class/fungsi public yang sudah ada.
- Jika menemukan bug saat refactoring, **catat** tapi jangan perbaiki di PR ini.
- Setiap tahap bisa di-commit terpisah untuk mempermudah review.
