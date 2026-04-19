import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Windows için
import '../models/stok_model.dart';

class DbHelper {
  // Resim Ana Dizini
  static const String resimAnaYolu = r'C:\wamp\www\OC3\image\catalog';
  static const String dbPath =
      r'C:\Users\koksa\flutter\stok_takip_flutter\lib\services\data.s3db';
  //r'\\server\MrmDeskCe\data.s3db';
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    // Yukarıdaki merkezi 'dbYolu' değişkenini kullanıyoruz
    _db = await databaseFactory.openDatabase(dbPath);
    return _db!;
  }

  // Tüm stokları getir (Lazarus: StokData.Open)
  Future<List<Stok>> getStokListesi() async {
    var dbClient = await db;
    List<Map<String, dynamic>> list = await dbClient.rawQuery(
      'SELECT * FROM STOK ORDER BY KIMLIK DESC',
    );

    return list.map((item) => Stok.fromMap(item)).toList();
  }
}
