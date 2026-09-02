import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stok_takip_flutter/views/widgets/barkodlar_tab_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BarkodlarTabWidget etiket mockup ve kontrollerini doğru render eder', (tester) async {
    final adetController = TextEditingController(text: '1');
    String basilacakKey = 'barkod';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return BarkodlarTabWidget(
                isStokSelected: true,
                stokAdi: 'Kadife Bebek Takımı',
                satisFiyati: '349.90',
                basilacakBarkodDegeri: '8690012345678',
                basilacakBarkodKey: basilacakKey,
                onBasilacakBarkodKeyChanged: (k) => setState(() => basilacakKey = k),
                buildInput: (label, key, width, {buyukHarf = false, focusNode, themeColor, onChanged, readOnly = false, isPassword = false, externalController}) {
                  return SizedBox(
                    width: width == double.infinity ? 200 : width,
                    child: Text('$label: sample'),
                  );
                },
                yaziciListesi: const ['Xprinter XP-365B', 'Zebra ZD220'],
                seciliYazici: 'Xprinter XP-365B',
                onYaziciChanged: (_) {},
                adetController: adetController,
                barkodBasimiBaslat: (context, {tiklananBarkodKey}) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kart başlıkları
    expect(find.text('Ek Barkod Tanımları (1 - 7)'), findsOneWidget);
    expect(find.text('Canlı Etiket Önizleme (50x30 mm)'), findsOneWidget);
    expect(find.text('Etiket Yazdırma Kontrolleri'), findsOneWidget);

    // Mockup içerikleri
    expect(find.text('KÖKSAL BEBE'), findsOneWidget);
    expect(find.text('Kadife Bebek Takımı'), findsOneWidget);
    expect(find.text('349.90 ₺'), findsOneWidget);
    expect(find.text('KDV DAHİL DEĞİLDİR'), findsOneWidget);

    // Yazdırma butonu
    expect(find.text('ETİKET YAZDIR'), findsOneWidget);

    // Hızlı Adet Artırma Testi
    final plusBtn = find.byIcon(Icons.add);
    expect(plusBtn, findsOneWidget);
    await tester.tap(plusBtn);
    expect(adetController.text, '2');
  });
}
