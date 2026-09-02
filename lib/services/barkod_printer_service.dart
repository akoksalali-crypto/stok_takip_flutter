import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class BarkodPrinterService {
  static Future<void> printBarkod(
    String barkod,
    String urunAdi,
    String fiyat, {
    required String printerName,
    String adet = "1",
    String altSira = "www.koksalbebe.com.tr",
  }) async {
    try {
      // 1. PPLA içeriğini oluştur
      final String command = generatePPLA(
        barkod,
        urunAdi,
        fiyat,
        adet: adet,
        altSira: altSira,
      );

      // Klasör ve dosya yollarını tanımla
      const String directoryPath = "C:\\Argox";
      //const String filePath = "$directoryPath\\output.prn";
      const String filePath = "$directoryPath\\ArgEtiket.txt";
      // Lazarus EXE'nin tam yolunu buraya yaz (Örn: C:\Argox\EtiketYazici.exe)
      const String exePath = "$directoryPath\\EtiketYazici.exe";

      // Klasör yoksa oluştur
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (!await File(exePath).exists()) {
        throw "Yazıcı programı bulunamadı: $exePath. Lütfen programın kurulu olduğunu doğrulayın.";
      }

      // 2. job.txt dosyasını yaz (Lazarus'un okuyacağı format)
      final File file = File(filePath);
      await file.writeAsBytes(latin1.encode(command), flush: true);

      debugPrint("🚀 Lazarus EXE tetikleniyor: $exePath");

      // 3. Lazarus EXE'sini parametrelerle çalıştır
      final result = await Process.run(exePath, [
        printerName,
        filePath,
      ], runInShell: true);

      if (result.exitCode == 0) {
        debugPrint("✅ Lazarus EXE başarıyla çalıştı.");
      } else {
        debugPrint("❌ EXE Hatası: ${result.stderr}");
        throw "Yazıcı programı hata döndürdü: ${result.stderr}";
      }
    } catch (e) {
      debugPrint("❌ Servis Katmanı Hatası: $e");
      rethrow;
    }
  }

  static String generatePPLA(
    String barkod,
    String urunAdi,
    String fiyat, {
    String adet = "1",
    String altSira = "www.koksalbebe.com.tr",
  }) {
    final StringBuffer sb = StringBuffer();

    // Türkçe karakterleri temizle ve büyük harfe çevir
    urunAdi = turkceKarakterDuzelt(urunAdi).toUpperCase();

    // Eğer ürün adı çok uzunsa 5'li etikette taşma yapmaması için kısaltalım
    if (urunAdi.length > 25) {
      urunAdi = urunAdi.substring(0, 25);
    }

    // 1. PPLA Başlangıç Komutları
    sb.write('\x02L\r\n'); // STX + L (Etiket formatı başlangıcı)
    sb.write('\x02KI70\r\n'); // STX + L (Etiket formatı başlangıcı)

    sb.write('D11\r\n'); // Piksel ayarı
    sb.write('H11\r\n'); // Isı/Hız ayarı

    // 2. BEŞLİ ETİKET KOORDİNATLARI
    // Her blok bir etiketi temsil eder. Koordinatlar senin job.txt dosyasından alınmıştır.

    // --- 1. Etiket ---
    sb.write('4F6203000180050$barkod\r\n'); // Barkod
    sb.write('490000100100065$urunAdi\r\n'); // Ürün Adı
    sb.write('491100200100077$altSira\r\n'); // Alt Bilgi

    // --- 2. Etiket ---
    sb.write('4F6203000180130$barkod\r\n');
    sb.write('490000100100145$urunAdi\r\n');
    sb.write('491100200100157$altSira\r\n');

    // --- 3. Etiket ---
    sb.write('4F6203000180210$barkod\r\n');
    sb.write('490000100100225$urunAdi\r\n');
    sb.write('491100200100237$altSira\r\n');

    // --- 4. Etiket ---
    sb.write('4F6203000180285$barkod\r\n');
    sb.write('490000100100300$urunAdi\r\n');
    sb.write('491100200100312$altSira\r\n');

    // --- 5. Etiket ---
    sb.write('4F6203000180365$barkod\r\n');
    sb.write('490000100100380$urunAdi\r\n');
    sb.write('491100200100392$altSira\r\n');

    // 3. Yazdırma Adedi ve Kapatma
    // 'Q' komutu kaç set basılacağını belirler
    sb.write('Q${adet.padLeft(3, '0')}\r\n');
    sb.write('E\r\n'); // Formatı bitir ve hafızayı boşalt

    return sb.toString();
  }

  static String turkceKarakterDuzelt(String text) {
    var turkishChars = {
      'ş': 's',
      'Ş': 'S',
      'ğ': 'g',
      'Ğ': 'G',
      'ü': 'u',
      'Ü': 'U',
      'ı': 'i',
      'İ': 'I',
      'ö': 'o',
      'Ö': 'O',
      'ç': 'c',
      'Ç': 'C',
    };
    turkishChars.forEach((key, value) => text = text.replaceAll(key, value));
    // Latin1 kapsamı dışındaki olası özel Unicode sembolleri güvenli karaktere çevir
    return text.replaceAll(RegExp(r'[^\x00-\xFF]'), '?');
  }

  static Future<List<String>> getWindowsPrinters() async {
    if (kDebugMode) {
      debugPrint("🚀 Yazıcı listesi çekiliyor...");
    }
    // PowerShell üzerinden sadece yazıcı isimlerini (Name) çeken en temiz komut
    const String powershellCommand =
        'Get-Printer | Select-Object -ExpandProperty Name';

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        powershellCommand,
      ], runInShell: true);

      if (result.exitCode == 0) {
        final String output = result.stdout.toString();

        // Satırlara böl, her satırı kırp (trim) ve boş olanları ele
        List<String> printers = output
            .split(RegExp(r'[\r\n]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (kDebugMode) {
          debugPrint("✅ Bulunan Yazıcılar: $printers");
        }
        return printers;
      } else {
        debugPrint("❌ PowerShell Hatası: ${result.stderr}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Yazıcı listesi alınırken istisna oluştu: $e");
      return [];
    }
  }
}
