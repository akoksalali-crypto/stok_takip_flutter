import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stok_takip_flutter/controllers/stock_form_controller.dart';
import 'package:stok_takip_flutter/controllers/settings_controller.dart';
import 'package:stok_takip_flutter/models/stok_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockFormController', () {
    late StockFormController controller;
    late SettingsController settingsController;

    setUp(() {
      Get.reset();
      settingsController = Get.put(SettingsController());
      controller = Get.put(StockFormController());
    });

    tearDown(() {
      Get.reset();
    });

    test('Senaryo A: Dolar alış girildiğinde canlı kur üzerinden TL alış, satış ve döviz satış fiyatlarını hesaplar', () {
      // Canlı kurları ayarla
      settingsController.c['kur_dolar']!.text = '34.25';
      settingsController.c['kur_euro']!.text = '37.10';

      // Dolar Alış ve Marj gir
      controller.c['dolar_alis']!.text = '10.00';
      controller.c['marj']!.text = '30';

      controller.fiyatHesapla();

      // 1. TL Alış = 10.00 * 34.25 = 342.50 ₺
      expect(controller.c['alis']!.text, '342.50');
      // 2. TL Satış = ceil(342.50 + 30%) = ceil(445.25) = 446.00 ₺
      expect(controller.c['satis']!.text, '446.00');
      // 3. Dolar Satış = 446 / 34.25 = 13.02 $
      expect(controller.c['dolar_satis']!.text, '13.02');
      // 4. Euro Satış = 446 / 37.10 = 12.02 €
      expect(controller.c['euro_satis']!.text, '12.02');
    });

    test('Senaryo B: Dolar alış boşken TL alış üzerinden sabit kurla döviz satış fiyatlarını hesaplar', () {
      // Sabit kurları ayarla
      settingsController.c['sabit_dolar']!.text = '34.00';
      settingsController.c['sabit_euro']!.text = '37.00';

      // Dolar Alış boş, TL Alış ve Marj gir
      controller.c['dolar_alis']!.text = '';
      controller.c['alis']!.text = '100.00';
      controller.c['marj']!.text = '30';

      controller.fiyatHesapla();

      // 1. TL Satış = 130.00 ₺
      expect(controller.c['satis']!.text, '130.00');
      // 2. Dolar Satış = 130 / 34.00 = 3.82 $
      expect(controller.c['dolar_satis']!.text, '3.82');
      // 3. Euro Satış = 130 / 37.00 = 3.51 €
      expect(controller.c['euro_satis']!.text, '3.51');
    });

    test('ondalıklı sonucu üst tam sayıya yuvarlar', () {
      controller.c['dolar_alis']!.text = '';
      controller.c['alis']!.text = '99';
      controller.c['marj']!.text = '12';

      controller.fiyatHesapla();

      expect(controller.c['satis']!.text, '111.00');
    });

    test('boş form için stok varsayılanlarını yükler', () {
      controller.formuTemizle();

      expect(controller.adetController.text, '1');
      expect(controller.c['marj']!.text, '30');
      expect(controller.c['kdv']!.text, '10');
      expect(controller.c['miktar']!.text, '100');
      expect(controller.c['stok_adi']!.text, isEmpty);
    });

    test('ürün kopyalama yeni kayıt için kodu, barkodu ve tarihleri hazırlar', () {
      controller.formuDoldur(
        Stok(
          id: 12,
          stokKod: 'ABC-12',
          stokAdi: 'Marka Tulum',
          barkod: '8690000000012',
          Fdate: '2020-01-01',
          Ldate: '2020-01-01',
        ),
      );

      final bugun = DateTime.now().toString().split(' ')[0];
      final yeniKod = controller.kopyaOlarakHazirla();

      expect(yeniKod, 'ABC-KOPYA');
      expect(controller.seciliStok.value?.id, isNull);
      expect(controller.c['stok_kod']!.text, 'ABC-KOPYA');
      expect(controller.c['barkod']!.text, isEmpty);
      expect(controller.c['Fdate']!.text, bugun);
      expect(controller.c['Ldate']!.text, bugun);
      expect(controller.c['image']!.text, 'Marka\\ABC-KOPYA.jpeg');
    });
  });
}
