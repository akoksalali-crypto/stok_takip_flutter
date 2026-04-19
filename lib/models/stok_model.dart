// ignore_for_file: non_constant_identifier_names

class Stok {
  final int? id;
  final String? stokKod;
  final String stokAdi;
  final String barkod;
  final String? barkod2; // Ek Barkod 2
  final String? barkod3; // Ek Barkod 2
  final String? barkod4; // Ek Barkod 2
  final String? barkod5; // Ek Barkod 2
  final String? barkod6; // Ek Barkod 2
  final String? barkod7; // Ek Barkod 2
  final String? alisFiyati; // TRY Alış
  final String? satisFiyati; // TRY Satış
  final String? dolarAlis; // DALIS
  final String? dolarSatis; // OZEL
  final String? euroSatis; // OZEL2
  final String? miktar;
  final String? marj; // <-- YENİ EKLENEN SATIR
  final String? kdv; // <-- YENİ EKLENEN SATIR
  final String? lot; // <-- YENİ EKLENEN SATIR
  final String? weight; // <-- YENİ EKLENEN SATIR
  final String? webLink;
  final String? metaTitle;
  final String? Fdate; // <-- ilk giriş tarihi
  final String? Ldate; // <-- Son giriş tarihi
  final String? beden; // <-- YENİ EKLENEN SATIR

  final String? image; // <-- YENİ EKLENEN SATIR

  Stok({
    this.id,
    this.stokKod,
    required this.stokAdi,
    required this.barkod,
    this.barkod2,
    this.barkod3,
    this.barkod4,
    this.barkod5,
    this.barkod6,
    this.barkod7,
    this.alisFiyati,
    this.satisFiyati,
    this.dolarAlis,
    this.dolarSatis,
    this.euroSatis,
    this.miktar,
    this.marj, // <-- YENİ EKLENEN SATIR
    this.kdv, // <-- YENİ EKLENEN SATIR
    this.lot, // <-- YENİ EKLENEN SATIR
    this.weight, // <-- YENİ EKLENEN SATIR
    this.metaTitle, // <-- YENİ EKLENEN SATIR
    this.webLink, // <-- YENİ EKLENEN SATIR
    this.image, // <-- YENİ EKLENEN SATIR
    this.Fdate, // <-- ilk giriş tarihi
    this.Ldate, // <-- Son giriş tarihi
    this.beden, // beden bilgisi (örneğin: S, M, L, XL) - <-- YENİ EKLENEN SATIR
  });

  factory Stok.fromMap(Map<String, dynamic> json) {
    var hamMiktar = json['MIKTAR'] ?? "0";
    String temizMiktar = double.parse(hamMiktar.toString()).toInt().toString();
    return Stok(
      id: json['KIMLIK'],
      stokKod: json['STOK_KOD'],
      stokAdi: json['STOK_ADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      barkod2: json['BARKOD2'] ?? '',
      barkod3: json['BARKOD3'] ?? '',
      barkod4: json['BARKOD4'] ?? '',
      barkod5: json['BARKOD5'] ?? '',
      barkod6: json['BARKOD6'] ?? '',
      barkod7: json['BARKOD7'] ?? '',

      alisFiyati: json['ALIS']?.toString(),
      satisFiyati: json['SATIS']?.toString(),
      dolarAlis: json['DALIS']?.toString(), // Veritabanındaki karşılığı
      dolarSatis: json['OZEL']?.toString(), // Veritabanındaki karşılığı
      euroSatis: json['OZEL2']?.toString(), // Veritabanındaki karşılığı
      marj: json['MARJ']?.toString(), // <-- YENİ EKLENEN SATIR
      kdv: json['KDV']?.toString(), // <-- YENİ EKLENEN SATIR
      miktar: temizMiktar,
      lot: json['LOT']?.toString(), // <-- YENİ EKLENEN SATIR
      weight: json['WEIGHT']?.toString(), // <-- YENİ EKLENEN SATIR
      metaTitle: json['META_TITLE']?.toString(), // <-- YENİ EKLENEN SATIR
      webLink: json['WebLink']?.toString(), // <-- YENİ EKLENEN SATIR
      image: json['image']?.toString(), // <-- YENİ EKLENEN SATIR
      Fdate: json['FDATE']?.toString(), // <-- ilk giriş tarihi
      Ldate: json['LDATE']?.toString(), // <-- Son giriş tarihi
      beden: json['TART']?.toString(), // <-- YENİ EKLENEN SATIR
    );
  }
  // Nesneden (Object) Veritabanına (Map) Dönüştürme
  // Kaydet butonuna bastığında bu harita kullanılır.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'KIMLIK': id, // Güncelleme için önemli
      'STOK_KOD': stokKod,
      'STOK_ADI': stokAdi,
      'BARKOD': barkod,
      'BARKOD2': barkod2,
      'BARKOD3': barkod3,
      'BARKOD4': barkod4,
      'BARKOD5': barkod5,
      'BARKOD6': barkod6,
      'BARKOD7': barkod7,
      'ALIS': alisFiyati,
      'SATIS': satisFiyati,
      'DALIS': dolarAlis,
      'OZEL': dolarSatis,
      'OZEL2': euroSatis,
      'MIKTAR': miktar,
      'MARJ': marj,
      'KDV': kdv,
      'LOT': lot, // SQLite kolon adın büyük harf ise büyük yazmalısın
      'WEIGHT': weight,
      'META_TITLE': metaTitle,
      'WebLink': webLink,
      'image': image,
      'FDATE': Fdate,
      'LDATE': Ldate,
      'TART': beden,
    };
  }
}
