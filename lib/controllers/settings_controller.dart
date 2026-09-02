import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/db_helper.dart';

class SettingsController extends GetxController {
  final DbHelper dbHelper = DbHelper();

  final Map<String, TextEditingController> c = {
    'kur_dolar': TextEditingController(),
    'kur_euro': TextEditingController(),
    'sabit_dolar': TextEditingController(),
    'sabit_euro': TextEditingController(),
    'parite_euro_dolar': TextEditingController(),
    'parite_dolar_euro': TextEditingController(),
    'resimAnaYolu': TextEditingController(),
    'oc_host': TextEditingController(),
    'oc_port': TextEditingController(text: '3306'),
    'oc_db': TextEditingController(),
    'oc_user': TextEditingController(),
    'oc_pass': TextEditingController(),
    'db_path': TextEditingController(),
  };

  RxBool isPasswordVisible = false.obs;
  RxBool seciliTl = true.obs;
  RxBool seciliEuro = false.obs;
  RxBool seciliDolar = false.obs;
  RxBool autoSync = false.obs;

  @override
  void onInit() {
    super.onInit();
    sabitAyarlariYukle();
  }

  @override
  void onClose() {
    c.forEach((key, controller) {
      controller.dispose();
    });
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void setCurrency(String currency) {
    if (currency == 'TL') {
      seciliTl.value = true;
      seciliEuro.value = false;
      seciliDolar.value = false;
    } else if (currency == 'EURO') {
      seciliTl.value = false;
      seciliEuro.value = true;
      seciliDolar.value = false;
    } else if (currency == 'USD') {
      seciliTl.value = false;
      seciliEuro.value = false;
      seciliDolar.value = true;
    }
  }

  Future<void> sabitAyarlariYukle() async {
    var data = await dbHelper.sabitAyarlariGetir();

    if (data != null) {
      String veritabaniYolu =
          data['RESIM_YOL'] ?? r"\\server\MrmDeskCe\image\catalog";
      String finalYol = veritabaniYolu;

      try {
        bool yolVarMi = await Directory(veritabaniYolu).exists();
        if (!yolVarMi) {
          finalYol = r"C:\wamp\www\OC3\image\catalog";
          // print("Uyarı: DB yolu bulunamadı, yerel alternatif atandı: $finalYol");
        }
      } catch (e) {
        finalYol = r"C:\wamp\www\OC3\image\catalog";
        // print("Hata: Yol kontrol edilemedi, alternatife dönüldü: $e");
      }

      DbHelper.resimAnaYolu = finalYol;

      c['sabit_dolar']?.text = ((data['SABIT_DOLAR'] ?? 0) / 100.0).toString();
      c['sabit_euro']?.text = ((data['SABIT_EURO'] ?? 0) / 100.0).toString();
      c['resimAnaYolu']?.text = finalYol;
      c['oc_host']?.text = data['OC_HOST']?.toString() ?? "";
      c['oc_port']?.text = (data['OC_PORT'] ?? 3306).toString();
      c['oc_db']?.text = data['OC_DB']?.toString() ?? "";
      c['oc_user']?.text = data['OC_USER']?.toString() ?? "";
      c['oc_pass']?.text = data['OC_PASS']?.toString() ?? "";
      c['db_path']?.text = DbHelper.dbPath;
    }
  }

  Future<void> sabitAyarlariYaz() async {
    try {
      String dolarMetin = c['sabit_dolar']?.text ?? "0";
      String euroMetin = c['sabit_euro']?.text ?? "0";
      String rYol = c['resimAnaYolu']?.text ?? r"\\server\MrmDeskCe\image\catalog";

      int dInt = ((double.tryParse(dolarMetin) ?? 0) * 100).toInt();
      int eInt = ((double.tryParse(euroMetin) ?? 0) * 100).toInt();

      await dbHelper.sabitAyarlariGuncelle(
        dInt,
        eInt,
        rYol,
        ocHost: c['oc_host']?.text,
        ocPort: int.tryParse(c['oc_port']?.text ?? '3306'),
        ocDb: c['oc_db']?.text,
        ocUser: c['oc_user']?.text,
        ocPass: c['oc_pass']!.text,
      );

      await DbHelper.dbYoluKaydet(c['db_path']!.text);
      DbHelper.resimAnaYolu = c['resimAnaYolu']?.text ?? "";

      Get.snackbar(
        "Başarılı",
        "Ayarlar kaydedildi.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Hata",
        "Ayarlar kaydedilirken bir hata oluştu:\n$e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
