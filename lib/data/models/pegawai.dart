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
      id: json['id']?.toString() ?? '',
      instansi: json['instansi']?.toString() ?? '',
      jenisPegawai: json['jenisPegawai']?.toString() ?? '',
      jenisKelamin: json['jenisKelamin']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      namaTanpaGelar: json['namaTanpaGelar']?.toString() ?? '',
      nip: json['nip']?.toString() ?? '',
      gelarBelakang: json['gelarBelakang']?.toString(),
      gelarDepan: json['gelarDepan']?.toString(),
      nik: json['nik']?.toString(),
      alamat: json['alamat']?.toString(),
      jabatan: json['jabatan']?.toString(),
      kodePangkatGolongan: json['kodePangkatGolongan']?.toString(),
      eselon: (json['eselon'] as num?)?.toInt(),
      isAsn: (json['isAsn'] as num?)?.toInt() ?? 0,
      tempatLahir: json['tempatLahir']?.toString(),
      tanggalLahir: json['tanggalLahir']?.toString(),
      tanggalAsn: json['tanggalAsn']?.toString(),
      skpdId: json['skpdId']?.toString() ?? '',
      namaSkpd: json['namaSkpd']?.toString() ?? '',
      userId: json['userId']?.toString(),
      username: json['username']?.toString(),
      image: json['image']?.toString(),
      localFotoPath: json['localFotoPath']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 1,
      isTtd: (json['isTtd'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
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
      kode: json['kode']?.toString() ?? '',
      pangkat: json['pangkat']?.toString() ?? '',
      golongan: json['golongan']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 1,
      keterangan: json['keterangan']?.toString(),
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
      id: json['id']?.toString() ?? '',
      kode: json['kode']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      singkatan: json['singkatan']?.toString(),
      status: (json['status'] as num?)?.toInt() ?? 1,
      isDefault: (json['isDefault'] as num?)?.toInt() ?? 0,
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
