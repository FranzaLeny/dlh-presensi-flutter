# Issue: Update Integrasi Storage — Tim Mobile (Flutter)

> **Prioritas**: 🟡 Medium (setelah backend storage module selesai deploy)
> **Estimasi**: 1–2 hari kerja
> **Tanggal**: 2026-07-12
> **Dependency**: Issue `storage-module-implementation.md` harus selesai terlebih dahulu

---

## Ringkasan

Backend telah memigrasikan sistem upload file dari **Presigned PUT URL** ke **Presigned POST URL** menggunakan `createPresignedPost` dari AWS SDK. Ini adalah **breaking change** — client Flutter harus mengupdate cara upload file.

**Perubahan utama:**
1. Endpoint presigned URL berpindah dari `/umum/presensi/presigned-url` → `/storage/:entity/presigned`
2. Metode upload berubah dari HTTP PUT → HTTP POST (multipart/form-data)
3. Response shape berubah
4. Ada field tambahan yang WAJIB disertakan saat upload

---

## Daftar Task

| # | Task | Status |
|---|------|--------|
| 1 | Update service/helper untuk generate presigned URL | ⬜ |
| 2 | Update upload logic dari PUT ke POST multipart | ⬜ |
| 3 | Tambah API service untuk preview, exists, delete | ⬜ |
| 4 | Update semua screen yang menggunakan upload (presensi, profile) | ⬜ |
| 5 | Testing end-to-end upload flow | ⬜ |
| 6 | Hapus kode lama yang menggunakan endpoint `/umum/presensi/presigned-url` | ⬜ |

---

## 1. Perubahan Endpoint

### 1.1 Endpoint Lama (DEPRECATED — AKAN DIHAPUS)

```
POST /umum/presensi/presigned-url
```

**Request Body (lama):**
```json
{
  "contentType": "image/jpeg",
  "tipePresensi": "masuk",
  "tanggal": "2026-07-12"
}
```

**Response (lama):**
```json
{
  "uploadUrl": "https://...",
  "publicUrl": "https://...",
  "url": "bucket/presensi/2026-07-12/uuid-masuk.jpg",
  "fileName": "uuid-masuk.jpg"
}
```

### 1.2 Endpoint Baru

```
POST /storage/{entity}/presigned
```

Entity yang tersedia:
- `presensi` — untuk foto presensi
- `profile` — untuk foto profil

**Request Body (baru):**
```json
{
  "contentType": "image/jpeg",
  "fileSize": 1048576,
  "tanggal": "2026-07-12",
  "tipePresensi": "masuk"
}
```

> ⚠️ **PENTING**: Field `fileSize` (dalam bytes) WAJIB disertakan. Backend akan menggunakan value ini untuk set `content-length-range` di S3 policy. Jika file yang di-upload ukurannya melebihi `fileSize` yang dideklarasikan, S3 akan **menolak** upload.

**Response (baru):**
```json
{
  "uploadUrl": "https://r2-bucket-endpoint.com",
  "fields": {
    "key": "presensi/2026-07-12/uuid-masuk.jpg",
    "Content-Type": "image/jpeg",
    "Policy": "eyJ...",
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": "...",
    "X-Amz-Date": "20260712T060000Z",
    "X-Amz-Signature": "abc123..."
  },
  "publicUrl": "https://public-domain.com/presensi/user-uuid-123/2026-07-12/uuid-masuk.jpg",
  "key": "presensi/user-uuid-123/2026-07-12/uuid-masuk.jpg"
}
```

> **Catatan**: Field `key` sekarang **selalu mengandung `userId`** dari session yang sedang login. Format: `{entity}/{userId}/...`. Ini digunakan backend untuk validasi ownership saat delete.

### 1.3 Endpoint Tambahan (Baru)

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| `GET` | `/storage/{entity}/preview?key=...` | Mendapatkan public URL untuk preview file |
| `GET` | `/storage/{entity}/exists?key=...` | Mengecek apakah file ada di storage |
| `DELETE` | `/storage/{entity}` + body `{ "key": "..." }` | Menghapus file — pegawai hanya bisa hapus file miliknya sendiri (key harus mengandung `userId` sendiri), admin bisa hapus file siapa saja |

---

## 2. Perubahan Cara Upload File

### 2.1 Cara Lama (HTTP PUT)

```dart
// ❌ CARA LAMA — JANGAN DIGUNAKAN LAGI
final response = await dio.put(
  presignedUrl,
  data: fileBytes,
  options: Options(
    headers: {'Content-Type': contentType},
  ),
);
```

### 2.2 Cara Baru (HTTP POST — Multipart Form Data)

```dart
// ✅ CARA BARU — WAJIB DIGUNAKAN
import 'package:dio/dio.dart';

Future<void> uploadFile({
  required String uploadUrl,
  required Map<String, String> fields,
  required File file,
}) async {
  final formData = FormData();

  // 1. WAJIB: Tambahkan SEMUA fields dari response presigned terlebih dahulu
  for (final entry in fields.entries) {
    formData.fields.add(MapEntry(entry.key, entry.value));
  }

  // 2. WAJIB: File harus menjadi field TERAKHIR
  formData.files.add(MapEntry(
    'file',
    await MultipartFile.fromFile(
      file.path,
      filename: file.path.split('/').last,
      contentType: MediaType.parse(fields['Content-Type'] ?? 'image/jpeg'),
    ),
  ));

  // 3. POST ke uploadUrl (bukan PUT!)
  final dio = Dio();
  final response = await dio.post(
    uploadUrl,
    data: formData,
    options: Options(
      // Jangan set Content-Type header manual — Dio akan set boundary otomatis
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  if (response.statusCode == 204 || response.statusCode == 200) {
    // Upload berhasil
  } else {
    throw Exception('Upload gagal: ${response.statusCode}');
  }
}
```

### 2.3 Full Flow — Contoh Implementasi

```dart
class StorageService {
  final Dio _dio;
  final String _baseUrl;

  StorageService(this._dio, this._baseUrl);

  /// Step 1: Request presigned POST URL dari backend
  Future<PresignedPostResponse> getPresignedUrl({
    required String entity,
    required String contentType,
    required int fileSize,
    String? tanggal,
    String? tipePresensi,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/storage/$entity/presigned',
      data: {
        'contentType': contentType,
        'fileSize': fileSize,
        if (tanggal != null) 'tanggal': tanggal,
        if (tipePresensi != null) 'tipePresensi': tipePresensi,
      },
    );

    return PresignedPostResponse.fromJson(response.data);
  }

  /// Step 2: Upload file ke S3/R2 menggunakan presigned POST
  Future<void> uploadFile({
    required PresignedPostResponse presigned,
    required File file,
  }) async {
    final formData = FormData();

    // Tambahkan semua policy fields
    for (final entry in presigned.fields.entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }

    // Tambahkan file sebagai field terakhir
    formData.files.add(MapEntry(
      'file',
      await MultipartFile.fromFile(file.path),
    ));

    // Upload langsung ke S3/R2
    final uploadDio = Dio(); // Dio baru tanpa interceptor auth
    await uploadDio.post(presigned.uploadUrl, data: formData);
  }
}
```

### 2.4 Model Response

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

## 3. Perubahan Per Fitur

### 3.1 Presensi — Upload Foto

**Sebelum:**
```dart
// Request presigned URL
final presigned = await api.post('/umum/presensi/presigned-url', {
  'contentType': 'image/jpeg',
  'tipePresensi': 'masuk',
  'tanggal': '2026-07-12',
});

// Upload via PUT
await dio.put(presigned['uploadUrl'], data: bytes);

// Simpan URL
final fotoUrl = presigned['url']; // "bucket/presensi/..."
```

**Sesudah:**
```dart
// 1. Hitung file size terlebih dahulu
final file = File(imagePath);
final fileSize = await file.length();

// 2. Request presigned POST URL
final presigned = await api.post('/storage/presensi/presigned', {
  'contentType': 'image/jpeg',
  'fileSize': fileSize,
  'tanggal': '2026-07-12',
  'tipePresensi': 'masuk',
});

// 3. Upload via POST multipart
await StorageService.uploadFile(
  presigned: PresignedPostResponse.fromJson(presigned),
  file: file,
);

// 4. Simpan key (bukan publicUrl) untuk referensi di database
// Key format: presensi/{userId}/{tanggal}/{fileName}
final fotoKey = presigned['key']; // "presensi/user-uuid-123/2026-07-12/masuk.jpg"
```

> **Catatan**: `userId` dan `fileName` otomatis disematkan/digenerate oleh backend. Client **tidak perlu** mengirimkan `userId` atau `fileName` — cukup kirim parameter relevan lainnya (seperti `tanggal` dan `tipePresensi` untuk presensi).

### 3.2 Presensi — Delete Foto (Pegawai)

Pegawai bisa menghapus file presensi **miliknya sendiri**. Backend akan memvalidasi bahwa `key` mengandung `userId` milik pemanggil.

```dart
// Hapus file presensi milik sendiri
await api.delete('/storage/presensi', data: {
  'key': fotoKey, // "presensi/user-uuid-123/2026-07-12/masuk.jpg"
});
```

> ⚠️ **PENTING**: Jika `key` tidak mengandung `userId` milik pemanggil, backend akan menolak dengan **403 Forbidden**.

### 3.3 Profile — Upload Foto Profil (Jika Ada)

```dart
final file = File(imagePath);
final fileSize = await file.length();

final presigned = await api.post('/storage/profile/presigned', {
  'contentType': 'image/jpeg',
  'fileSize': fileSize,
});

await StorageService.uploadFile(
  presigned: PresignedPostResponse.fromJson(presigned),
  file: file,
);
```

---

## 4. Batasan File

Batasan ini diatur di backend dan di-enforce oleh S3 policy. Client **HARUS** mematuhi batasan ini agar upload tidak ditolak:

### 4.1 Entity: `presensi`

| Parameter | Nilai |
|-----------|-------|
| Max file size | 5 MB |
| Allowed types | `image/jpeg`, `image/jpg`, `image/png`, `image/webp`, `application/pdf` |

### 4.2 Entity: `profile`

| Parameter | Nilai |
|-----------|-------|
| Max file size | 2 MB |
| Allowed types | `image/jpeg`, `image/jpg`, `image/png`, `image/webp` |

> ⚠️ **Penting**: Jika client mengirimkan `fileSize` yang lebih kecil dari ukuran file asli, upload ke S3 akan **GAGAL** karena S3 policy memvalidasi `content-length-range`.

---

## 5. Error Handling

### 5.1 Error dari Backend (`/storage/...`)

| Code | Error Code | Penyebab |
|------|-----------|----------|
| `400` | `INVALID_ENTITY` | Entity tidak valid (bukan `presensi`/`profile`) |
| `400` | `INVALID_CONTENT_TYPE` | Content type tidak diizinkan untuk entity tersebut |
| `400` | `FILE_TOO_LARGE` | File size melebihi batas maksimum |
| `401` | `UNAUTHORIZED` | Belum login / token expired |
| `403` | `FORBIDDEN` | Tidak punya permission, **atau** pegawai mencoba hapus file milik user lain |
| `404` | `FILE_NOT_FOUND` | File tidak ditemukan (saat delete) |

### 5.2 Error dari S3 (Saat Upload)

Jika upload ke S3 gagal, response berupa XML error:

| HTTP Code | Penyebab |
|-----------|----------|
| `400` | File size melebihi `content-length-range` yang di-set di policy |
| `400` | Content-Type file tidak cocok dengan yang dideklarasikan |
| `403` | Presigned URL expired (default: 5 menit) |
| `403` | Policy fields tidak lengkap/tidak cocok |

**Rekomendasi handling:**

```dart
try {
  await uploadFile(presigned: presigned, file: file);
} on DioException catch (e) {
  if (e.response?.statusCode == 403) {
    // Presigned URL expired — minta ulang
    // Atau: policy fields tidak cocok
  } else if (e.response?.statusCode == 400) {
    // File size / content-type mismatch
  }
}
```

---

## 6. Checklist Migrasi

- [ ] Buat `PresignedPostResponse` model
- [ ] Buat `StorageService` class/helper (upload + delete)
- [ ] Update presensi upload flow → gunakan `/storage/presensi/presigned`
- [ ] Update profile upload flow (jika ada) → gunakan `/storage/profile/presigned`
- [ ] Implementasi delete file flow → `DELETE /storage/{entity}` + `{ "key": "..." }`
- [ ] Gunakan HTTP POST + multipart/form-data (bukan PUT)
- [ ] Sertakan semua `fields` dari response presigned sebagai form-data fields
- [ ] Pastikan `file` menjadi field **terakhir** di form-data
- [ ] Hitung dan kirimkan `fileSize` (bytes) yang akurat
- [ ] Gunakan Dio instance **terpisah** (tanpa auth interceptor) untuk upload ke S3
- [ ] Handle S3 error response (XML format)
- [ ] Handle 403 saat delete (pegawai coba hapus file milik user lain)
- [ ] Simpan `key` dari response presigned — ini digunakan untuk delete dan preview
- [ ] Hapus kode lama yang menggunakan endpoint `/umum/presensi/presigned-url`
- [ ] Test upload dengan berbagai file size dan content type
- [ ] Test delete: hapus file sendiri, coba hapus file user lain (expect 403)
- [ ] Test error handling: expired URL, wrong content type, oversized file

---

## 7. Timeline

| Fase | Deadline |
|------|----------|
| Backend deploy storage module | TBD |
| Mobile mulai integrasi | Setelah backend deploy |
| Mobile testing | 1 hari setelah integrasi |
| Remove kode lama | Setelah testing selesai |

---

## 8. Kontak

Jika ada pertanyaan teknis terkait API baru, hubungi tim backend.

**Key Points:**
1. `fileSize` WAJIB akurat — jangan hardcode atau estimasi.
2. Semua `fields` dari response WAJIB disertakan — jangan skip satupun.
3. File HARUS menjadi field terakhir di form-data.
4. Gunakan Dio **tanpa** auth interceptor untuk upload ke S3/R2.
5. `key` dari response presigned **mengandung `userId`** — simpan key ini untuk keperluan delete dan preview.
6. Pegawai **bisa** delete file, tapi **hanya** file miliknya sendiri (key harus mengandung `userId` sendiri).
