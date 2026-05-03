import 'package:flutter/material.dart';
import 'services/db_helper.dart'; // DbHelper yolunu kontrol et
import 'views/stok_ana_sayfa.dart';

void main() async {
  // 1. Flutter bağlamını başlat (Asenkron işlemler için şart)
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Önce varsa eski bağlantıyı temizleyelim (Tedbir amaçlı)
  await DbHelper.baglantiyiKapat();

  // 2. paths.txt veya data klasöründen yolları oku
  await DbHelper.yollariYapilandir();

  runApp(const StokTakipApp());
}

class StokTakipApp extends StatelessWidget {
  const StokTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stok Takip Flutter',
      // 'false' yaparsan sağ üstteki "debug" bandı kalkar
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StokAnaSayfa(),
    );
  }
}
