// ====================================
// Model: Pegawai — Profil Pegawai
// ====================================

/// Response data profil pegawai dari backend
class Pegawai {
  final String id;
  final String instansi;
  final String jenisPegawai; // 'PNS' | 'PPPK' | 'NON_ASN'
  final String jenisKelamin; // 'L' | 'P'
  final String nama;
  final String namaTanpaGelar;
  final String nip;
  final String? gelarBelakang;
  final String? gelarDepan;
  final String? nik;
  final String? alamat;
  final String? jabatan;
  final String? kodePangkatGolongan;
  final int? eselon;
  final int isAsn; // 0: Non ASN, 1: ASN
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? tanggalAsn;
  final String skpdId;
  final String namaSkpd;
  final String? userId;
  final String? username;
  final String? image;
  final String? localFotoPath;
  final int status;
  final int isTtd;
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final PangkatGolongan? pangkatGolongan;
  final Skpd? skpd;

  const Pegawai({
    required this.id,
    required this.instansi,
    required this.jenisPegawai,
    required this.jenisKelamin,
    required this.nama,
    required this.namaTanpaGelar,
    required this.nip,
    this.gelarBelakang,
    this.gelarDepan,
    this.nik,
    this.alamat,
    this.jabatan,
    this.kodePangkatGolongan,
    this.eselon,
    this.isAsn = 0,
    this.tempatLahir,
    this.tanggalLahir,
    this.tanggalAsn,
    required this.skpdId,
    required this.namaSkpd,
    this.userId,
    this.username,
    this.image,
    this.localFotoPath,
    required this.status,
    this.isTtd = 0,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.pangkatGolongan,
    this.skpd,
  });

  factory Pegawai.fromJson(Map<String, dynamic> json) {
    return Pegawai(
      id: json['id'] as String,
      instansi: json['instansi'] as String,
      jenisPegawai: json['jenisPegawai'] as String,
      jenisKelamin: json['jenisKelamin'] as String,
      nama: json['nama'] as String,
      namaTanpaGelar: json['namaTanpaGelar'] as String,
      nip: json['nip'] as String,
      gelarBelakang: json['gelarBelakang'] as String?,
      gelarDepan: json['gelarDepan'] as String?,
      nik: json['nik'] as String?,
      alamat: json['alamat'] as String?,
      jabatan: json['jabatan'] as String?,
      kodePangkatGolongan: json['kodePangkatGolongan'] as String?,
      eselon: (json['eselon'] as num?)?.toInt(),
      isAsn: (json['isAsn'] as num?)?.toInt() ?? 0,
      tempatLahir: json['tempatLahir'] as String?,
      tanggalLahir: json['tanggalLahir'] as String?,
      tanggalAsn: json['tanggalAsn'] as String?,
      skpdId: json['skpdId'] as String,
      namaSkpd: json['namaSkpd'] as String,
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      image: json['image'] as String?,
      localFotoPath: json['localFotoPath'] as String?,
      status: (json['status'] as num).toInt(),
      isTtd: (json['isTtd'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      pangkatGolongan: json['pangkatGolongan'] != null
          ? PangkatGolongan.fromJson(
              json['pangkatGolongan'] as Map<String, dynamic>)
          : null,
      skpd: json['skpd'] != null
          ? Skpd.fromJson(json['skpd'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'instansi': instansi,
        'jenisPegawai': jenisPegawai,
        'jenisKelamin': jenisKelamin,
        'nama': nama,
        'namaTanpaGelar': namaTanpaGelar,
        'nip': nip,
        'gelarBelakang': gelarBelakang,
        'gelarDepan': gelarDepan,
        'nik': nik,
        'alamat': alamat,
        'jabatan': jabatan,
        'kodePangkatGolongan': kodePangkatGolongan,
        'eselon': eselon,
        'isAsn': isAsn,
        'tempatLahir': tempatLahir,
        'tanggalLahir': tanggalLahir,
        'tanggalAsn': tanggalAsn,
        'skpdId': skpdId,
        'namaSkpd': namaSkpd,
        'userId': userId,
        'username': username,
        'image': image,
        'localFotoPath': localFotoPath,
        'status': status,
        'isTtd': isTtd,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'pangkatGolongan': pangkatGolongan?.toJson(),
        'skpd': skpd?.toJson(),
      };

  Pegawai copyWith({
    String? id,
    String? instansi,
    String? jenisPegawai,
    String? jenisKelamin,
    String? nama,
    String? namaTanpaGelar,
    String? nip,
    String? gelarBelakang,
    String? gelarDepan,
    String? nik,
    String? alamat,
    String? jabatan,
    String? kodePangkatGolongan,
    int? eselon,
    int? isAsn,
    String? tempatLahir,
    String? tanggalLahir,
    String? tanggalAsn,
    String? skpdId,
    String? namaSkpd,
    String? userId,
    String? username,
    String? image,
    String? localFotoPath,
    int? status,
    int? isTtd,
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? updatedBy,
    PangkatGolongan? pangkatGolongan,
    Skpd? skpd,
  }) {
    return Pegawai(
      id: id ?? this.id,
      instansi: instansi ?? this.instansi,
      jenisPegawai: jenisPegawai ?? this.jenisPegawai,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      nama: nama ?? this.nama,
      namaTanpaGelar: namaTanpaGelar ?? this.namaTanpaGelar,
      nip: nip ?? this.nip,
      gelarBelakang: gelarBelakang ?? this.gelarBelakang,
      gelarDepan: gelarDepan ?? this.gelarDepan,
      nik: nik ?? this.nik,
      alamat: alamat ?? this.alamat,
      jabatan: jabatan ?? this.jabatan,
      kodePangkatGolongan: kodePangkatGolongan ?? this.kodePangkatGolongan,
      eselon: eselon ?? this.eselon,
      isAsn: isAsn ?? this.isAsn,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      tanggalAsn: tanggalAsn ?? this.tanggalAsn,
      skpdId: skpdId ?? this.skpdId,
      namaSkpd: namaSkpd ?? this.namaSkpd,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      image: image ?? this.image,
      localFotoPath: localFotoPath ?? this.localFotoPath,
      status: status ?? this.status,
      isTtd: isTtd ?? this.isTtd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      pangkatGolongan: pangkatGolongan ?? this.pangkatGolongan,
      skpd: skpd ?? this.skpd,
    );
  }
}

class PangkatGolongan {
  final String kode;
  final String pangkat;
  final String golongan;
  final String ruang;
  final int status;
  final String? keterangan;

  const PangkatGolongan({
    required this.kode,
    required this.pangkat,
    required this.golongan,
    required this.ruang,
    required this.status,
    this.keterangan,
  });

  factory PangkatGolongan.fromJson(Map<String, dynamic> json) {
    return PangkatGolongan(
      kode: json['kode'] as String,
      pangkat: json['pangkat'] as String,
      golongan: json['golongan'] as String,
      ruang: json['ruang'] as String,
      status: (json['status'] as num).toInt(),
      keterangan: json['keterangan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'kode': kode,
        'pangkat': pangkat,
        'golongan': golongan,
        'ruang': ruang,
        'status': status,
        'keterangan': keterangan,
      };
}

class Skpd {
  final String id;
  final String kode;
  final String nama;
  final String? singkatan;
  final int status;
  final int isDefault;

  const Skpd({
    required this.id,
    required this.kode,
    required this.nama,
    this.singkatan,
    required this.status,
    required this.isDefault,
  });

  factory Skpd.fromJson(Map<String, dynamic> json) {
    return Skpd(
      id: json['id'] as String,
      kode: json['kode'] as String,
      nama: json['nama'] as String,
      singkatan: json['singkatan'] as String?,
      status: (json['status'] as num).toInt(),
      isDefault: (json['isDefault'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kode': kode,
        'nama': nama,
        'singkatan': singkatan,
        'status': status,
        'isDefault': isDefault,
      };
}
