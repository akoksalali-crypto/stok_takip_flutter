import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:stok_takip_flutter/controllers/stock_form_controller.dart';
import 'package:stok_takip_flutter/models/stok_model.dart';
import 'package:stok_takip_flutter/views/widgets/stok_detay_form_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  testWidgets('StokDetayFormWidget ürün seçildiğinde ve kâr özeti hesaplandığında hatasız render edilir', (tester) async {
    final formController = Get.put(StockFormController());

    final testStok = Stok(
      id: 1,
      stokKod: 'TEST-001',
      stokAdi: 'Test Ürün Adı',
      barkod: '8690001',
      alisFiyati: '100',
      satisFiyati: '150',
      marj: '50',
      miktar: '10',
    );

    formController.formuDoldur(testStok);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: StokDetayFormWidget(
            stokKodFocusNode: formController.stokKodFocusNode,
            tabDovizFiyatlar: const SizedBox.shrink(),
            openCartPreview: const SizedBox.shrink(),
            buildInput: (label, key, width, {buyukHarf = false, focusNode, themeColor}) {
              return SizedBox(
                width: width == double.infinity ? 200 : width,
                child: Text('$label: ${formController.c[key]?.text ?? ""}'),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Temel ürün alanlarının ve kâr özetinin render edildiğini doğrula
    expect(find.textContaining('Temel Ürün Bilgileri'), findsOneWidget);
    expect(find.textContaining('Fiyatlandırma & Kâr Marjı'), findsOneWidget);
    expect(find.textContaining('Birim Alış'), findsOneWidget);
    expect(find.textContaining('100.00 ₺'), findsOneWidget);
    expect(find.textContaining('150.00 ₺'), findsOneWidget);
    expect(find.textContaining('+50.00 ₺'), findsOneWidget);
    expect(find.textContaining('%50.0'), findsOneWidget);
    expect(find.textContaining('1500.00 ₺'), findsOneWidget);
  });
}
