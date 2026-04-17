class Stok {
  final int? id;
  final String? stokKod;
  final String stokAdi;
  final String barkod;
  final String? alisFiyati; // TRY Alış
  final String? satisFiyati; // TRY Satış
  final String? dolarAlis; // DALIS
  final String? dolarSatis; // OZEL
  final String? euroSatis; // OZEL2
  final String? miktar;
  final String? image; // <-- YENİ EKLENEN SATIR

  Stok({
    this.id,
    this.stokKod,
    required this.stokAdi,
    required this.barkod,
    this.alisFiyati,
    this.satisFiyati,
    this.dolarAlis,
    this.dolarSatis,
    this.euroSatis,
    this.miktar,
    this.image, // <-- YENİ EKLENEN SATIR
  });

  factory Stok.fromMap(Map<String, dynamic> json) {
    var hamMiktar = json['MIKTAR'] ?? json['miktar'] ?? "0";
    String temizMiktar = double.parse(hamMiktar.toString()).toInt().toString();
    return Stok(
      id: json['KIMLIK'],
      stokKod: json['STOK_KOD'],
      stokAdi: json['STOK_ADI'] ?? '',
      barkod: json['BARKOD'] ?? '',
      alisFiyati: json['ALIS']?.toString(),
      satisFiyati: json['SATIS']?.toString(),
      dolarAlis: json['DALIS']?.toString(), // Veritabanındaki karşılığı
      dolarSatis: json['OZEL']?.toString(), // Veritabanındaki karşılığı
      euroSatis: json['OZEL2']?.toString(), // Veritabanındaki karşılığı
      miktar: temizMiktar,
      image: json['image']?.toString(), // <-- YENİ EKLENEN SATIR
    );
  }
}
