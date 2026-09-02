import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/db_helper.dart';
import '../services/barkod_printer_service.dart';
import '../utils/barcode_utils.dart';

class PrinterController extends GetxController {
  final DbHelper dbHelper = DbHelper();

  RxList<String> yaziciListesi = <String>[].obs;
  Rx<String?> seciliYazici = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    yazicilariGetir();
  }

  void yazicilariGetir() async {
    try {
      if (!Platform.isWindows) return;

      final printers = await BarkodPrinterService.getWindowsPrinters();
      yaziciListesi.value = printers;

      if (printers.isNotEmpty) {
        if (seciliYazici.value == null || !printers.contains(seciliYazici.value)) {
          if (printers.contains('ZDesigner GC420t (EPL)')) {
            seciliYazici.value = printers.firstWhere((p) => p == 'ZDesigner GC420t (EPL)');
          } else {
            seciliYazici.value = printers.first;
          }
        }
      }
    } catch (e) {
      debugPrint("Yazıcıları Getir Hatası: $e");
    }
  }

  void barkodBasimiBaslat({
    required String barkod,
    required String ad,
    required String fiyat,
    required String miktar,
    required String hedefKey,
  }) async {
    if (seciliYazici.value == null) {
      Get.snackbar("Hata", "Lütfen önce bir yazıcı seçin!", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (barkod.isEmpty || ad.isEmpty) {
      Get.snackbar("Hata", "$hedefKey alanı veya ürün adı boş!", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      await BarkodPrinterService.printBarkod(
        barkod,
        ad,
        fiyat,
        printerName: seciliYazici.value!,
        adet: miktar,
        altSira: "www.koksalbebe.com.tr",
      );
      Get.snackbar("Başarılı", "Barkod basım talebi gönderildi.", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Hata", "Baskı Hatası: $e", backgroundColor: Colors.red, colorText: Colors.white);
      // print("Baskı Hatası: $e");
    }
  }

  String uretBarkod(String inBar) {
    return BarcodeUtils.uretBarkod(inBar);
  }

  Future<void> generateBarkodDialog({required Function(String) onBarkodGenerated, int? currentStokId}) async {
    final ayarlar = await dbHelper.sabitAyarlariGetir();

    if (ayarlar == null || ayarlar['TERAZI'] == null) {
      Get.snackbar("Hata", "AYARLAR tablosunda TERAZI değeri bulunamadı!", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    String codeEx = ayarlar['TERAZI'].toString().trim();
    int currentCodeInt = int.tryParse(codeEx) ?? 0;
    String testBarkod = "";
    bool barkodVarMi = true;

    do {
      testBarkod = uretBarkod(currentCodeInt.toString());
      barkodVarMi = await dbHelper.checkBarkodMevcutMu(testBarkod, currentStokId ?? -1);
      if (barkodVarMi) {
        currentCodeInt++;
      }
    } while (barkodVarMi);

    Get.defaultDialog(
      title: "Barkod Üret",
      content: Text("Sıradaki Barkod:\n$testBarkod\n\nBu barkodu kullanmak istiyor musunuz?"),
      textConfirm: "Evet",
      textCancel: "Hayır",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await dbHelper.updateTerazi((currentCodeInt + 1).toString().padLeft(5, '0'));
        onBarkodGenerated(testBarkod);
        Get.back();
      },
    );
  }
}
