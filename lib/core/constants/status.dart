// ====================================
// Status Constants — Enum Status Presensi
// ====================================

class Status {
  Status._();

  static const int deleted = -100; // hilang permanen
  static const int inactive = -10; // tidak aktif, bisa diaktifkan lagi
  static const int draft = 0; // belum dipublikasikan (netral)
  static const int rejected = 1; // ditolak
  static const int pending = 2; // menunggu verifikasi
  static const int accepted = 5; // diterima
  static const int active = 10; // aktif
  static const int approved = 11; // disetujui
  static const int registered = 20; // sudah terdaftar
  static const int finalized = 30; // sudah finalisasi
  static const int published = 50; // sudah dipublikasikan
  static const int archived = 100; // disimpan, tidak aktif
  static const int locked = 200; // terkunci, tidak bisa diubah
}

const Map<int, String> statusLabel = {
  Status.active: 'Aktif',
  Status.deleted: 'Dihapus',
  Status.inactive: 'Tidak Aktif',
  Status.archived: 'Arsip',
  Status.locked: 'Dikunci',
  Status.draft: 'Draft',
  Status.published: 'Dipublikasi',
  Status.registered: 'Terdaftar',
  Status.accepted: 'Diterima',
  Status.finalized: 'Selesai',
  Status.rejected: 'Ditolak',
  Status.pending: 'Menunggu Verifikasi',
  Status.approved: 'Disetujui',
};

String getStatusLabel(int status) {
  return statusLabel[status] ?? 'Tidak Diketahui';
}
