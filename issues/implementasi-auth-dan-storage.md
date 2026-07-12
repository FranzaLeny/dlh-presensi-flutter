# Perencanaan Implementasi: Auth & Storage Integration

> **Tanggal Dibuat**: 2026-07-12
> **Estimasi Total**: 2–4 hari kerja
> **Target Pelaksana**: Junior Programmer / AI Agent
> **Issue Sumber**:
> - `issues/auth-change-email-password.md` — Fitur ubah password, ubah email via OTP, dan lupa password
> - `issues/storage-mobile-integration-update.md` — Migrasi upload file dari PUT ke POST (presigned POST URL)

---

## Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Prasyarat & Dependency](#2-prasyarat--dependency)
3. [Fase 1 — Auth: Ubah Password, Ubah Email & Lupa Password](#3-fase-1--auth-ubah-password-ubah-email--lupa-password)
4. [Fase 2 — Storage: Migrasi Upload Presigned POST URL](#4-fase-2--storage-migrasi-upload-presigned-post-url)
5. [Checklist Akhir](#5-checklist-akhir)
6. [Catatan Penting](#6-catatan-penting)

---

## 1. Gambaran Umum

Dokumen ini adalah **panduan implementasi langkah-demi-langkah** untuk dua fitur yang saling independen namun dijadwalkan dalam sprint yang sama:

| # | Fitur | Scope | Estimasi |
|---|-------|-------|----------|
| A | Auth — Ubah Password, Ubah Email (OTP), Lupa Password (OTP) | Service + Screen + Router | 1 hari |
| B | Storage — Migrasi upload file dari PUT ke POST multipart | Model + Service + Update Screen | 1–2 hari |

> ⚠️ **Kedua fitur ini TIDAK saling bergantung**. Implementasi bisa dilakukan secara **paralel** atau **berurutan**.

---

## 2. Prasyarat & Dependency

### 2.1 Dependency Backend

| Fitur | Kondisi Backend |
|-------|-----------------|
| Ubah Password | ✅ Endpoint `/auth/change-password` sudah aktif (bawaan better-auth) |
| Ubah Email (OTP) | ✅ Plugin `emailOTP` sudah aktif di backend |
| Lupa Password (OTP) | ⚠️ **PERLU koordinasi backend**: Rute `/auth/forget-password` dan `/auth/reset-password` harus **dihapus dari `disabledPaths`** di `src/core/lib/auth.ts` di sisi backend |
| Storage Migrasi | ⚠️ **PERLU backend deploy terlebih dahulu**: Issue `storage-module-implementation.md` harus selesai |

### 2.2 Dependency Package

Tidak ada package baru yang perlu ditambahkan. Semua fitur menggunakan:
- `dio` — sudah ada di `pubspec.yaml`
- `flutter_secure_storage` — sudah ada
- `go_router` — sudah ada
- `flutter_riverpod` — sudah ada

### 2.3 File-File Kunci yang Perlu Dipahami

Sebelum mulai, **BACA dan pahami** file-file berikut:

| File | Fungsi |
|------|--------|
| `lib/data/remote/api_client.dart` | Dio instance global dengan interceptor auth (auto `x-api-key` header) |
| `lib/services/auth_service.dart` | Service auth existing (login, logout, session) |
| `lib/services/absen_service.dart` | Service upload dokumen yang menggunakan **endpoint lama** (akan dimigrasi) |
| `lib/presentation/router/app_router.dart` | Router GoRouter (perlu tambah route baru) |
| `lib/presentation/screens/profil/profil_screen.dart` | Screen profil (perlu tambah menu ubah password & email) |
| `lib/presentation/screens/auth/login_screen.dart` | Screen login (perlu tambah link "Lupa Password") |

---

## 3. Fase 1 — Auth: Ubah Password, Ubah Email & Lupa Password

### 3.1 Task A1: Tambah Method di `AuthService`

**File**: `lib/services/auth_service.dart`
**Aksi**: Tambahkan 4 method static baru di class `AuthService`

```dart
// ── Ubah Password ────────────────────────────────────────────────────
/// Mengubah password saat user sudah login.
/// Membutuhkan header x-api-key (otomatis dari apiClient interceptor).
static Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
  bool revokeOtherSessions = true,
}) async {
  await apiClient.post('/auth/change-password', data: {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'revokeOtherSessions': revokeOtherSessions,
  });
}

// ── Ubah Email — Step 1: Kirim OTP ──────────────────────────────────
/// Mengirim OTP ke email baru untuk verifikasi perubahan email.
/// Membutuhkan header x-api-key.
static Future<void> sendChangeEmailOtp(String newEmail) async {
  await apiClient.post('/auth/email-otp/send-verification-otp', data: {
    'email': newEmail,
    'type': 'change-email',
  });
}

// ── Ubah Email — Step 2: Verifikasi OTP ─────────────────────────────
/// Memverifikasi OTP dan mengubah email user.
/// Membutuhkan header x-api-key.
static Future<void> verifyChangeEmailOtp({
  required String newEmail,
  required String otp,
}) async {
  await apiClient.post('/auth/email-otp/verify-email', data: {
    'email': newEmail,
    'otp': otp,
  });
}

// ── Lupa Password — Step 1: Kirim OTP Reset ─────────────────────────
/// Mengirim OTP reset password ke email terdaftar.
/// TIDAK membutuhkan header x-api-key (user belum login).
static Future<void> sendForgetPasswordOtp(String email) async {
  // Gunakan Dio instance BARU tanpa interceptor auth
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiUrl,
    headers: {'Content-Type': 'application/json'},
  ));
  await dio.post('/auth/forget-password', data: {
    'email': email,
  });
}

// ── Lupa Password — Step 2: Reset Password ──────────────────────────
/// Mereset password dengan OTP yang diterima via email.
/// TIDAK membutuhkan header x-api-key (user belum login).
static Future<void> resetPassword({
  required String newPassword,
  required String otp,
}) async {
  // Gunakan Dio instance BARU tanpa interceptor auth
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiUrl,
    headers: {'Content-Type': 'application/json'},
  ));
  await dio.post('/auth/reset-password', data: {
    'newPassword': newPassword,
    'otp': otp,
  });
}
```

> ⚠️ **PENTING**:
> - `changePassword`, `sendChangeEmailOtp`, dan `verifyChangeEmailOtp` menggunakan `apiClient` global (otomatis mengirim `x-api-key`).
> - `sendForgetPasswordOtp` dan `resetPassword` **HARUS** menggunakan Dio instance baru **TANPA interceptor** karena user belum login.

---

### 3.2 Task A2: Buat Screen Ubah Password

**File BARU**: `lib/presentation/screens/pengaturan/ubah_password_screen.dart`

**Spesifikasi UI:**
- AppBar: title "Ubah Password"
- Form dengan 3 field:
  1. `currentPassword` — Password lama (obscured, dengan toggle visibility)
  2. `newPassword` — Password baru (obscured, dengan toggle visibility)
  3. `confirmPassword` — Konfirmasi password baru (obscured)
- Tombol "Simpan"
- Loading indicator saat proses
- Validasi:
  - Semua field wajib diisi
  - `newPassword` minimal 8 karakter
  - `newPassword` harus sama dengan `confirmPassword`
- Error handling:
  - Status `400` → "Password lama salah"
  - Status lainnya → tampilkan pesan error dari server
- Setelah berhasil: tampilkan SnackBar sukses dan `Navigator.pop(context)`

**Contoh Flow:**
```
User mengisi form → tekan "Simpan"
→ panggil AuthService.changePassword(...)
→ berhasil: SnackBar "Password berhasil diubah" + pop screen
→ gagal: tampilkan error message
```

---

### 3.3 Task A3: Buat Screen Ubah Email (2 Langkah)

**File BARU**: `lib/presentation/screens/pengaturan/ubah_email_screen.dart`

**Spesifikasi UI — Langkah 1 (Input Email Baru):**
- AppBar: title "Ubah Email"
- Tampilkan email saat ini (dari data Pegawai)
- Form dengan 1 field: `newEmail`
- Tombol "Kirim Kode OTP"
- Validasi: format email valid

**Spesifikasi UI — Langkah 2 (Verifikasi OTP):**
- Setelah OTP terkirim, tampilkan form OTP (6 digit)
- Bisa gunakan 6 `TextField` terpisah atau 1 field input biasa
- Tombol "Verifikasi"
- Tombol "Kirim Ulang OTP" (dengan countdown timer 60 detik)

**Contoh Flow:**
```
User isi email baru → tekan "Kirim Kode OTP"
→ panggil AuthService.sendChangeEmailOtp(newEmail)
→ berhasil: pindah ke tampilan input OTP

User isi OTP → tekan "Verifikasi"
→ panggil AuthService.verifyChangeEmailOtp(newEmail, otp)
→ berhasil: panggil AuthService.syncPegawai() untuk refresh data
→ SnackBar "Email berhasil diubah" + pop screen
→ gagal: tampilkan error (OTP salah / expired)
```

---

### 3.4 Task A4: Buat Screen Lupa Password (2 Langkah)

**File BARU**: `lib/presentation/screens/auth/lupa_password_screen.dart`

**Spesifikasi UI — Langkah 1 (Input Email):**
- AppBar: title "Lupa Password"
- Form dengan 1 field: `email` (email terdaftar)
- Tombol "Kirim Kode OTP"

**Spesifikasi UI — Langkah 2 (OTP + Password Baru):**
- Form dengan 3 field:
  1. `otp` — Kode OTP 6 digit
  2. `newPassword` — Password baru (obscured)
  3. `confirmPassword` — Konfirmasi password baru (obscured)
- Tombol "Reset Password"
- Validasi:
  - `newPassword` minimal 8 karakter
  - `newPassword` harus sama dengan `confirmPassword`

**Contoh Flow:**
```
User isi email → tekan "Kirim Kode OTP"
→ panggil AuthService.sendForgetPasswordOtp(email)
→ berhasil: pindah ke tampilan OTP + password baru

User isi OTP + password baru → tekan "Reset Password"
→ panggil AuthService.resetPassword(newPassword, otp)
→ berhasil: SnackBar "Password berhasil direset" + navigate ke /login
→ gagal: tampilkan error (OTP salah / expired)
```

---

### 3.5 Task A5: Update Router

**File**: `lib/presentation/router/app_router.dart`

**Aksi**: Tambahkan 3 route baru (di luar `ShellRoute`, sejajar dengan `/login`):

```dart
GoRoute(
  path: '/ubah-password',
  builder: (context, state) => const UbahPasswordScreen(),
),
GoRoute(
  path: '/ubah-email',
  builder: (context, state) => const UbahEmailScreen(),
),
GoRoute(
  path: '/lupa-password',
  builder: (context, state) => const LupaPasswordScreen(),
),
```

> Jangan lupa import file screen baru di atas.

---

### 3.6 Task A6: Update Screen Profil — Tambah Menu

**File**: `lib/presentation/screens/profil/profil_screen.dart`

**Aksi**: Tambahkan 2 tombol/menu baru di area action buttons (sebelum tombol Logout):
1. **"Ubah Password"** → `context.push('/ubah-password')`
2. **"Ubah Email"** → `context.push('/ubah-email')`

Desain tombol mengikuti pattern yang sudah ada di `ProfilActionButtons` widget.

---

### 3.7 Task A7: Update Screen Login — Tambah Link Lupa Password

**File**: `lib/presentation/screens/auth/login_screen.dart`

**Aksi**: Tambahkan `TextButton` atau `GestureDetector` dengan teks **"Lupa Password?"** di bawah tombol Login:

```dart
TextButton(
  onPressed: () => context.push('/lupa-password'),
  child: const Text('Lupa Password?'),
),
```

---

## 4. Fase 2 — Storage: Migrasi Upload Presigned POST URL

### 4.1 Task B1: Buat Model `PresignedPostResponse`

**File BARU**: `lib/data/models/presigned_post_response.dart`

```dart
class PresignedPostResponse {
  final String uploadUrl;
  final Map<String, String> fields;
  final String publicUrl;
  final String key;

  PresignedPostResponse({
    required this.uploadUrl,
    required this.fields,
    required this.publicUrl,
    required this.key,
  });

  factory PresignedPostResponse.fromJson(Map<String, dynamic> json) {
    return PresignedPostResponse(
      uploadUrl: json['uploadUrl'] as String,
      fields: Map<String, String>.from(json['fields'] as Map),
      publicUrl: json['publicUrl'] as String,
      key: json['key'] as String,
    );
  }
}
```

---

### 4.2 Task B2: Buat `StorageService`

**File BARU**: `lib/services/storage_service.dart`

**Spesifikasi**:
- Class `StorageService` dengan constructor private (`StorageService._()`)
- Import `api_client.dart` untuk request presigned URL
- Gunakan Dio instance **TERPISAH** (tanpa auth interceptor) untuk upload ke S3/R2

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../data/models/presigned_post_response.dart';
import '../data/remote/api_client.dart';

class StorageService {
  StorageService._();

  /// Minta presigned POST URL dari backend.
  /// [entity] bisa "presensi" atau "profile".
  static Future<PresignedPostResponse> getPresignedUrl({
    required String entity,
    required String contentType,
    required int fileSize,
    String? tanggal,
    String? tipePresensi,
  }) async {
    final response = await apiClient.post(
      '/storage/$entity/presigned',
      data: {
        'contentType': contentType,
        'fileSize': fileSize,
        if (tanggal != null) 'tanggal': tanggal,
        if (tipePresensi != null) 'tipePresensi': tipePresensi,
      },
    );
    return PresignedPostResponse.fromJson(response.data);
  }

  /// Upload file ke S3/R2 menggunakan presigned POST.
  /// WAJIB menggunakan Dio instance terpisah tanpa auth interceptor.
  static Future<void> uploadFile({
    required PresignedPostResponse presigned,
    required File file,
  }) async {
    final formData = FormData();

    // 1. WAJIB: Tambahkan SEMUA fields dari response presigned TERLEBIH DAHULU
    for (final entry in presigned.fields.entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }

    // 2. WAJIB: File harus menjadi field TERAKHIR
    final contentType = presigned.fields['Content-Type'] ?? 'image/jpeg';
    formData.files.add(MapEntry(
      'file',
      await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
        contentType: MediaType.parse(contentType),
      ),
    ));

    // 3. POST ke uploadUrl (BUKAN PUT!) — tanpa interceptor auth
    final uploadDio = Dio();
    final response = await uploadDio.post(
      presigned.uploadUrl,
      data: formData,
      options: Options(
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Upload gagal: ${response.statusCode}');
    }
  }

  /// Upload file lengkap: request presigned + upload ke S3.
  /// Return: key dari file yang diupload.
  static Future<String> uploadToStorage({
    required String entity,
    required File file,
    required String contentType,
    String? tanggal,
    String? tipePresensi,
  }) async {
    final fileSize = await file.length();

    final presigned = await getPresignedUrl(
      entity: entity,
      contentType: contentType,
      fileSize: fileSize,
      tanggal: tanggal,
      tipePresensi: tipePresensi,
    );

    await uploadFile(presigned: presigned, file: file);

    // Return key, bukan publicUrl
    return presigned.key;
  }

  /// Hapus file dari storage.
  /// Pegawai hanya bisa hapus file miliknya sendiri.
  static Future<void> deleteFile({
    required String entity,
    required String key,
  }) async {
    await apiClient.delete('/storage/$entity', data: {'key': key});
  }

  /// Preview: dapatkan public URL untuk file.
  static Future<String> getPreviewUrl({
    required String entity,
    required String key,
  }) async {
    final response = await apiClient.get(
      '/storage/$entity/preview',
      queryParameters: {'key': key},
    );
    return response.data['url'] as String;
  }

  /// Cek apakah file ada di storage.
  static Future<bool> fileExists({
    required String entity,
    required String key,
  }) async {
    final response = await apiClient.get(
      '/storage/$entity/exists',
      queryParameters: {'key': key},
    );
    return response.data['exists'] as bool;
  }
}
```

---

### 4.3 Task B3: Update `AbsenService` — Migrasi Upload Dokumen

**File**: `lib/services/absen_service.dart`

**Aksi**: Ganti method `uploadDokumen` agar menggunakan `StorageService`.

**SEBELUM** (kode lama yang harus DIHAPUS):
```dart
static Future<String> uploadDokumen(
  String localPath,
  String tipePresensi,
  String tanggal,
  String contentType,
) async {
  // ... menggunakan /umum/presensi/presigned-url + PUT
}
```

**SESUDAH** (kode baru):
```dart
/// Upload dokumen lampiran via presigned POST URL (cara baru).
static Future<String> uploadDokumen(
  String localPath,
  String tipePresensi,
  String tanggal,
  String contentType,
) async {
  final file = File(localPath);

  // Validasi: cek file size sebelum upload
  final fileSize = await file.length();
  if (fileSize > 5 * 1024 * 1024) {
    throw Exception('Ukuran file melebihi batas maksimum 5 MB.');
  }

  final key = await StorageService.uploadToStorage(
    entity: 'presensi',
    file: file,
    contentType: contentType,
    tanggal: tanggal,
    tipePresensi: tipePresensi,
  );

  return key; // Return key (bukan publicUrl)
}
```

> ⚠️ **PENTING**: Return value berubah dari `publicUrl` menjadi `key`.
> Pastikan semua caller yang menggunakan `uploadDokumen` menyimpan `key` (bukan URL).

**Tambahkan import** di bagian atas file:
```dart
import 'storage_service.dart';
```

---

### 4.4 Task B4: Update Upload Presensi (Foto Selfie)

**File**: `lib/presentation/screens/presensi/presensi_controller.dart`

**Aksi**: Cari bagian `savePresensi` yang menyimpan `fotoPath`. Saat ini foto disimpan sebagai path lokal. Jika ada flow upload foto presensi, update agar menggunakan `StorageService`:

```dart
// Sebelum menyimpan PresensiLog, upload foto jika ada
String? fotoKey;
if (fotoPath != null) {
  final file = File(fotoPath);
  fotoKey = await StorageService.uploadToStorage(
    entity: 'presensi',
    file: file,
    contentType: 'image/jpeg',
    tanggal: today,
    tipePresensi: jenis.name,
  );
}
```

> **Catatan**: Periksa flow saat ini. Jika foto hanya disimpan lokal dan di-sync via `sync_engine.dart`, mungkin perlu update juga di sync engine. Analisis terlebih dahulu sebelum mengubah.

---

### 4.5 Task B5: Error Handling Storage

**Aksi**: Pastikan semua tempat yang memanggil `StorageService` memiliki error handling yang memadai.

**Error dari Backend:**

| Code | Error Code | Pesan untuk User |
|------|-----------|------------------|
| `400` + `INVALID_CONTENT_TYPE` | "Format file tidak didukung." |
| `400` + `FILE_TOO_LARGE` | "Ukuran file terlalu besar." |
| `401` | "Sesi login telah berakhir. Silakan login ulang." |
| `403` + `FORBIDDEN` | "Anda tidak memiliki izin untuk menghapus file ini." |
| `404` + `FILE_NOT_FOUND` | "File tidak ditemukan." |

**Error dari S3 (saat upload ke `uploadUrl`):**

| Code | Pesan untuk User |
|------|------------------|
| `400` | "Upload gagal. Ukuran file tidak sesuai." |
| `403` | "Link upload sudah kadaluarsa. Silakan coba lagi." |

**Contoh implementasi helper:**
```dart
String getStorageErrorMessage(DioException e) {
  final statusCode = e.response?.statusCode;
  final errorCode = e.response?.data?['code'];

  if (statusCode == 400) {
    if (errorCode == 'INVALID_CONTENT_TYPE') return 'Format file tidak didukung.';
    if (errorCode == 'FILE_TOO_LARGE') return 'Ukuran file terlalu besar.';
    return 'Upload gagal. Periksa format dan ukuran file.';
  }
  if (statusCode == 403) {
    if (errorCode == 'FORBIDDEN') return 'Anda tidak memiliki izin untuk menghapus file ini.';
    return 'Link upload sudah kadaluarsa. Silakan coba lagi.';
  }
  if (statusCode == 404) return 'File tidak ditemukan.';
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
```

---

### 4.6 Task B6: Validasi File di Client (Sebelum Upload)

**Aksi**: Tambahkan validasi di client **SEBELUM** memanggil API presigned, agar user mendapat feedback cepat.

```dart
class FileValidator {
  static const Map<String, int> _maxSizeBytes = {
    'presensi': 5 * 1024 * 1024,  // 5 MB
    'profile': 2 * 1024 * 1024,   // 2 MB
  };

  static const Map<String, List<String>> _allowedTypes = {
    'presensi': ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf'],
    'profile': ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'],
  };

  static String? validate(String entity, File file, String contentType) {
    final maxSize = _maxSizeBytes[entity];
    if (maxSize != null && file.lengthSync() > maxSize) {
      final maxMb = maxSize ~/ (1024 * 1024);
      return 'Ukuran file melebihi batas maksimum $maxMb MB.';
    }

    final allowed = _allowedTypes[entity];
    if (allowed != null && !allowed.contains(contentType)) {
      return 'Format file tidak didukung.';
    }

    return null; // valid
  }
}
```

**Lokasi file**: `lib/core/utils/file_validator.dart` (baru)

---

### 4.7 Task B7: Hapus Kode Lama

Setelah semua task di atas selesai dan **sudah di-test**:

1. **Hapus** endpoint lama `/umum/presensi/presigned-url` dari semua file.
2. **Hapus** semua pemanggilan `Dio().put(...)` untuk upload file.
3. Cari dengan keyword: `presigned-url`, `uploadUrl`, `.put(` untuk memastikan tidak ada yang terlewat.

---

## 5. Checklist Akhir

### Fase 1 — Auth

- [ ] **A1**: Tambah 4 method baru di `AuthService` (changePassword, sendChangeEmailOtp, verifyChangeEmailOtp, sendForgetPasswordOtp, resetPassword)
- [ ] **A2**: Buat `UbahPasswordScreen` (`lib/presentation/screens/pengaturan/ubah_password_screen.dart`)
- [ ] **A3**: Buat `UbahEmailScreen` (`lib/presentation/screens/pengaturan/ubah_email_screen.dart`)
- [ ] **A4**: Buat `LupaPasswordScreen` (`lib/presentation/screens/auth/lupa_password_screen.dart`)
- [ ] **A5**: Update `app_router.dart` — tambah 3 route baru
- [ ] **A6**: Update `profil_screen.dart` — tambah menu Ubah Password & Ubah Email
- [ ] **A7**: Update `login_screen.dart` — tambah link "Lupa Password?"
- [ ] **A8**: Test: ubah password dengan password lama benar
- [ ] **A9**: Test: ubah password dengan password lama salah (expect error)
- [ ] **A10**: Test: ubah email → kirim OTP → verifikasi OTP → data pegawai ter-update
- [ ] **A11**: Test: lupa password → kirim OTP → reset password → bisa login dengan password baru

### Fase 2 — Storage

- [ ] **B1**: Buat model `PresignedPostResponse` (`lib/data/models/presigned_post_response.dart`)
- [ ] **B2**: Buat `StorageService` (`lib/services/storage_service.dart`)
- [ ] **B3**: Update `AbsenService.uploadDokumen` → gunakan `StorageService`
- [ ] **B4**: Update upload presensi foto (jika ada flow upload foto)
- [ ] **B5**: Implementasi error handling storage
- [ ] **B6**: Buat `FileValidator` (`lib/core/utils/file_validator.dart`)
- [ ] **B7**: Hapus kode lama (endpoint `/umum/presensi/presigned-url` + PUT upload)
- [ ] **B8**: Test: upload file presensi (JPEG, < 5MB) — expect sukses
- [ ] **B9**: Test: upload file terlalu besar — expect error
- [ ] **B10**: Test: upload content type tidak didukung — expect error
- [ ] **B11**: Test: delete file milik sendiri — expect sukses
- [ ] **B12**: Test: delete file milik orang lain — expect 403

---

## 6. Catatan Penting

### Aturan Penggunaan `apiClient` vs Dio Baru

| Situasi | Gunakan |
|---------|---------|
| User **sudah login** dan endpoint butuh auth | `apiClient` (global Dio dengan interceptor `x-api-key`) |
| User **belum login** (lupa password) | `Dio()` baru tanpa interceptor |
| Upload ke S3/R2 (endpoint bukan milik backend kita) | `Dio()` baru tanpa interceptor |

### Struktur File Baru yang Akan Dibuat

```
lib/
├── core/
│   └── utils/
│       └── file_validator.dart          ← [BARU] B6
├── data/
│   └── models/
│       └── presigned_post_response.dart ← [BARU] B1
├── services/
│   ├── auth_service.dart                ← [MODIF] A1
│   ├── absen_service.dart               ← [MODIF] B3
│   └── storage_service.dart             ← [BARU] B2
├── presentation/
│   ├── router/
│   │   └── app_router.dart              ← [MODIF] A5
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart         ← [MODIF] A7
│       │   └── lupa_password_screen.dart ← [BARU] A4
│       ├── pengaturan/
│       │   ├── ubah_password_screen.dart ← [BARU] A2
│       │   └── ubah_email_screen.dart    ← [BARU] A3
│       ├── presensi/
│       │   └── presensi_controller.dart  ← [MODIF] B4
│       └── profil/
│           └── profil_screen.dart        ← [MODIF] A6
```

### Urutan Implementasi yang Direkomendasikan

```
1. B1 (Model)
2. B2 (StorageService)
3. B6 (FileValidator)
4. B3 (Update AbsenService)
5. B4 (Update PresensiController)
6. B5 (Error handling)
7. B7 (Hapus kode lama) — setelah testing
8. A1 (Method AuthService)
9. A2 (Screen Ubah Password)
10. A3 (Screen Ubah Email)
11. A4 (Screen Lupa Password)
12. A5 (Update Router)
13. A6 (Update Profil)
14. A7 (Update Login)
```

> **Alasan**: Storage bisa ditesting lebih awal secara independen. Auth fitur membutuhkan lebih banyak screen baru.
