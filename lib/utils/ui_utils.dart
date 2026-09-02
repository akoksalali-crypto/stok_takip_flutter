import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UiUtils {
  /// Merkezi mesaj gösterme metodu (Snackbar)
  static void showMessage(String mesaj, {bool hata = false}) {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    } catch (_) {
      // GetX snackbar henüz ekrana çizilmeden close çağrıldığında
      // oluşan AnimationController LateInitializationError'ını yutar.
    }

    Get.snackbar(
      hata ? "Hata" : "Bilgi",
      mesaj,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: hata ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      icon: Icon(
        hata ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }
}
