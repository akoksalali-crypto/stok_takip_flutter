import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stok_model.dart';
import '../services/db_helper.dart';
import 'stock_list_controller.dart';
import 'settings_controller.dart' as import_settings;
import 'opencart_controller.dart' as import_opencart;
import '../utils/string_utils.dart';
import '../utils/ui_utils.dart';
import '../utils/barcode_utils.dart';

class StockFormController extends GetxController {
  final Rx<Stok?> seciliStok = Rx<Stok?>(null);
  final FocusNode stokKodFocusNode = FocusNode();

  final TextEditingController adetController = TextEditingController(text: "1");
  RxString basilacakBarkodKey = 'barkod'.obs; // Varsayılan olarak ana barkod

  final Map<String, TextEditingController> c = {
    'stok_kod': TextEditingController(),
    'stok_adi': TextEditingController(),
    'barkod': TextEditingController(),
    'barkod2': TextEditingController(),
    'barkod3': TextEditingController(),
    'barkod4': TextEditingController(),
    'barkod5': TextEditingController(),
    'barkod6': TextEditingController(),
    'barkod7': TextEditingController(),
    'alis': TextEditingController(),
    'satis': TextEditingController(),
    'dolar_alis': TextEditingController(),
    'dolar_satis': TextEditingController(),
    'euro_satis': TextEditingController(),
    'miktar': TextEditingController(),
    'marj': TextEditingController(),
    'kdv': TextEditingController(),
    'min_adet': TextEditingController(),
    'lot': TextEditingController(),
    'weight': TextEditingController(),
    'metaTitle': TextEditingController(),
    'metaDescription': TextEditingController(),
    'metaKeyword': TextEditingController(),
    'seoUrl': TextEditingController(),
    'webLink': TextEditingController(),
    'Fdate': TextEditingController(),
    'Ldate': TextEditingController(),
    'beden': TextEditingController(),
    'image': TextEditingController(),
    'aciklama': TextEditingController(),
  };

  void fiyatHesapla() {
    final settingsController =
        Get.isRegistered<import_settings.SettingsController>()
            ? Get.find<import_settings.SettingsController>()
            : null;

    double dolarAlis = double.tryParse(
          c['dolar_alis']?.text.replaceAll(',', '.').trim() ?? '0',
        ) ??
        0;
    double marj = double.tryParse(
          c['marj']?.text.replaceAll(',', '.').trim() ?? '0',
        ) ??
        0;

    // Senaryo A: Dolar Alış girilmiş veya mevcut (dolar_alis > 0) -> Canlı Kur ile Hesaplama
    if (dolarAlis > 0) {
      double kurDolar = 0;
      double kurEuro = 0;
      if (settingsController != null) {
        kurDolar = double.tryParse(
              settingsController.c['kur_dolar']?.text
                      .replaceAll(',', '.')
                      .trim() ??
                  '0',
            ) ??
            0;
        kurEuro = double.tryParse(
              settingsController.c['kur_euro']?.text
                      .replaceAll(',', '.')
                      .trim() ??
                  '0',
            ) ??
            0;
      }

      if (kurDolar > 0) {
        // 1. TL Alış = Dolar Alış * Canlı Dolar Kuru
        double alis = dolarAlis * kurDolar;
        c['alis']?.text = alis.toStringAsFixed(2);

        // 2. TL Satış = TL Alış + (TL Alış * Marj / 100) -> Yukarı Yuvarla (Ceil)
        double sonSatis = (alis + (alis * marj / 100)).ceil().toDouble();
        c['satis']?.text = sonSatis.toStringAsFixed(2);

        // 3. Dolar Satış = TL Satış / Canlı Dolar Kuru
        double dolarSatis = sonSatis / kurDolar;
        c['dolar_satis']?.text = dolarSatis.toStringAsFixed(2);

        // 4. Euro Satış = TL Satış / Canlı Euro Kuru
        if (kurEuro > 0) {
          double euroSatis = sonSatis / kurEuro;
          c['euro_satis']?.text = euroSatis.toStringAsFixed(2);
        }
      }
    } else {
      // Senaryo B: Dolar Alış Boş veya 0 -> TL Alış ve Sabit Kur ile Hesaplama
      double alis = double.tryParse(
            c['alis']?.text.replaceAll(',', '.').trim() ?? '0',
          ) ??
          0;

      if (alis > 0) {
        // 1. TL Satış = TL Alış + (TL Alış * Marj / 100) -> Yukarı Yuvarla (Ceil)
        double sonSatis = (alis + (alis * marj / 100)).ceil().toDouble();
        c['satis']?.text = sonSatis.toStringAsFixed(2);

        // Sabit kurlar üzerinden Dolar ve Euro satış hesaplama
        if (settingsController != null) {
          double sabitDolar = double.tryParse(
                settingsController.c['sabit_dolar']?.text
                        .replaceAll(',', '.')
                        .trim() ??
                    '0',
              ) ??
              0;
          double sabitEuro = double.tryParse(
                settingsController.c['sabit_euro']?.text
                        .replaceAll(',', '.')
                        .trim() ??
                    '0',
              ) ??
              0;

          if (sabitDolar > 0) {
            double dolarSatis = sonSatis / sabitDolar;
            c['dolar_satis']?.text = dolarSatis.toStringAsFixed(2);
          }

          if (sabitEuro > 0) {
            double euroSatis = sonSatis / sabitEuro;
            c['euro_satis']?.text = euroSatis.toStringAsFixed(2);
          }
        }
      }
    }
  }

  void formuTemizle() {
    seciliStok.value = null;
    for (var controller in c.values) {
      controller.clear();
    }
    adetController.text = "1";
    // Default values
    c['marj']?.text = "30";
    c['kdv']?.text = "10";
    c['lot']?.text = "3";
    c['miktar']?.text = "100";
    String bugun = DateTime.now().toString().split(' ')[0];
    c['Fdate']?.text = bugun;
    c['Ldate']?.text = bugun;
    c['image']?.text = "";
    c['webLink']?.text = "";
  }

  void formuDoldur(Stok urun) {
    seciliStok.value = urun;
    c['stok_kod']!.text = urun.stokKod ?? "";
    c['stok_adi']!.text = urun.stokAdi;
    c['barkod']!.text = urun.barkod;
    c['barkod2']!.text = urun.barkod2 ?? "";
    c['barkod3']!.text = urun.barkod3 ?? "";
    c['barkod4']!.text = urun.barkod4 ?? "";
    c['barkod5']!.text = urun.barkod5 ?? "";
    c['barkod6']!.text = urun.barkod6 ?? "";
    c['barkod7']!.text = urun.barkod7 ?? "";
    c['alis']!.text = urun.alisFiyati ?? "";
    c['satis']!.text = urun.satisFiyati ?? "";
    c['dolar_alis']!.text = urun.dolarAlis ?? "";
    c['dolar_satis']!.text = urun.dolarSatis ?? "";
    c['euro_satis']!.text = urun.euroSatis ?? "";
    c['miktar']!.text = urun.miktar ?? "";
    c['marj']!.text = urun.marj ?? "";
    c['kdv']!.text = urun.kdv ?? "";
    c['weight']!.text = urun.weight ?? "";
    c['lot']!.text = urun.lot ?? "";
    c['metaTitle']!.text = urun.metaTitle ?? "";
    c['metaDescription']!.text = "";
    c['metaKeyword']!.text = "";
    c['seoUrl']!.text = "";
    c['webLink']!.text = urun.webLink ?? "";
    c['Fdate']!.text = urun.Fdate ?? "";
    c['Ldate']!.text = urun.Ldate ?? "";
    c['beden']!.text = urun.beden ?? "";
    c['image']!.text = urun.image ?? "";
  }

  String? kopyaOlarakHazirla() {
    if (seciliStok.value == null) return null;

    final ad = c['stok_adi']?.text.trim() ?? '';
    final eskiKod = c['stok_kod']?.text.trim() ?? '';
    final yeniKod = '${eskiKod.split('-').first}-KOPYA';
    final marka = ad.trim().isEmpty ? 'Genel' : ad.trim().split(' ').first;
    final bugun = DateTime.now().toString().split(' ')[0];

    seciliStok.value = Stok(
      id: null,
      stokKod: yeniKod,
      stokAdi: ad,
      barkod: '',
      Fdate: bugun,
      Ldate: bugun,
    );
    c['stok_kod']?.text = yeniKod;
    c['barkod']?.clear();
    c['Fdate']?.text = bugun;
    c['Ldate']?.text = bugun;
    c['image']?.text = '$marka\\${yeniKod.trim().toUpperCase()}.jpeg';
    metaHazirla();
    return yeniKod;
  }

  Future<void> stokKaydet(Function(Stok) onUrunSec) async {
    if (c['stok_adi']!.text.trim().isEmpty) {
      UiUtils.showMessage("Hata: Stok adı boş bırakılamaz!", hata: true);
      return;
    }

    String ad = c['stok_adi']!.text.trim();
    String kod = c['stok_kod']!.text.trim();

    if (kod.isEmpty) {
      if (c['barkod']!.text.trim().isNotEmpty) {
        c['stok_kod']!.text = c['barkod']!.text.trim();
      } else {
        c['stok_kod']!.text = "KOD-${DateTime.now().millisecondsSinceEpoch}";
      }
      kod = c['stok_kod']!.text;
    }

    String bugun = DateTime.now().toString().split(' ')[0];
    if (c['marj']!.text.isEmpty) c['marj']!.text = "30";
    if (c['kdv']!.text.isEmpty) c['kdv']!.text = "10";
    if (c['lot']!.text.isEmpty) c['lot']!.text = "3";
    if (c['miktar']!.text.isEmpty) c['miktar']!.text = "100";
    if (c['Fdate']!.text.isEmpty) c['Fdate']!.text = bugun;
    if (c['Ldate']!.text.isEmpty) c['Ldate']!.text = bugun;

    String nihaiResimYolu = yerelYolOlustur(ad, kod);
    c['image']?.text = nihaiResimYolu;

    Stok urun = Stok(
      id: seciliStok.value?.id,
      stokKod: kod,
      stokAdi: ad,
      barkod: c['barkod']!.text,
      barkod2: c['barkod2']!.text,
      barkod3: c['barkod3']!.text,
      barkod4: c['barkod4']!.text,
      barkod5: c['barkod5']!.text,
      barkod6: c['barkod6']!.text,
      barkod7: c['barkod7']!.text,
      alisFiyati: c['alis']!.text,
      satisFiyati: c['satis']!.text,
      dolarAlis: c['dolar_alis']!.text,
      dolarSatis: c['dolar_satis']!.text,
      euroSatis: c['euro_satis']!.text,
      miktar: c['miktar']!.text,
      marj: c['marj']!.text,
      kdv: c['kdv']!.text,
      weight: c['weight']!.text,
      lot: c['lot']!.text,
      metaTitle: (c['metaTitle']?.text.isEmpty ?? true) ? ad : c['metaTitle']!.text,
      webLink: c['webLink']!.text,
      Fdate: c['Fdate']!.text,
      Ldate: c['Ldate']!.text,
      beden: c['beden']!.text,
      image: nihaiResimYolu,
    );

    final row = urun.toMap();
    final dbHelper = DbHelper();
    final stockListController = Get.find<StockListController>();

    try {
      if (seciliStok.value?.id == null) {
        await dbHelper.insertStok(row);
        UiUtils.showMessage("Yeni Ürün Başarıyla Kaydedildi");
      } else {
        await dbHelper.updateStok(row, seciliStok.value!.id!);
        UiUtils.showMessage("Ürün Başarıyla Güncellendi");
      }

      await stockListController.verileriGetir();

      Future.delayed(const Duration(milliseconds: 100), () {
        stockListController.aramaYap(stockListController.aramaController.text, onTekSonuc: onUrunSec);
      });
    } catch (e) {
      UiUtils.showMessage("Veritabanı hatası: $e", hata: true);
    }
  }

  String yerelYolOlustur(String ad, String kod) {
    String marka = ad.trim().split(' ').first;
    if (marka.isEmpty) marka = "genel";
    String temizKod = StringUtils.temizleDosyaAdi(kod);
    return "$marka\\$temizKod.jpeg";
  }

  Future<void> stokSil(Function() verileriGetir) async {
    if (seciliStok.value == null) {
      UiUtils.showMessage("Lütfen silmek için bir ürün seçin!", hata: true);
      return;
    }

    final String stokKodu = seciliStok.value!.stokKod ?? "";
    final ocController = Get.find<import_opencart.OpenCartController>();
    
    // Geçici olarak arka planda bağlantı kontrolü yapalım
    bool ocBaglantiVarMi = ocController.isOcConnected.value;
    if (!ocBaglantiVarMi) {
      ocBaglantiVarMi = await ocController.ocService.baglan(manuelBaslatma: true);
    }

    bool opencarttaVarMi = false;
    String? ocProductId;

    if (ocBaglantiVarMi && stokKodu.isNotEmpty) {
      ocProductId = await ocController.ocService.urunIdSorgula(stokKodu);
      opencarttaVarMi = (ocProductId != null);
    }

    if (opencarttaVarMi) {
      Get.defaultDialog(
        title: "Opencart Ürün Tespit Edildi",
        middleText: "Silmek istediğiniz ürün Opencart üzerinde de bulunmaktadır.\nÜrünü Opencart üzerinden de silmek ister misiniz?",
        textConfirm: "İkisinden de Sil",
        textCancel: "İptal",
        textCustom: "Sadece Yerelden Sil",
        confirmTextColor: Colors.white,
        cancelTextColor: Colors.black,
        buttonColor: Colors.red,
        onConfirm: () async {
          Get.back(); // close dialog
          UiUtils.showMessage("Opencart üzerinden siliniyor...");
          
          bool ocSilindi = await ocController.ocService.urunSil(ocProductId!);
          if (!ocSilindi) {
            UiUtils.showMessage("Opencart'tan silme başarısız oldu! İşlem iptal edildi.", hata: true);
            return;
          }
          
          await _yereldenSil(verileriGetir);
          
          // Eğer OpenCart paneli açıksa ve verisi silindiyse temizleyelim
          if (ocController.ocProductId.value == ocProductId) {
             ocController.ocProductId.value = null;
             ocController.ocData.clear();
          }
        },
        onCustom: () async {
          Get.back(); // close dialog
          await _yereldenSil(verileriGetir);
        },
      );
    } else {
      Get.defaultDialog(
        title: "Silme Onayı",
        middleText: "Seçili ürünü silmek istediğinize emin misiniz?",
        textConfirm: "Evet, Sil",
        textCancel: "İptal",
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () async {
          Get.back(); // close dialog
          await _yereldenSil(verileriGetir);
        },
      );
    }
  }

  Future<void> _yereldenSil(Function() verileriGetir) async {
    final stokId = seciliStok.value?.id;
    if (stokId == null) {
      UiUtils.showMessage("Lütfen silmek için bir ürün seçin!", hata: true);
      return;
    }

    try {
      final dbHelper = DbHelper();
      await dbHelper.deleteStok(stokId);
      formuTemizle();
      UiUtils.showMessage("Ürün yerel stoktan başarıyla silindi!");
      await verileriGetir();
    } catch (e) {
      UiUtils.showMessage("Hata oluştu: $e", hata: true);
    }
  }

  String uretBarkod(String inBar) {
    return BarcodeUtils.uretBarkod(inBar);
  }

  Future<void> generateBarkodDialog() async {
    final dbHelper = DbHelper();
    final ayarlar = await dbHelper.sabitAyarlariGetir();

    if (ayarlar == null || ayarlar['TERAZI'] == null) {
      UiUtils.showMessage("Hata: AYARLAR tablosunda TERAZI değeri bulunamadı!", hata: true);
      return;
    }

    String codeEx = ayarlar['TERAZI'].toString().trim();
    int currentCodeInt = int.tryParse(codeEx) ?? 0;
    String testBarkod = "";
    bool barkodVarMi = true;

    do {
      testBarkod = uretBarkod(currentCodeInt.toString());
      barkodVarMi = await dbHelper.checkBarkodMevcutMu(
        testBarkod,
        seciliStok.value?.id ?? -1,
      );

      if (barkodVarMi) {
        currentCodeInt++;
      }
    } while (barkodVarMi);

    Get.defaultDialog(
      title: "Barkod Üret",
      middleText: "Üretilecek Barkod: $testBarkod\nOnaylıyor musunuz?",
      textConfirm: "Uygula",
      textCancel: "İptal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back(); 
        c['barkod']?.text = testBarkod;
        int nextCodeInt = currentCodeInt + 1;
        await dbHelper.updateTerazi(nextCodeInt.toString().padLeft(5, '0'));
        UiUtils.showMessage("Başarılı: $testBarkod");
      },
    );
  }

  void kurlariHesapla() {
    final settingsController = Get.find<import_settings.SettingsController>();
    double usd = double.tryParse(settingsController.c['kur_dolar']!.text.replaceAll(',', '.')) ?? 0;
    double eur = double.tryParse(settingsController.c['kur_euro']!.text.replaceAll(',', '.')) ?? 0;

    if (usd > 0 && eur > 0) {
      double eurUsd = eur / usd;
      double usdEur = usd / eur;
      settingsController.c['parite_euro_dolar']?.text = eurUsd.toStringAsFixed(4);
      settingsController.c['parite_dolar_euro']?.text = usdEur.toStringAsFixed(4);
    }

    // Eğer formda Dolar Alış girilmişse güncel kurla fiyatları anında güncelle
    double dolarAlis = double.tryParse(
          c['dolar_alis']?.text.replaceAll(',', '.').trim() ?? '0',
        ) ??
        0;
    if (dolarAlis > 0) {
      fiyatHesapla();
    }
  }

  void sabitfiyatlariDovizeCevir() {
    final settingsController = Get.find<import_settings.SettingsController>();
    double tlSatis = double.tryParse(c['satis']!.text.replaceAll(',', '.')) ?? 0;
    double kurUsd = double.tryParse(settingsController.c['sabit_dolar']!.text.replaceAll(',', '.')) ?? 0;
    double kurEur = double.tryParse(settingsController.c['sabit_euro']!.text.replaceAll(',', '.')) ?? 0;

    if (tlSatis <= 0) {
      UiUtils.showMessage("Önce geçerli bir TL Satış Fiyatı giriniz!", hata: true);
      return;
    }

    if (kurUsd <= 0 || kurEur <= 0) {
      UiUtils.showMessage("Kurlar henüz çekilmemiş veya girilmemiş!", hata: true);
      return;
    }

    double dolarSatis = tlSatis / kurUsd;
    c['dolar_satis']?.text = dolarSatis.toStringAsFixed(2);

    double euroSatis = tlSatis / kurEur;
    c['euro_satis']?.text = euroSatis.toStringAsFixed(2);

    settingsController.c['parite_euro_dolar']?.text = (kurEur / kurUsd).toStringAsFixed(4);
    settingsController.c['parite_dolar_euro']?.text = (kurUsd / kurEur).toStringAsFixed(4);
  }

  void fiyatlariDovizeCevir() {
    final settingsController = Get.find<import_settings.SettingsController>();
    double tlSatis = double.tryParse(c['satis']!.text.replaceAll(',', '.')) ?? 0;
    double kurUsd = double.tryParse(settingsController.c['kur_dolar']!.text.replaceAll(',', '.')) ?? 0;
    double kurEur = double.tryParse(settingsController.c['kur_euro']!.text.replaceAll(',', '.')) ?? 0;

    if (tlSatis <= 0) {
      UiUtils.showMessage("Önce geçerli bir TL Satış Fiyatı giriniz!", hata: true);
      return;
    }

    if (kurUsd <= 0 || kurEur <= 0) {
      UiUtils.showMessage("Kurlar henüz çekilmemiş veya girilmemiş!", hata: true);
      return;
    }

    double dolarSatis = tlSatis / kurUsd;
    c['dolar_satis']?.text = dolarSatis.toStringAsFixed(2);

    double euroSatis = tlSatis / kurEur;
    c['euro_satis']?.text = euroSatis.toStringAsFixed(2);

    settingsController.c['parite_euro_dolar']?.text = (kurEur / kurUsd).toStringAsFixed(4);
    settingsController.c['parite_dolar_euro']?.text = (kurUsd / kurEur).toStringAsFixed(4);
  }

  void metaHazirla() {
    String sadi = c['stok_adi']?.text.trim() ?? "";
    String aciklama = c['aciklama']?.text.trim() ?? "";
    String ean = c['barkod']?.text ?? "";

    if (sadi.isNotEmpty) {
      c['metaTitle']?.text = "$sadi - En Uygun Fiyatlar";
    }

    String varsayilanDesc = "En uygun fiyatlar, toptan bebek giyim. Kaliteli bebek giyim ürünleri burada!";
    if (aciklama.isNotEmpty) {
      String duzMetin = aciklama.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
      if (duzMetin.length > 157) {
        c['metaDescription']?.text = "${duzMetin.substring(0, 157)}...";
      } else {
        c['metaDescription']?.text = duzMetin;
      }
    } else {
      c['metaDescription']?.text = varsayilanDesc;
    }

    c['metaKeyword']?.text = "Toptan Fiyat, Bebe takım, baby wear, bebe body, zıbın, Toptan bebe giyim, tulum, çorap, Uygun fiyat, battaniye, Barkod: $ean";
    c['seoUrl']?.text = StringUtils.toSeoUrl(sadi);
  }

  @override
  void onClose() {
    for (var controller in c.values) {
      controller.dispose();
    }
    adetController.dispose();
    stokKodFocusNode.dispose();
    super.onClose();
  }
}
