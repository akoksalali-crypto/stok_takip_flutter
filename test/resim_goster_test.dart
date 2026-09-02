import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stok_takip_flutter/views/widgets/resim_goster_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ResimGosterWidget WhatsApp mesaj önizlemesini ve para birimi çiplerini doğru render eder', (tester) async {
    final webLinkController = TextEditingController(text: 'https://example.com/product/1');
    bool seciliTl = true;
    bool seciliEuro = false;
    bool seciliDolar = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ResimGosterWidget(
                stokAdi: 'Bebek Tulumu',
                stokKod: 'BBM-101',
                resimAnaYolu: '',
                fiyatTl: '250',
                fiyatEuro: '10',
                fiyatDolar: '12',
                seciliTl: seciliTl,
                seciliEuro: seciliEuro,
                seciliDolar: seciliDolar,
                onSeciliTlChanged: (v) => setState(() => seciliTl = v),
                onSeciliEuroChanged: (v) => setState(() => seciliEuro = v),
                onSeciliDolarChanged: (v) => setState(() => seciliDolar = v),
                onWhatsappIlePaylas: (_) {},
                isOcConnected: false,
                onOcBaglantisiniYonet: () {},
                onStokKaydet: () {},
                onStokSilOnayli: () {},
                onStokDataUrunKopyala: () {},
                buildInput: (label, key, width, {buyukHarf = false, focusNode, themeColor, onChanged, readOnly = false, isPassword = false, externalController}) {
                  return SizedBox(
                    width: width == double.infinity ? 200 : width,
                    child: Text('$label: sample'),
                  );
                },
                webLinkController: webLinkController,
                onLinkiAc: (_) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Kart başlıklarını doğrula
    expect(find.text('WhatsApp & Paylaşım'), findsOneWidget);
    expect(find.text('Görsel Yolu & Web Linki'), findsOneWidget);

    // Canlı mesaj önizlemesinde seçili TL ve Dolar fiyatlarını doğrula
    expect(find.textContaining('*Bebek Tulumu*'), findsOneWidget);
    expect(find.textContaining('💰 Fiyat: 250 TL'), findsOneWidget);
    expect(find.textContaining('💵 Dolar: 12 \$'), findsOneWidget);

    // Butonları doğrula
    expect(find.text('WhatsApp ile Paylaş'), findsOneWidget);
    expect(find.text('Kopyala'), findsOneWidget);
  });

  testWidgets('ResimGosterWidget görsel bulunmadığında klasör açma ipucu ve butonunu gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResimGosterWidget(
            stokAdi: 'KÖKSAL Bebek Takımı',
            stokKod: 'KB-202',
            resimAnaYolu: r'C:\image\catalog',
            fiyatTl: '300',
            fiyatEuro: '0',
            fiyatDolar: '0',
            seciliTl: true,
            seciliEuro: false,
            seciliDolar: false,
            onSeciliTlChanged: (_) {},
            onSeciliEuroChanged: (_) {},
            onSeciliDolarChanged: (_) {},
            onWhatsappIlePaylas: (_) {},
            isOcConnected: false,
            onOcBaglantisiniYonet: () {},
            onStokKaydet: () {},
            onStokSilOnayli: () {},
            onStokDataUrunKopyala: () {},
            buildInput: (label, key, width, {buyukHarf = false, focusNode, themeColor, onChanged, readOnly = false, isPassword = false, externalController}) {
              return SizedBox(width: width, child: Text(label));
            },
            webLinkController: TextEditingController(),
            onLinkiAc: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Görsel Bulunamadı'), findsOneWidget);
    expect(find.text('KÖKSAL / KB-202'), findsOneWidget);
    expect(find.text('Klasörü açmak için çift tıklayın'), findsOneWidget);
  });
}
