import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/db_helper.dart';
import '../services/opencart_service.dart';
import 'stock_form_controller.dart';
import 'settings_controller.dart';
import '../utils/ui_utils.dart';
import '../utils/string_utils.dart';

class OpenCartController extends GetxController {
  final OpenCartService _ocService = OpenCartService();
  OpenCartService get ocService => _ocService;
  final StockFormController _stockFormController =
      Get.find<StockFormController>();
  final SettingsController _settingsController = Get.find<SettingsController>();

  var isOcConnected = false.obs;
  var ocData = <String, dynamic>{}.obs;
  var ocProductId = Rxn<String>();
  var autoSync = false.obs;
  Timer? _secimDebounceTimer;

  @override
  void onClose() {
    _secimDebounceTimer?.cancel();
    super.onClose();
  }

  Future<void> disconnect() async {
    await _ocService.kapat();
    isOcConnected.value = false;
    ocProductId.value = null;
    ocData.clear();
  }

  Future<void> connect(String kod) async {
    isOcConnected.value = false;
    ocProductId.value = null;
    ocData.clear();

    if (_settingsController.c['oc_host']!.text.isEmpty ||
        _settingsController.c['oc_user']!.text.isEmpty ||
        _settingsController.c['oc_pass']!.text.isEmpty) {
      return;
    }

    try {
      bool baglantiVarMi = await _ocService.baglan(manuelBaslatma: true);
      isOcConnected.value = baglantiVarMi;

      if (baglantiVarMi) {
        final id = await _ocService.urunIdSorgula(kod);
        if (id != null) {
          final detay = await _ocService.urunDetayGetir(id);
          if (detay != null) {
            ocData.value = detay;
            ocProductId.value = id;
            _seoVeETicaretBilgileriniDoldur(detay);
          } else {
            _seoVeETicaretBilgileriniDoldur(null);
          }
        } else {
          ocData.clear();
          ocProductId.value = null;
          _seoVeETicaretBilgileriniDoldur(null);
        }
      }
    } catch (e) {
      isOcConnected.value = false;
      ocProductId.value = null;
      Get.snackbar(
        'Bağlantı Hatası',
        'OpenCart sunucusuna bağlanılamadı: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchDataIfConnected(String kod) async {
    if (!isOcConnected.value) return;

    ocProductId.value = null;
    ocData.clear();

    try {
      final id = await _ocService.urunIdSorgula(kod);
      if (id != null) {
        final detay = await _ocService.urunDetayGetir(id);
        if (detay != null) {
          ocData.value = detay;
          ocProductId.value = id;
          _seoVeETicaretBilgileriniDoldur(detay);
        } else {
          _seoVeETicaretBilgileriniDoldur(null);
        }
      } else {
        _seoVeETicaretBilgileriniDoldur(null);
      }
    } catch (e) {
      Get.snackbar('Veri Hatası', 'Ürün verisi çekilirken hata oluştu: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _seoVeETicaretBilgileriniDoldur(Map<String, dynamic>? detay) {
    final stokAdi = _stockFormController.c['stok_adi']?.text.trim() ?? '';
    final barkod = _stockFormController.c['barkod']?.text.trim() ?? '';

    if (detay != null) {
      final mTitle = detay['meta_title']?.toString().trim();
      final mDesc = detay['meta_description']?.toString().trim();
      final mKey = detay['meta_keyword']?.toString().trim();
      final seoUrl = detay['seo_url']?.toString().trim();
      final aciklama = detay['description']?.toString().trim();

      if (mTitle != null && mTitle.isNotEmpty) {
        _stockFormController.c['metaTitle']?.text = mTitle;
      } else if (stokAdi.isNotEmpty) {
        _stockFormController.c['metaTitle']?.text = "$stokAdi - En Uygun Fiyatlar";
      }

      if (mDesc != null && mDesc.isNotEmpty) {
        _stockFormController.c['metaDescription']?.text = mDesc;
      } else if (aciklama != null && aciklama.isNotEmpty) {
        String duzMetin = aciklama.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
        _stockFormController.c['metaDescription']?.text =
            duzMetin.length > 157 ? "${duzMetin.substring(0, 157)}..." : duzMetin;
      } else {
        _stockFormController.c['metaDescription']?.text =
            "En uygun fiyatlar, toptan bebek giyim. Kaliteli bebek giyim ürünleri burada!";
      }

      if (mKey != null && mKey.isNotEmpty) {
        _stockFormController.c['metaKeyword']?.text = mKey;
      } else {
        _stockFormController.c['metaKeyword']?.text =
            "Toptan Fiyat, Bebe takım, baby wear, bebe body, zıbın, Toptan bebe giyim, tulum, çorap, Uygun fiyat, battaniye, Barkod: $barkod";
      }

      if (seoUrl != null && seoUrl.isNotEmpty) {
        _stockFormController.c['seoUrl']?.text = seoUrl;
      } else if (stokAdi.isNotEmpty) {
        _stockFormController.c['seoUrl']?.text = StringUtils.toSeoUrl(stokAdi);
      }

      if (aciklama != null && aciklama.isNotEmpty) {
        _stockFormController.c['aciklama']?.text = aciklama;
      }
    } else {
      _stockFormController.metaHazirla();
    }
  }

  void seciliUrunuYukleGecikmeli({
    required bool autoSync,
  }) {
    _secimDebounceTimer?.cancel();
    _secimDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      seciliUrunuYukle(autoSync: autoSync);
    });
  }

  Future<void> seciliUrunuYukle({
    required bool autoSync,
  }) async {
    final stok = _stockFormController.seciliStok.value;
    final stokKodu = stok?.stokKod;

    if (!isOcConnected.value || stokKodu == null || stokKodu.isEmpty) {
      return;
    }

    await fetchDataIfConnected(stokKodu);
    await _weblinkKontrolVeGuncelle();
    await _autoSyncKontrol(autoSync);
  }

  Future<void> _weblinkKontrolVeGuncelle() async {
    final productId = ocProductId.value;
    final stok = _stockFormController.seciliStok.value;
    if (productId == null || stok?.id == null) return;

    final dogruLink =
        'https://www.koksalbebe.com.tr/index.php?route=product/product&product_id=$productId';
    final mevcutLink = _stockFormController.c['webLink']?.text.trim() ?? '';
    if (mevcutLink == dogruLink) return;

    _stockFormController.c['webLink']?.text = dogruLink;
    try {
      final db = await DbHelper().db;
      await db.update(
        'STOK',
        {'WebLink': dogruLink},
        where: 'KIMLIK = ?',
        whereArgs: [stok!.id],
      );
      stok.webLink = dogruLink;
    } catch (e) {
      debugPrint('WebLink otomatik güncelleme hatası: $e');
    }
  }

  Future<void> _autoSyncKontrol(
    bool autoSync,
  ) async {
    if (!autoSync || ocProductId.value == null || ocData.isEmpty) return;

    final ocPrice = double.tryParse(ocData['price']?.toString() ?? '0') ?? 0;
    final localPrice =
        double.tryParse(
          _stockFormController.c['satis']?.text.replaceAll(',', '.') ?? '0',
        ) ??
        0;
    final ocQty = int.tryParse(ocData['quantity']?.toString() ?? '0') ?? 0;
    final localQty =
        int.tryParse(_stockFormController.c['miktar']?.text ?? '0') ?? 0;
    final ocEan = ocData['ean']?.toString().trim() ?? '';
    final localEan = _stockFormController.c['barkod']?.text.trim() ?? '';
    final ocName = ocData['name']?.toString().trim() ?? '';
    final localName = _stockFormController.c['stok_adi']?.text.trim() ?? '';

    final farkVar =
        (ocPrice - localPrice).abs() > 0.01 ||
        ocQty != localQty ||
        ocEan != localEan ||
        ocName != localName;
    if (!farkVar) return;

    UiUtils.showMessage('Farklılık tespit edildi, OC3 otomatik güncelleniyor...');
    await senkronizeEt();
  }

  Future<void> getUrunDetay(String pid) async {
    final detay = await _ocService.urunDetayGetir(pid);
    if (detay != null) {
      ocData.value = detay;
      ocProductId.value = pid;
    }
  }

  void gorselSeoHazirla(String ad) {
    String gecici = ad
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .toLowerCase();
    String seoUrl = gecici
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    _stockFormController.c['seoUrl']?.text = seoUrl;
  }

  void metaHazirla() {
    String mTitle = _stockFormController.c['metaTitle']?.text ?? '';
    String ad = _stockFormController.c['stok_adi']?.text ?? '';
    String stokKod = _stockFormController.c['stok_kod']?.text ?? '';

    if (mTitle.isEmpty) {
      _stockFormController.c['metaTitle']?.text = ad;
    }
    if (_stockFormController.c['metaDescription']?.text.isEmpty ?? true) {
      String desc = "$ad - $stokKod";
      _stockFormController.c['metaDescription']?.text = desc;
    }
    if (_stockFormController.c['metaKeyword']?.text.isEmpty ?? true) {
      _stockFormController.c['metaKeyword']?.text =
          "Toptan Fiyat, Bebe takım, yenidoğan, erkek bebek, kız bebek";
    }
    if (_stockFormController.c['seoUrl']?.text.isEmpty ?? true) {
      gorselSeoHazirla(ad);
    }
  }

  Future<void> senkronizeEt() async {
    metaHazirla();

    bool basarili = false;
    String tamAd = _stockFormController.c['stok_adi']?.text ?? "";
    String marka = tamAd.trim().split(' ').first;
    if (marka.isEmpty) marka = "genel";
    String kod = _stockFormController.c['stok_kod']?.text ?? "";
    String resimAdi = "$marka/$kod.jpeg";
    String ad = _stockFormController.c['stok_adi']?.text ?? "";
    String barkod = _stockFormController.c['barkod']?.text ?? "";

    double fiyat =
        double.tryParse(
          _stockFormController.c['satis']?.text.replaceAll(',', '.') ?? '0',
        ) ??
        0;
    int miktar =
        int.tryParse(_stockFormController.c['miktar']?.text ?? '0') ?? 0;
    String kdv = _stockFormController.c['kdv']?.text ?? "10";
    String lot = _stockFormController.c['lot']?.text ?? "3";
    double agirlik =
        double.tryParse(
          _stockFormController.c['weight']?.text.replaceAll(',', '.') ?? '0',
        ) ??
        0;
    String urunAciklama = _stockFormController.c['aciklama']?.text ?? "";

    String mTitle = _stockFormController.c['metaTitle']?.text ?? '';
    String mDesc = _stockFormController.c['metaDescription']?.text ?? '';
    String mKeyword = _stockFormController.c['metaKeyword']?.text ?? '';
    String seoUrl = _stockFormController.c['seoUrl']?.text ?? '';

    if (ocProductId.value == null) {
      UiUtils.showMessage("Yeni ürün OpenCart'a yükleniyor...");
      basarili = await _ocService.urunEkle(
        model: kod,
        ad: ad,
        barkod: barkod,
        fiyat: fiyat,
        miktar: miktar,
        taxClassId: kdv,
        minimum: lot,
        weight: agirlik.toString(),
        aciklama: urunAciklama,
        metaTitle: mTitle,
        metaDescription: mDesc,
        metaKeyword: mKeyword,
        seoUrl: seoUrl,
        marka: marka,
        image: resimAdi,
      );

      if (basarili) {
        UiUtils.showMessage("Ürün başarıyla OpenCart'a EKLENDİ!");
        ocData.clear();
        Future.delayed(const Duration(milliseconds: 100), () {
          connect(kod);
        });
      } else {
        UiUtils.showMessage("Ürün eklenemedi!", hata: true);
      }
    } else {
      UiUtils.showMessage("Mevcut ürün güncelleniyor (ID: ${ocProductId.value})...");
      basarili = await _ocService.urunGuncelle(
        productId: ocProductId.value!,
        ad: ad,
        barkod: barkod,
        fiyat: fiyat,
        miktar: miktar,
        taxClassId: kdv,
        minimum: lot,
        weight: agirlik.toString(),
        aciklama: urunAciklama,
        metaTitle: mTitle,
        metaDescription: mDesc,
        metaKeyword: mKeyword,
        seoUrl: seoUrl,
        marka: marka,
        image: resimAdi,
        sonGuncelleme: DateTime.now().toString().split('.')[0],
      );
      if (basarili) {
        UiUtils.showMessage("Ürün başarıyla güncellendi!");
        Future.delayed(const Duration(milliseconds: 100), () {
          connect(kod);
        });
      } else {
        UiUtils.showMessage("Ürün güncellenemedi!", hata: true);
      }
    }
  }

  Future<void> durumDegistir() async {
    if (ocProductId.value == null) {
      UiUtils.showMessage("Bu ürün OpenCart'ta bulunmuyor!", hata: true);
      return;
    }

    String suankiDurum = ocData['status']?.toString() ?? "1";
    String yeniDurum = suankiDurum == "1" ? "0" : "1";

    bool basarili = await _ocService.urunDurumGuncelle(
      ocProductId.value!,
      yeniDurum,
    );

    if (basarili) {
      ocData['status'] = yeniDurum;
      ocData.refresh(); // Reactive update
      UiUtils.showMessage(
        yeniDurum == "1" ? "Ürün yayına alındı!" : "Ürün yayından kaldırıldı!",
      );
    } else {
      UiUtils.showMessage("Ürün durumu değiştirilemedi!", hata: true);
    }
  }

  Future<void> urunSil() async {
    if (ocProductId.value == null) {
      UiUtils.showMessage("OpenCart tarafında silinecek ürün bulunamadı!");
      return;
    }

    bool basarili = await _ocService.urunSil(ocProductId.value!);
    if (basarili) {
      UiUtils.showMessage("Ürün OpenCart'tan silindi!");
      ocProductId.value = null;
      ocData.clear();
    } else {
      UiUtils.showMessage("Ürün silinemedi!", hata: true);
    }
  }
}
