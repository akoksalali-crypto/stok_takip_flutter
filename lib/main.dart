import 'package:flutter/material.dart';
import 'views/stok_ana_sayfa.dart'; // Dosya yolunun doğru olduğundan emin ol

void main() {
  runApp(const StokTakipApp());
}

class StokTakipApp extends StatelessWidget {
  const StokTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stok Takip Flutter',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki "debug" yazısını kaldırır
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Modern görünüm için
      ),
      home: const StokAnaSayfa(),
    );
  }
}
