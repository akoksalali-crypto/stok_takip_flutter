import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KurService {
  // Varsayılan kurlar (İnternet olmaması durumunda veya ilk açılışta koruyucu olarak)
  double usd = 34.25;
  double eur = 37.10;
  bool yukleniyor = false;

  /// TCMB veya ücretsiz döviz API servislerinden TRY bazlı canlı kurları çeker
  Future<bool> kurlariGuncelle() async {
    yukleniyor = true;
    try {
      // Güvenli ve hızlı bir kur API sağlayıcısı (TRY bazlı kurlar)
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/TRY'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'];

          // API TRY tabanlı olduğu için diğer para birimlerinin TRY karşılıklarını buluyoruz
          // Örn: 1 USD = kaç TRY -> 1 / TRY rates['USD']
          if (rates['USD'] != null) {
            usd = 1.0 / (rates['USD'] as num).toDouble();
          }
          if (rates['EUR'] != null) {
            eur = 1.0 / (rates['EUR'] as num).toDouble();
          }
          yukleniyor = false;
          return true;
        }
      }
    } catch (e) {
      debugPrint("Canlı kur güncelleme hatası: $e");
    }
    yukleniyor = false;
    return false;
  }

  /// EUR / USD paritesini hesaplar
  double get eurUsdParitesi {
    if (usd == 0) return 0.0;
    return eur / usd;
  }

  /// USD / EUR paritesini hesaplar
  double get usdEurParitesi {
    if (eur == 0) return 0.0;
    return usd / eur;
  }
}
