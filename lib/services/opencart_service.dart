import 'package:mysql_client/mysql_client.dart';

class OpenCartService {
  // Bağlantı Bilgileri
  //final String _host = '93.89.225.215';
  // final int _port = 3306;
  //final String _user = 'gvtkoksa_oc1';
  // final String _password = 'O.141iMseLjbaEkMQAA89';
  // final String _database = 'gvtkoksa_oc1';

  MySQLConnection? _conn;

  // Bağlantı durumunu kontrol et
  bool get isConnected => _conn != null && _conn!.connected;

  /// OpenCart'taki ürün detaylarını getirir (Karşılaştırma için)
  Future<Map<String, dynamic>?> urunDetayGetir(String productId) async {
    if (!isConnected) return null;

    var res = await _conn!.execute(
      "SELECT p.price, p.quantity, p.sku,p.ean, p.location, pd.name " // sku ve location eklendi
      "FROM oc_product p "
      "LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id "
      "WHERE p.product_id = :pid AND pd.language_id = 2",
      {"pid": productId},
    );

    if (res.rows.isEmpty) return null;
    return res.rows.first.assoc();
  }

  /// MySQL Bağlantısını Akıllı Reconnect ile Yönet
  Future<bool> baglan({
    bool manuelBaslatma = false,
    Function(String mesaj, bool hata)? onMessage,
  }) async {
    try {
      // 1. KRİTİK KONTROL: Eğer kullanıcı manuel basmadıysa ve nesne null ise DUR.
      // Bu sayede sen istemeden asla bağlantı başlamaz.
      if (!manuelBaslatma && _conn == null) {
        print("Bağlantı henüz manuel olarak başlatılmadı. Reconnect iptal.");
        return false;
      }

      // 2. Zaten bağlı ve canlıysak devam et
      if (_conn != null && _conn!.connected) {
        return true;
      }

      // 3. RECONNECT VEYA İLK BAĞLANTI BAŞLATMA
      print("Bağlantı kuruluyor/tazeleniyor...");

      if (_conn != null) {
        await _conn!.close();
      }

      _conn = await MySQLConnection.createConnection(
        host: '93.89.225.215',
        port: 3306,
        userName: 'gvtkoksa_oc1',
        password: 'O.141iMseLjbaEkMQAA89',
        databaseName: 'gvtkoksa_oc1',
      );

      await _conn!.connect().timeout(const Duration(seconds: 5));

      return _conn!.connected;
    } catch (e) {
      onMessage?.call("Bağlantı Hatası: $e", true);
      _conn = null;
      return false;
    }
  }

  Future<void> kapat({Function(String mesaj, bool hata)? onMessage}) async {
    try {
      if (_conn != null && _conn!.connected) {
        await _conn!.close();
        onMessage?.call("Bağlantı güvenli bir şekilde kapatıldı.", false);
      }
    } catch (e) {
      onMessage?.call("Kapatma sırasında bir sorun oluştu.", true);
    } finally {
      _conn = null;
    }
  }

  /// Ürün OpenCart'ta var mı kontrol et (Lazarus: Locate('model', LFindID))
  /// Varsa product_id döner, yoksa null döner.
  Future<String?> urunIdSorgula(String stokKodu) async {
    if (!isConnected) return null;
    try {
      var result = await _conn!.execute(
        "SELECT product_id FROM oc_product WHERE LOWER(model) = LOWER(:model) LIMIT 1",
        {"model": stokKodu.trim()},
      );

      if (result.rows.isEmpty) return null;
      return result.rows.first.assoc()['product_id']?.toString();
    } catch (e) {
      print("Sorgu hatası: $e");
      return null;
    }
  }

  /// Yeni Ürün Ekle (Lazarus: INSERT INTO oc_product...)
  Future<bool> urunEkle({
    required String model,
    required String ad,
    required String barkod,
    required double fiyat,
    required int miktar,
    required String aciklama,
    String kategoriId = "0",
  }) async {
    if (!isConnected) return false;

    try {
      final simdi = DateTime.now().toString().split('.')[0];

      // 1. oc_product Tablosu
      var res = await _conn!.execute(
        "INSERT INTO oc_product (model, ean, sku, upc, status, quantity, price, date_added, date_modified, stock_status_id, shipping) "
        "VALUES (:model, :ean, :sku, :upc, '1', :qty, :price, :d_add, :d_mod, '7', '1')",
        {
          "model": model,
          "ean": barkod,
          "sku": barkod,
          "upc": model,
          "qty": miktar,
          "price": fiyat,
          "d_add": simdi,
          "d_mod": simdi,
        },
      );

      String newId = res.lastInsertID.toString();

      // 2. oc_product_description (Dil ID: 2 - Türkçe)
      await _conn!.execute(
        "INSERT INTO oc_product_description (product_id, language_id, name, description, meta_title) "
        "VALUES (:pid, 2, :name, :desc, :meta)",
        {"pid": newId, "name": ad, "desc": aciklama, "meta": ad},
      );

      // 3. oc_product_to_store
      await _conn!.execute(
        "INSERT INTO oc_product_to_store (product_id, store_id) VALUES (:pid, 0)",
        {"pid": newId},
      );

      // 4. oc_product_to_category
      await _conn!.execute(
        "INSERT INTO oc_product_to_category (product_id, category_id) VALUES (:pid, :cid)",
        {"pid": newId, "cid": kategoriId},
      );

      return true;
    } catch (e) {
      print("Ekleme Hatası: $e");
      return false;
    }
  }

  Future<bool> baglantiTestEt() async {
    try {
      // _conn sizin MySQLConnection nesnenizdir
      // connected özelliği bağlantının fiziksel olarak açık olup olmadığını verir
      if (_conn == null || !_conn!.connected) {
        return false;
      }

      // Bağlantı "açık" görünüyor ama gerçekten cevap veriyor mu?
      // Çok basit bir sorgu ile "ping" atıyoruz.
      await _conn!.execute("SELECT 1");
      return true;
    } catch (e) {
      print("MySQL Canlılık Testi Başarısız: $e");
      return false;
    }
  }

  /// Mevcut Ürünü Güncelle (Lazarus: UPDATE oc_product...)
  Future<bool> urunGuncelle({
    required String productId,
    required double fiyat,
    required int miktar,
    required String ad,
  }) async {
    if (!isConnected) return false;

    try {
      // Fiyat ve Miktar Güncelleme
      await _conn!.execute(
        "UPDATE oc_product SET price = :price, quantity = :qty, date_modified = NOW() WHERE product_id = :pid",
        {"pid": productId, "price": fiyat, "qty": miktar},
      );

      // İsim Güncelleme
      await _conn!.execute(
        "UPDATE oc_product_description SET name = :name WHERE product_id = :pid AND language_id = 2",
        {"pid": productId, "name": ad},
      );

      return true;
    } catch (e) {
      print("Güncelleme Hatası: $e");
      return false;
    }
  }
}
