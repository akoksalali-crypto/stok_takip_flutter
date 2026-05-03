//static String resimAnaYolu = r'C:\wamp\www\OC3\image\catalog';
//static String dbPath =
//   r'C:\Users\koksa\flutter\stok_takip_flutter\lib\services\data.s3db';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/stok_model.dart';

class DbHelper {
  // Singleton Yapısı (Lazarus'taki tekil DataModule gibi)
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static String resimAnaYolu = "";
  static String dbPath = "";
  static Database? _db;

  static Future<void> baglantiyiKapat() async {
    if (_db != null && _db!.isOpen) {
      print(">>> SQLite Bağlantısı Kapatılıyor...");
      await _db!.close();
      _db = null;
    }
  }

  /// paths.txt veya yerel klasörden yolları çeken ana fonksiyon
  static Future<void> yollariYapilandir() async {
    try {
      String exePath = File(Platform.resolvedExecutable).parent.path;

      // Varsayılan yollar (Fallback)
      dbPath = join(exePath, 'data', 'data.s3db');
      resimAnaYolu = join(exePath, 'data', 'image');

      // paths.txt kontrolü
      String configPath = join(exePath, 'paths.txt');
      File configFile = File(configPath);

      if (await configFile.exists()) {
        List<String> satirlar = await configFile.readAsLines();
        if (satirlar.isNotEmpty && satirlar[0].trim().isNotEmpty) {
          dbPath = satirlar[0].trim();
        }
        if (satirlar.length > 1 && satirlar[1].trim().isNotEmpty) {
          resimAnaYolu = satirlar[1].trim();
        }
      }
      print(">>> Yapılandırma Tamamlandı: $dbPath");
    } catch (e) {
      print(">>> Yol Yapılandırma Hatası: $e");
    }
  }

  Future<Database> get db async {
    if (_db != null && _db!.isOpen) return _db!;

    print(">>> SQLite Bağlantısı Açılıyor...");

    String path = DbHelper.dbPath;
    var databaseFactory = databaseFactoryFfi;

    // ÖNEMLİ: Dosyayı açarken kilitlenmeyi önleyen parametreler
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) {
          // Tablo oluşturma kodların buradaysa kalabilir
        },
        // singleInstance: true -> Aynı dosya için birden fazla bağlantı nesnesi oluşmasını engeller
        // Bu, "dönmeye devam" sorununu çözen anahtar ayardır.
        singleInstance: true,
      ),
    );

    // SQLite'a özel PRAGMA ayarı: Dosya kilitlendiğinde bekleme süresi (mil saniye)
    await _db!.execute("PRAGMA busy_timeout = 3000;");
    // Yazma hızını artırır ve kilitlenme riskini azaltır (WAL Modu)
    await _db!.execute("PRAGMA journal_mode = WAL;");

    print(">>> SQLite Bağlantısı BAŞARILI.");
    return _db!;
  }

  /// Tüm stokları getir
  Future<List<Stok>> getStokListesi() async {
    try {
      final dbClient = await db;
      final List<Map<String, dynamic>> list = await dbClient.rawQuery(
        'SELECT * FROM STOK ORDER BY KIMLIK DESC',
      );
      return list.map((item) => Stok.fromMap(item)).toList();
    } catch (e) {
      print(">>> getStokListesi Hatası: $e");
      return [];
    }
  }
}
