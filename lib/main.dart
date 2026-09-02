import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:get/get.dart';
import 'services/db_helper.dart'; 
import 'views/stok_ana_sayfa.dart';
import 'utils/app_theme.dart';
import 'package:path_provider/path_provider.dart';

Future<void> yazLog(String mesaj) async {
  try {
    final directory = await getApplicationSupportDirectory();
    File logFile = File('${directory.path}/error_log.txt');
    await logFile.writeAsString('${DateTime.now()}: $mesaj\n', mode: FileMode.append);
  } catch (e) {
    // Ignore
  }
}

void main() async {
  // Hataları yakalamak için (Release modunda donmayı anlamak için çok önemli)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    yazLog('Flutter Hata: ${details.exceptionAsString()}\nStack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    yazLog('Platform Hata: $error\nStack: $stack');
    return true;
  };

  // 1. Flutter bağlamını başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Masaüstü platformları için SQLite FFI başlat (Release'de donmaları önler)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pencere yöneticisini başlat (Debug modunda donmaları önleyen standart yöntem)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });
  }

  // 2. Kaydedilen, uygulama yanı veya ağ paylaşımındaki veritabanını bul.
  try {
    await DbHelper.dbYoluYapilandir();
    yazLog('runApp cagiriliyor...');
    runApp(const StokTakipApp());
  } on DbYapilandirmaHatasi catch (hata) {
    yazLog(hata.toString());
    runApp(VeritabaniYapilandirmaUygulamasi(hata: hata));
  }
}

class StokTakipApp extends StatelessWidget {
  const StokTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Stok Takip Flutter',
      // 'false' yaparsan sağ üstteki "debug" bandı kalkar
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: StokAnaSayfa(),
    );
  }
}

class VeritabaniYapilandirmaUygulamasi extends StatelessWidget {
  final DbYapilandirmaHatasi hata;

  const VeritabaniYapilandirmaUygulamasi({super.key, required this.hata});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veritabanı Yapılandırması',
      home: VeritabaniYapilandirmaSayfasi(hata: hata),
    );
  }
}

class VeritabaniYapilandirmaSayfasi extends StatefulWidget {
  final DbYapilandirmaHatasi hata;

  const VeritabaniYapilandirmaSayfasi({super.key, required this.hata});

  @override
  State<VeritabaniYapilandirmaSayfasi> createState() =>
      _VeritabaniYapilandirmaSayfasiState();
}

class _VeritabaniYapilandirmaSayfasiState
    extends State<VeritabaniYapilandirmaSayfasi> {
  final _yolController = TextEditingController(text: r'\\server\MrmDeskCe\data.s3db');
  String? _hataMesaji;
  bool _kaydediliyor = false;

  @override
  void dispose() {
    _yolController.dispose();
    super.dispose();
  }

  Future<void> _kaydetVeBaslat() async {
    setState(() {
      _kaydediliyor = true;
      _hataMesaji = null;
    });

    try {
      await DbHelper.dbYoluKaydet(_yolController.text);
      await DbHelper.dbYoluYapilandir();
      runApp(const StokTakipApp());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hataMesaji = e.toString();
        _kaydediliyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Veritabanı bulunamadı',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ağ paylaşımındaki veya yerel veritabanı dosyasının tam yolunu girin. '
                    'Dosyanın varlığı ve okunabilirliği kaydetmeden önce doğrulanır.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _yolController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Veritabanı dosyası yolu',
                      hintText: r'\\sunucu\paylasim\data.s3db',
                    ),
                    onSubmitted: (_) => _kaydetVeBaslat(),
                  ),
                  if (_hataMesaji != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _hataMesaji!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _kaydediliyor ? null : _kaydetVeBaslat,
                      child: Text(_kaydediliyor ? 'Doğrulanıyor...' : 'Kaydet ve başlat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
