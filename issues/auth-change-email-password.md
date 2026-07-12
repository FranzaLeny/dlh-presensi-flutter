# Issue: Panduan Implementasi Auth (Ubah Password, Ubah Email & Lupa Password)

> **Prioritas**: 🔵 Low / 🟡 Medium
> **Estimasi**: 1 hari kerja
> **Tags**: `auth`, `security`, `mobile-integration`

---

## Ringkasan

Sistem autentikasi saat ini secara penuh menggunakan `better-auth` yang telah dikonfigurasi pada `src/core/lib/auth.ts`. Sesuai standar arsitektur, **semua alur autentikasi WAJIB menggunakan endpoint bawaan (native) dari `better-auth`** untuk memastikan *update* atau *maintenance* ke depannya tidak menimbulkan masalah kompatibilitas.

> ⚠️ **Catatan Penting untuk Mobile (Flutter):**
> Karena aplikasi *mobile* menggunakan skema autentikasi **API Key**, maka setiap panggilan *endpoint* yang membutuhkan autorisasi/sesi aktif **WAJIB** menyertakan *header* `x-api-key: <API_KEY>` alih-alih `Authorization: Bearer <token>`.

---

## 1. Ubah Password (Ganti Password Saat Login)

Fitur ini digunakan saat pengguna sedang login dan ingin mengganti *password* lamanya.

**Endpoint:** `POST /auth/change-password`

**Header:**
- `x-api-key: <API_KEY>`

**Payload (JSON):**
```json
{
  "newPassword": "password_baru",
  "currentPassword": "password_lama",
  "revokeOtherSessions": true
}
```

---

## 2. Ubah Email via OTP (Change Email)

Perubahan *email* dilindungi secara penuh oleh OTP (plugin `emailOTP`). 

### Alur Kerja (Workflow) Tim Mobile:
#### Langkah 1: Meminta OTP (Request OTP)
- **Endpoint:** `POST /auth/email-otp/send-verification-otp`
- **Header:** `x-api-key: <API_KEY>`
- **Payload:**
```json
{
  "email": "email_baru@domain.com",
  "type": "change-email"
}
```

#### Langkah 2: Verifikasi OTP
- **Endpoint:** `POST /auth/email-otp/verify-email`
- **Header:** `x-api-key: <API_KEY>`
- **Payload:**
```json
{
  "email": "email_baru@domain.com",
  "otp": "123456"
}
```

---

## 3. Lupa Password via OTP (Forget Password)

Untuk pengguna yang belum/tidak bisa login dan lupa *password*.

> 🔧 **Tugas Backend:** Saat ini rute `/forget-password` dan `/reset-password` ada di dalam array `disabledPaths` di file `src/core/lib/auth.ts`. Anda **HARUS** menghapusnya dari `disabledPaths` agar fitur ini bisa diakses.

### Alur Kerja (Workflow) Lupa Password dengan OTP:

#### Langkah 1: Meminta OTP Reset Password
- **Endpoint:** `POST /auth/forget-password`
- **Payload:**
```json
{
  "email": "user@domain.com"
}
```
*Catatan: Karena plugin `emailOTP` aktif, `better-auth` secara otomatis akan mencegat pengiriman link dan mengubahnya menjadi pengiriman OTP reset password ke email.*

#### Langkah 2: Reset Password (Input OTP & Password Baru)
- **Endpoint:** `POST /auth/reset-password`
- **Payload:**
```json
{
  "newPassword": "password_baru_sekali",
  "otp": "123456"
}
```
*Catatan: Pada tahap lupa password, pengguna belum login, sehingga **TIDAK PERLU** mengirimkan header `x-api-key`.*

---

## 4. Checklist Integrasi (Frontend / Mobile)

- [ ] Pastikan pemanggilan *endpoint* yang butuh sesi login menyertakan *header* `x-api-key` (Ubah Password & Ubah Email).
- [ ] Ubah Password: Implementasikan *form* dengan parameter `newPassword` & `currentPassword`.
- [ ] Ubah Email: Implementasikan dua form (1 untuk input *email* baru, 1 untuk verifikasi *OTP*).
- [ ] Lupa Password: Implementasikan dua form (1 untuk input *email* yang terdaftar, 1 untuk verifikasi *OTP* sekaligus input *password* baru).
- [ ] *Mapping error message* dari *better-auth* di sisi *client* (seperti kode `400` untuk *password* lama salah, atau OTP *invalid/expired*).
