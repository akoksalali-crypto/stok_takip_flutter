class StringUtils {
  /// Türkçe karakterleri dönüştürür ve SEO uyumlu URL yapısına çevirir.
  /// Boşlukları ve özel karakterleri '-' ile değiştirir.
  /// En fazla 3 kelimelik bir URL döndürür.
  static String toSeoUrl(String metin) {
    if (metin.isEmpty) return "";
    String res = metin.toLowerCase();
    res = res
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    
    // Alfasayısal olmayan tüm karakterleri '-' yap
    res = res.replaceAll(RegExp(r'[^a-z0-9]'), '-');
    
    // Yan yana gelen '-' karakterlerini teke düşür
    while (res.contains('--')) {
      res = res.replaceAll('--', '-');
    }
    
    // Baştaki ve sondaki '-' karakterlerini temizle
    if (res.startsWith('-')) res = res.substring(1);
    if (res.endsWith('-')) res = res.substring(0, res.length - 1);
    
    // En fazla 3 kelime al
    List<String> kelimeler = res.split('-');
    if (kelimeler.length > 3) {
      res = kelimeler.sublist(0, 3).join('-');
    }
    return res;
  }

  /// Dosya isimlerinde kullanılabilecek, Türkçe karakterlerden ve 
  /// özel işaretlerden arındırılmış bir string döndürür.
  static String temizleDosyaAdi(String metin) {
    if (metin.isEmpty) return "";
    String gecici = metin
        .replaceAll('ç', 'c').replaceAll('Ç', 'C')
        .replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
        .replaceAll('ı', 'i').replaceAll('İ', 'I')
        .replaceAll('ö', 'o').replaceAll('Ö', 'O')
        .replaceAll('ş', 's').replaceAll('Ş', 'S')
        .replaceAll('ü', 'u').replaceAll('Ü', 'U');
    
    // Harf, rakam, alt çizgi ve tire dışındaki her şeyi '_' yap
    return gecici.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
