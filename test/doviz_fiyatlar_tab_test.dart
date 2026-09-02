import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stok_takip_flutter/views/widgets/doviz_fiyatlar_tab_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DovizFiyatlarTabWidget döviz kurlarını ve ürün döviz fiyat kutularını doğru render eder', (tester) async {
    bool kurCekildi = false;
    bool sabitKaydedildi = false;
    bool dovizeCevrildi = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DovizFiyatlarTabWidget(
            isStokSelected: true,
            stokAdi: 'Dantelli Bebek Elbisesi',
            satisFiyati: '450',
            dolarSatis: '15.00',
            euroSatis: '13.50',
            buildInput: (label, key, width, {buyukHarf = false, focusNode, themeColor, onChanged, readOnly = false, isPassword = false, externalController}) {
              return SizedBox(
                width: width == double.infinity ? 200 : width,
                child: Text('$label: sample'),
              );
            },
            fiyatlariDovizeCevir: () => dovizeCevrildi = true,
            sabitfiyatlariDovizeCevir: () {},
            guncelKurlariCek: () => kurCekildi = true,
            sabitAyarlariYaz: () => sabitKaydedildi = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kart Başlıkları
    expect(find.text('Canlı Piyasa Döviz Kurları & Parite'), findsOneWidget);
    expect(find.text('Veritabanı Sabit Kurları (Offline / Sabit Fiyatlama)'), findsOneWidget);
    expect(find.text('Seçili Ürün Döviz Satış Fiyatları'), findsOneWidget);

    // Eylem Butonları
    expect(find.text('Kurları İnternetten Çek'), findsOneWidget);
    expect(find.text('Sabit Kurları Kaydet'), findsOneWidget);
    expect(find.text('Seçili Ürünü Reel Canlı Kurla Çevir & Güncelle'), findsOneWidget);

    // Fiyat Kutuları
    expect(find.text('450 ₺'), findsOneWidget);
    expect(find.text('15.00 \$'), findsOneWidget);
    expect(find.text('13.50 €'), findsOneWidget);

    // Buton Tıklama Testi
    await tester.tap(find.text('Kurları İnternetten Çek'));
    expect(kurCekildi, true);

    await tester.tap(find.text('Sabit Kurları Kaydet'));
    expect(sabitKaydedildi, true);

    await tester.tap(find.text('Seçili Ürünü Reel Canlı Kurla Çevir & Güncelle'));
    expect(dovizeCevrildi, true);
  });
}
