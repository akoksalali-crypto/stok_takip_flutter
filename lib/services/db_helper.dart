import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Windows için
import '../models/stok_model.dart';

class DbHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    // Windows üzerinde sqlite başlatma
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    // Veritabanı dosyanızın yolu (Örn: Masaüstündeki dosya)
    // Gerçek projede bunu 'path_provider' ile uygulama içine almalısın
    String dbPath = "//server/MrmDeskCe/data.s3db";

    _db = await databaseFactory.openDatabase(dbPath);
    return _db!;
  }

  // Tüm stokları getir (Lazarus: StokData.Open)
  Future<List<Stok>> getStokListesi() async {
    var dbClient = await db;
    // Senin paylaştığın şemaya göre: SELECT * FROM STOK
    List<Map<String, dynamic>> list = await dbClient.rawQuery(
      'SELECT * FROM STOK ORDER BY KIMLIK DESC',
    );

    return list.map((item) => Stok.fromMap(item)).toList();
  }
}
