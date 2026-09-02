// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // compute için eklendi

import '../models/stok_model.dart';

// Arka planda listeyi mapleme fonksiyonu (Isolate)
List<Stok> _parseStokListesi(List<Map<String, dynamic>> data) {
  return data.map((item) => Stok.fromMap(item)).toList();
}

class DbYapilandirmaHatasi implements Exception {
  final List<String> denenenYollar;

  const DbYapilandirmaHatasi(this.denenenYollar);

  @override
  String toString() =>
      'Geçerli bir veritabanı dosyası bulunamadı. Denenen yollar: ${denenenYollar.join(', ')}';
}

class DbHelper {
  // Singleton Yapısı (Lazarus'taki tekil DataModule gibi)
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();
  static String dbPath = ""; // Başlangıçta boş bırakıyoruz
  static String resimAnaYolu = "";

  static Database? _db;

  static const String _agPaylasimDbYolu = r'\\server\MrmDeskCe\data.s3db';

  static Future<void> dbYoluYapilandir() async {
    final prefs = await SharedPreferences.getInstance();
    final exePath = File(Platform.resolvedExecutable).parent.path;
    final uygulamaYaniDbYolu = join(exePath, 'data', 'data.s3db');
    final uygulamaVeriDizini = await getApplicationSupportDirectory();
    final uygulamaVeriDbYolu = join(uygulamaVeriDizini.path, 'data.s3db');
    final kayitliYol = prefs.getString('db_path')?.trim();

    final adayYollar = <String>[
      if (kayitliYol != null && kayitliYol.isNotEmpty) kayitliYol,
      uygulamaYaniDbYolu,
      _agPaylasimDbYolu,
      uygulamaVeriDbYolu,
    ];

    for (final adayYol in adayYollar.toSet()) {
      if (await _veritabaniDosyasiKullanilabilirMi(adayYol)) {
        dbPath = adayYol;
        print(">>> Aktif Veritabanı Yolu: $dbPath");
        return;
      }
    }

    throw DbYapilandirmaHatasi(adayYollar);
  }

  static Future<bool> _veritabaniDosyasiKullanilabilirMi(String yol) async {
    try {
      final dosya = File(yol);
      if (!await dosya.exists()) return false;
      final acilanDosya = await dosya.open(mode: FileMode.read);
      await acilanDosya.close();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  // Veritabanı yolunu kaydetmek için yeni fonksiyon
  static Future<void> dbYoluKaydet(String yeniYol) async {
    final temizYol = yeniYol.trim();
    if (!await _veritabaniDosyasiKullanilabilirMi(temizYol)) {
      throw ArgumentError.value(
        yeniYol,
        'yeniYol',
        'Veritabanı dosyası bulunamadı veya okunamıyor.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_path', temizYol);
    dbPath = temizYol;
  }

  // Veritabanından ayarları tek bir Map olarak getirir
  Future<Map<String, dynamic>?> sabitAyarlariGetir() async {
    final dbClient = await db; // 'database' yerine 'db' getter'ını çağırdık
    List<Map<String, dynamic>> maps = await dbClient.query('AYARLAR', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> sabitAyarlariGuncelle(
    int dolarInt,
    int euroInt,
    String rYol, {
    String? ocHost,
    int? ocPort,
    String? ocDb,
    String? ocUser,
    String? ocPass,
  }) async {
    final dbClient = await db; 
    
    // Temel güncellemeler
    int count = await dbClient.rawUpdate(
      'UPDATE AYARLAR SET SABIT_DOLAR = ?, SABIT_EURO = ?, RESIM_YOL = ?',
      [dolarInt, euroInt, rYol],
    );

    // OpenCart ayarları verildiyse onları da güncelle
    if (ocHost != null && ocDb != null && ocUser != null && ocPass != null && ocPort != null) {
      await dbClient.rawUpdate(
        'UPDATE AYARLAR SET OC_HOST = ?, OC_PORT = ?, OC_DB = ?, OC_USER = ?, OC_PASS = ?',
        [ocHost, ocPort, ocDb, ocUser, ocPass],
      );
    }
    
    return count;
  }

  Future<bool> checkBarkodMevcutMu(String barkod, int haricTutulacakId) async {
    final dbClient = await db;
    final cleanBar = barkod.trim();
    if (cleanBar.isEmpty) return false;

    final result = await dbClient.rawQuery(
      '''SELECT COUNT(*) FROM STOK 
         WHERE (BARKOD = ? OR BARKOD2 = ? OR BARKOD3 = ? OR BARKOD4 = ? OR BARKOD5 = ? OR BARKOD6 = ? OR BARKOD7 = ?) 
         AND KIMLIK != ?''',
      [
        cleanBar,
        cleanBar,
        cleanBar,
        cleanBar,
        cleanBar,
        cleanBar,
        cleanBar,
        haricTutulacakId,
      ],
    );
    int count = result.isNotEmpty ? (result.first.values.first as int? ?? 0) : 0;
    return count > 0;
  }

  Future<void> updateTerazi(String yeniDeger) async {
    final dbClient = await db;
    await dbClient.execute("UPDATE AYARLAR SET TERAZI = ?", [yeniDeger]);
  }

  static Future<Database>? _initDbFuture;

  Future<Database> get db async {
    if (_db != null && _db!.isOpen) return _db!;
    if (_initDbFuture != null) {
      return await _initDbFuture!;
    }
    _initDbFuture = _initDb();
    return await _initDbFuture!;
  }

  Future<Database> _initDb() async {
    try {
      var databaseFactory = databaseFactoryFfi;
      _db = await databaseFactory.openDatabase(
        DbHelper.dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          singleInstance: true,
          onCreate: (db, version) {},
        ),
      );
      try {
        await _db!.execute("PRAGMA busy_timeout = 5000;");
      } catch (e) {
        print("PRAGMA busy_timeout hatası: $e");
      }
      try {
        await _db!.execute("PRAGMA journal_mode = DELETE;");
      } catch (e) {
        print("PRAGMA journal_mode hatası: $e");
      }
      try {
        await _db!.execute("PRAGMA synchronous = NORMAL;");
      } catch (e) {
        print("PRAGMA synchronous hatası: $e");
      }

      try {
        var tableInfo = await _db!.rawQuery('PRAGMA table_info(AYARLAR)');
        var columnNames = tableInfo.map((e) => e['name'] as String).toList();
        
        if (!columnNames.contains('OC_HOST')) {
          await _db!.execute("ALTER TABLE AYARLAR ADD COLUMN OC_HOST TEXT DEFAULT ''");
        }
        if (!columnNames.contains('OC_PORT')) {
          await _db!.execute("ALTER TABLE AYARLAR ADD COLUMN OC_PORT INTEGER DEFAULT 3306");
        }
        if (!columnNames.contains('OC_DB')) {
          await _db!.execute("ALTER TABLE AYARLAR ADD COLUMN OC_DB TEXT DEFAULT ''");
        }
        if (!columnNames.contains('OC_USER')) {
          await _db!.execute("ALTER TABLE AYARLAR ADD COLUMN OC_USER TEXT DEFAULT ''");
        }
        if (!columnNames.contains('OC_PASS')) {
          await _db!.execute("ALTER TABLE AYARLAR ADD COLUMN OC_PASS TEXT DEFAULT ''");
        }
      } catch (e) {
        print("Sütun kontrol hatası: $e");
      }
      return _db!;
    } catch (e) {
      _initDbFuture = null;
      print(">>> SQLite Bağlantı HATASI: $e");
      rethrow;
    }
  }

  static Future<void> baglantiyiKapat() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Future<List<Stok>> getStokListesi() async {
    final dbClient = await db;
    try {
      final List<Map<String, dynamic>> list = await dbClient.rawQuery(
        'SELECT * FROM STOK ORDER BY LDATE DESC',
      );
      // Ağır parsing işlemini ayrı bir thread (isolate) üzerinde yap
      return await compute(_parseStokListesi, list);
    } catch (e) {
      print(">>> getStokListesi Hatası: $e");
      return [];
    }
  }

  Future<int> deleteStok(int id) async {
    final dbClient = await db;
    return await dbClient.delete('STOK', where: 'KIMLIK = ?', whereArgs: [id]);
  }

  Future<int> insertStok(Map<String, dynamic> row) async {
    final dbClient = await db;
    return await dbClient.insert('STOK', row);
  }

  Future<int> updateStok(Map<String, dynamic> row, int id) async {
    final dbClient = await db;
    return await dbClient.update('STOK', row, where: 'KIMLIK = ?', whereArgs: [id]);
  }

  // Arama Metodu
  Future<List<Map<String, dynamic>>> stokAra(String kelime) async {
    final dbClient = await db;
    String aramaTerimi = kelime.trim().toUpperCase();
    if (aramaTerimi.isEmpty) return [];

    try {
      // 7 barkod alanı ve parça aramayı destekleyen SQL sorgusu
      return await dbClient.rawQuery(
        '''
      SELECT 
        KIMLIK, 
        STOK_ADI, 
        STOK_KOD 
      FROM STOK 
      WHERE UPPER(STOK_ADI) LIKE ? 
         OR UPPER(STOK_KOD) LIKE ?
         OR BARKOD = ?
         OR BARKOD2 = ?
         OR BARKOD3 = ?
         OR BARKOD4 = ?
         OR BARKOD5 = ?
         OR BARKOD6 = ?
         OR BARKOD7 = ?
      ORDER BY STOK_ADI ASC 
    ''',
        [
          '%$aramaTerimi%',
          '%$aramaTerimi%',
          aramaTerimi,
          aramaTerimi,
          aramaTerimi,
          aramaTerimi,
          aramaTerimi,
          aramaTerimi,
          aramaTerimi,
        ],
      );
    } catch (e) {
      debugPrint("Stok Arama Hatası: $e");
      return [];
    }
  }

  // Toplu Güncelleme Metodu
  Future<int> topluIsimGuncelle(String eski, String yeni) async {
    final dbClient = await db;
    final eskiTemiz = eski.trim();
    final yeniTemiz = yeni.trim();
    if (eskiTemiz.isEmpty) return 0;

    return await dbClient.rawUpdate(
      '''
    UPDATE STOK 
    SET STOK_ADI = TRIM(REPLACE(' ' || UPPER(STOK_ADI) || ' ', ?, ?)) 
    WHERE ' ' || UPPER(STOK_ADI) || ' ' LIKE ?
  ''',
      [' ${eskiTemiz.toUpperCase()} ', ' ${yeniTemiz.toUpperCase()} ', '% ${eskiTemiz.toUpperCase()} %'],
    );
  }
}
