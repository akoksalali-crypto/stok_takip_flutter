// ignore_for_file: avoid_print
import 'package:mysql_client/mysql_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import '../utils/string_utils.dart';

class OpenCartService {
  DateTime? _sonIslemZamani; // Son başarılı sorgu zamanını tutar
  MySQLConnection? _conn; // Bağlantı Nesnesi

  // KRİTİK DÜZELTME: Sunucuya sormadan sadece nesne var mı ona bakar.
  // Bu sayede 8. dakikadaki kilitlenmeyi engeller.
  bool get isConnected => _conn != null;

  Future<void> _guvenliBaglantiSifirla() async {
    try {
      if (_conn != null) {
        await _conn!.close().timeout(const Duration(seconds: 1));
      }
    } catch (_) {}
    _conn = null;
    _sonIslemZamani = null;
  }

  /// Ürün detaylarını çekmek için kullanılan donma korumalı fonksiyon
  Future<Map<String, dynamic>?> urunDetayGetir(
    String productId, {
    Function(String mesaj, bool hata)? onMessage,
  }) async {
    // Arayüzün nefes alması için çok kısa bir duraksama (Kilitlenmeyi hafifletir)
    await Future.delayed(const Duration(milliseconds: 10));

    // 1. ADIM: Katı Zaman Bariyeri
    // Eğer 7 dakika geçtiyse kütüphaneye DOKUNMADAN (execute demeden) çıkıyoruz.
    if (_sonIslemZamani != null) {
      int gecenSureSaniye = DateTime.now()
          .difference(_sonIslemZamani!)
          .inSeconds;
      if (gecenSureSaniye > 420) {
        // 7 dakika sınırı
        await _guvenliBaglantiSifirla();

        // Önemli: Mesajı microtask ile gönderiyoruz ki UI kilitli kalsa bile aradan sızsın
        Future.microtask(
          () => onMessage?.call(
            "Oturum süresi doldu (7 dk+). Lütfen tekrar bağlanın.",
            true,
          ),
        );
        return null;
      }
    }

    // 2. ADIM: Bağlantı kontrolü (Sadece nesne var mı bakıyoruz)
    if (_conn == null) {
      onMessage?.call("OpenCart bağlantısı aktif değil!", true);
      return null;
    }

    try {
      // 3. ADIM: Riskli bölge (Execute öncesi ve sonrası çok dikkatli olunmalı)
      // Kütüphane kilitlenirse timeout(2s) ana iş parçacığını kurtarmaya çalışacak
      var res = await _conn!
          .execute(
            "SELECT p.product_id, p.price, p.tax_class_id, p.quantity, p.status, p.sku, p.ean, p.image, p.location, p.minimum, p.weight, p.date_modified, "
            "pd.name, pd.description, pd.meta_title, pd.meta_description, pd.meta_keyword, "
            "su.keyword AS seo_url "
            "FROM oc_product p "
            "LEFT JOIN oc_product_description pd ON p.product_id = pd.product_id AND pd.language_id = 2 "
            "LEFT JOIN oc_seo_url su ON su.query = CONCAT('product_id=', p.product_id) AND su.language_id = 2 "
            "WHERE p.product_id = :pid",
            {"pid": productId},
          )
          .timeout(
            const Duration(seconds: 2),
          ); // Süreyi 2 saniyeye indirdik ki donma hissi azalsın

      // Sorgu başarılıysa zamanı hemen güncelle
      _sonIslemZamani = DateTime.now();

      if (res.rows.isEmpty) return null;
      return res.rows.first.assoc();
    } on TimeoutException catch (_) {
      await _guvenliBaglantiSifirla();
      Future.microtask(
        () => onMessage?.call("Sunucu yanıt vermiyor. Bağlantı kesildi.", true),
      );
      return null;
    } catch (e) {
      await _guvenliBaglantiSifirla();
      Future.microtask(() => onMessage?.call("Bağlantı Hatası: $e", true));
      return null;
    }
  }

  /// MySQL Bağlantısını Akıllı Reconnect ile Yönet
  Future<bool> baglan({
    bool manuelBaslatma = false,
    Function(String mesaj, bool hata)? onMessage,
  }) async {
    try {
      if (!manuelBaslatma && _conn == null) return false;

      // Canlılık Kontrolü (Ping)
      if (_conn != null && _conn!.connected) {
        try {
          await _conn!.execute("SELECT 1").timeout(const Duration(seconds: 1));
          _sonIslemZamani = DateTime.now(); // Canlıysa süreyi sıfırla
          return true;
        } catch (_) {
          _conn = null;
        }
      }

      onMessage?.call("Bağlantı kuruluyor...", false);

      // Hard Reset
      if (_conn != null) {
        _conn!.close().timeout(
          const Duration(milliseconds: 300),
          onTimeout: () => null,
        );
        _conn = null;
      }

      // Ayarları veritabanından çek
      var ayarlar = await DbHelper().sabitAyarlariGetir();
      String host = ayarlar?['OC_HOST']?.toString().trim() ?? '';
      int port = ayarlar?['OC_PORT'] ?? 3306;
      String dbName = ayarlar?['OC_DB']?.toString().trim() ?? '';
      String userName = ayarlar?['OC_USER']?.toString().trim() ?? '';
      String password = ayarlar?['OC_PASS']?.toString().trim() ?? '';

      if (host.isEmpty || dbName.isEmpty || userName.isEmpty) {
        onMessage?.call("OpenCart sunucu ayarları eksik! Lütfen Ayarlar sekmesini doldurun.", true);
        return false;
      }

      _conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: dbName,
        secure: false, // <-- SSL hatalarını önlemek için eklendi
      );

      await _conn!.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _conn = null;
          throw TimeoutException("Zaman aşımı.");
        },
      );

      if (_conn?.connected ?? false) {
        _sonIslemZamani = DateTime.now(); // Sayacı yeni bağlantıyla başlat
        onMessage?.call("Bağlantı başarıyla kuruldu.", false);
        return true;
      }
      return false;
    } catch (e) {
      _conn = null;
      _sonIslemZamani = null;
      onMessage?.call("Bağlantı Hatası: $e", true);
      print("Flutter MySQL Detaylı Hata: $e");
      return false;
    }
  }

  /// Ürün OpenCart'ta var mı kontrol et
  Future<String?> urunIdSorgula(String stokKodu) async {
    if (!isConnected) return null;
    try {
      var result = await _conn!
          .execute(
            "SELECT product_id FROM oc_product WHERE LOWER(model) = LOWER(:model) LIMIT 1",
            {"model": stokKodu.trim()},
          )
          .timeout(const Duration(seconds: 3));

      _sonIslemZamani = DateTime.now(); // Her başarılı işlemde sayacı güncelle
      if (result.rows.isEmpty) return null;
      return result.rows.first.assoc()['product_id']?.toString();
    } catch (e) {
      _conn = null;
      return null;
    }
  }

  /// Ürün Durum Güncelleme
  Future<bool> urunDurumGuncelle(String productId, String status) async {
    if (!isConnected) return false;
    try {
      await _conn!
          .execute(
            "UPDATE oc_product SET status = :status WHERE product_id = :id",
            {"status": status, "id": productId},
          )
          .timeout(const Duration(seconds: 3));

      _sonIslemZamani = DateTime.now();
      return true;
    } catch (e) {
      _conn = null;
      return false;
    }
  }

  Future<bool> urunEkle({
    required String model,
    required String ad,
    required String barkod,
    required double fiyat,
    required String taxClassId,
    required int miktar,
    required String weight,
    required String aciklama,
    required String metaTitle,
    required String metaDescription,
    required String metaKeyword,
    required String seoUrl,
    String? image,
    String? marka,
    String kategoriId = "0",
    String minimum = "3",
    Function(String mesaj, bool hata)? onMessage, // Mesaj desteği eklendi
  }) async {
    // 1. UI Nefes Alma: Büyük veri girişinden önce arayüzü rahatlat
    await Future.delayed(const Duration(milliseconds: 20));

    // 2. Zaman Bariyeri: 7 dakika kontrolü
    if (_sonIslemZamani != null &&
        DateTime.now().difference(_sonIslemZamani!).inSeconds > 420) {
      _conn = null;
      Future.microtask(
        () => onMessage?.call(
          "Oturum süresi doldu, lütfen tekrar bağlanın.",
          true,
        ),
      );
      return false;
    }

    if (!isConnected) {
      onMessage?.call("Bağlantı aktif değil!", true);
      return false;
    }

    bool transactionStarted = false;
    try {
      final simdi = DateTime.now().toString().split('.')[0];
      await _conn!.execute('START TRANSACTION');
      transactionStarted = true;
      String tamResimYolu = "catalog/${(image ?? "").replaceAll('\\', '/')}";
      // 🔥 KDV KORUMASI: Boş, null veya geçersiz gelirse otomatik "100" yapıyoruz
      // KDV Koruma ve Temizleme Mantığı
      String guvenliTaxClassId =
          (taxClassId.trim().isEmpty || taxClassId == "0")
          ? "100"
          : taxClassId.trim();

      var res = await _conn!
          .execute(
            "INSERT INTO oc_product (model, ean, sku, status, quantity, price, image, minimum, weight, tax_class_id, date_added, date_modified, stock_status_id) "
            "VALUES (:model, :ean, :sku, '1', :qty, :price, :image, :minimum, :weight, :taxId, :d_add, :d_mod, '7')",
            {
              "model": model,
              "ean": barkod,
              "sku": barkod,
              "qty": miktar,
              "price": fiyat,
              "image": tamResimYolu,
              "minimum": minimum,
              "weight": weight,
              "taxId": guvenliTaxClassId, // Sorgudaki :taxId ile tam eşleşti
              "d_add": simdi,
              "d_mod": simdi,
            },
          )
          .timeout(const Duration(seconds: 5));

      String newId = res.lastInsertID.toString();

      await _conn!.execute(
        "INSERT INTO oc_product_description (product_id, language_id, name, description, meta_title, meta_description, meta_keyword) "
        "VALUES (:pid, 2, :name, :desc, :metaT, :metaD, :metaK)",
        {
          "pid": newId,
          "name": ad,
          "desc": aciklama,
          "metaT": metaTitle,
          "metaD": metaDescription,
          "metaK": metaKeyword,
        },
      );

      // Yan tabloları eklerken UI'ı bloklamamak için küçük esler
      await Future.delayed(const Duration(milliseconds: 5));
      await _seoAyarla(newId, ad, model);

      await _conn!.execute(
        "INSERT INTO oc_product_to_store (product_id, store_id) VALUES (:pid, 0)",
        {"pid": newId},
      );

      if (kategoriId != "0") {
        await _conn!.execute(
          "INSERT INTO oc_product_to_category (product_id, category_id) VALUES (:pid, :cid)",
          {"pid": newId, "cid": kategoriId},
        );
      }

      await _conn!.execute('COMMIT');
      _sonIslemZamani = DateTime.now(); // İşlem başarılı, zamanı güncelle
      return true;
    } catch (e) {
      if (transactionStarted) {
        try {
          await _conn?.execute('ROLLBACK');
        } catch (_) {
          // The server rolls back an uncommitted transaction after disconnect.
        }
      }
      await _guvenliBaglantiSifirla();
      Future.microtask(() => onMessage?.call("Ekleme Hatası: $e", true));
      return false;
    }
  }

  /// Mevcut Ürünü Güncelle
  Future<bool> urunGuncelle({
    required String productId,
    required double fiyat,
    required String taxClassId,
    required int miktar,
    required String ad,
    required String barkod,
    required String aciklama,
    String? marka,
    String? image,
    String? minimum,
    String? weight,
    required String sonGuncelleme,
    required String metaTitle,
    required String metaDescription,
    required String metaKeyword,
    required String seoUrl,
    Function(String mesaj, bool hata)? onMessage, // Mesaj desteği eklendi
  }) async {
    // 1. UI Nefes Alma[cite: 1]
    await Future.delayed(const Duration(milliseconds: 15));

    // 2. Zaman Bariyeri Kontrolü[cite: 1]
    if (_sonIslemZamani != null &&
        DateTime.now().difference(_sonIslemZamani!).inSeconds > 420) {
      await _guvenliBaglantiSifirla();
      return false;
    }

    if (!isConnected) return false;

    bool transactionStarted = false;
    try {
      final bool hasImage = (image != null && image.isNotEmpty);
      // 🔥 KDV KORUMASI: Güncellerken de boşluk/null durumunda "100" basıyoruz
      String guvenliTaxClassId =
          (taxClassId.trim().isEmpty || taxClassId == "0")
          ? "100"
          : taxClassId.trim();

      await _conn!.execute('START TRANSACTION');
      transactionStarted = true;
      
      final String sql = hasImage
          ? "UPDATE oc_product SET ean = :ean, price = :price, quantity = :qty, tax_class_id = :taxId, image = :img, minimum = :minimum, weight = :weight, date_modified = :d_mod WHERE product_id = :pid"
          : "UPDATE oc_product SET ean = :ean, price = :price, quantity = :qty, tax_class_id = :taxId, minimum = :minimum, weight = :weight, date_modified = :d_mod WHERE product_id = :pid";

      final Map<String, dynamic> params = {
        "pid": productId,
        "ean": barkod,
        "price": fiyat,
        "qty": miktar,
        "taxId": guvenliTaxClassId,
        "minimum": minimum ?? "3",
        "weight": weight ?? "0",
        "d_mod": sonGuncelleme,
      };
      if (hasImage) {
        params["img"] = "catalog/${image.replaceAll('\\', '/')}";
      }

      await _conn!.execute(sql, params).timeout(const Duration(seconds: 5));

      await _conn!.execute(
        "UPDATE oc_product_description SET name = :name, description = :desc, meta_title = :metaT, meta_description = :metaD, meta_keyword = :metaK "
        "WHERE product_id = :pid AND language_id = 2",
        {
          "pid": productId,
          "name": ad,
          "desc": aciklama,
          "metaT": metaTitle,
          "metaD": metaDescription,
          "metaK": metaKeyword,
        },
      );

      await _seoAyarla(productId, ad, barkod);

      await _conn!.execute('COMMIT');
      _sonIslemZamani = DateTime.now(); //[cite: 1]
      return true;
    } catch (e) {
      if (transactionStarted) {
        try {
          await _conn?.execute('ROLLBACK');
        } catch (_) {
          // The server rolls back an uncommitted transaction after disconnect.
        }
      }
      await _guvenliBaglantiSifirla();
      Future.microtask(() => onMessage?.call("Güncelleme Hatası: $e", true));
      return false;
    }
  }

  Future<bool> urunSil(String productId) async {
    if (!isConnected) return false;
    bool transactionStarted = false;
    try {
      List<String> sqlSorgulari = [
        "DELETE FROM oc_product WHERE product_id = :pid",
        "DELETE FROM oc_product_attribute WHERE product_id = :pid",
        "DELETE FROM oc_product_description WHERE product_id = :pid",
        "DELETE FROM oc_product_discount WHERE product_id = :pid",
        "DELETE FROM oc_product_filter WHERE product_id = :pid",
        "DELETE FROM oc_product_image WHERE product_id = :pid",
        "DELETE FROM oc_product_option WHERE product_id = :pid",
        "DELETE FROM oc_product_option_value WHERE product_id = :pid",
        "DELETE FROM oc_product_recurring WHERE product_id = :pid",
        "DELETE FROM oc_product_related WHERE product_id = :pid",
        "DELETE FROM oc_product_reward WHERE product_id = :pid",
        "DELETE FROM oc_product_special WHERE product_id = :pid",
        "DELETE FROM oc_product_to_category WHERE product_id = :pid",
        "DELETE FROM oc_product_to_download WHERE product_id = :pid",
        "DELETE FROM oc_product_to_layout WHERE product_id = :pid",
        "DELETE FROM oc_product_to_store WHERE product_id = :pid",
        "DELETE FROM oc_review WHERE product_id = :pid",
        "DELETE FROM oc_seo_url WHERE query = :query",
        "DELETE FROM oc_coupon_product WHERE product_id = :pid",
      ];

      await _conn!.execute('START TRANSACTION');
      transactionStarted = true;
      for (var sorgu in sqlSorgulari) {
        if (sorgu.contains("oc_seo_url")) {
          await _conn!.execute(sorgu, {"query": "product_id=$productId"});
        } else {
          await _conn!.execute(sorgu, {"pid": productId});
        }
        await Future.delayed(const Duration(milliseconds: 2)); // UI Nefes Alma (Yield)
      }

      await _conn!.execute('COMMIT');
      _sonIslemZamani = DateTime.now();
      return true;
    } catch (e) {
      if (transactionStarted) {
        try {
          await _conn?.execute('ROLLBACK');
        } catch (_) {
          // The server rolls back an uncommitted transaction after disconnect.
        }
      }
      debugPrint("Silme Hatası: $e");
      return false;
    }
  }

  Future<void> _seoAyarla(String productId, String ad, String model) async {
    String seoText = StringUtils.toSeoUrl("$ad $model");
    try {
      await _conn!.execute(
        "DELETE FROM oc_seo_url WHERE query = :query",
        {"query": "product_id=$productId"},
      );
      
      await _conn!.execute(
        "INSERT INTO oc_seo_url (store_id, language_id, query, keyword) VALUES (0, 2, :query, :keyword)",
        {"query": "product_id=$productId", "keyword": seoText},
      );
    } catch (e) {
      debugPrint("SEO Ayarlama Hatası: $e");
    }
  }

  Future<void> kapat({Function(String mesaj, bool hata)? onMessage}) async {
    try {
      if (_conn != null && _conn!.connected) {
        await _conn!.close().timeout(const Duration(seconds: 2));
        onMessage?.call("Bağlantı kapatıldı.", false);
      }
    } catch (e) {
      onMessage?.call("Hata: $e", true);
    } finally {
      _conn = null;
      _sonIslemZamani = null;
    }
  }
}
