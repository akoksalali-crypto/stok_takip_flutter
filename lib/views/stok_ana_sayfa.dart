import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/stok_model.dart';

class StokAnaSayfa extends StatefulWidget {
  const StokAnaSayfa({super.key});

  @override
  State<StokAnaSayfa> createState() => _StokAnaSayfaState();
}

class _StokAnaSayfaState extends State<StokAnaSayfa>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Database? _db;
  bool _isDbInitialized = false;
  List<Stok> _stokListesi = [];
  Stok? _seciliStok;

  // Kontrolcüler (Lazarus: TEdit karşılıkları)
  final Map<String, TextEditingController> _c = {
    'stok_kod': TextEditingController(),
    'stok_adi': TextEditingController(),
    'barkod': TextEditingController(),
    'alis': TextEditingController(),
    'satis': TextEditingController(),
    'dolar_alis': TextEditingController(),
    'dolar_satis': TextEditingController(),
    'euro_satis': TextEditingController(),
    'miktar': TextEditingController(),
    'marj': TextEditingController(),
    'kdv': TextEditingController(),
    'min_adet': TextEditingController(),
    'lot': TextEditingController(),
    'weight': TextEditingController(),
    'meta_title': TextEditingController(),
    'web_link': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    String path = r'\\server\MrmDeskCe\data.s3db';

    try {
      _db = await databaseFactory.openDatabase(path);
      setState(() => _isDbInitialized = true);
      _verileriGetir();
    } catch (e) {
      _mesajGoster("Bağlantı Hatası: $e");
    }
  }

  Future<void> _verileriGetir() async {
    if (_db == null) return;
    final List<Map<String, dynamic>> maps = await _db!.query(
      'STOK',
      orderBy: 'KIMLIK DESC',
      limit: 100,
    );

    setState(() {
      _stokListesi = maps.map((item) => Stok.fromMap(item)).toList();
    });
  }

  Future<void> _stokKaydet() async {
    if (_db == null) return;

    // Pascal'daki otomatik alan doldurma mantığı
    if (_c['weight']!.text.isEmpty) _c['weight']!.text = "1";
    if (_c['min_adet']!.text.isEmpty) _c['min_adet']!.text = "1";
    if (_c['lot']!.text.isEmpty) _c['lot']!.text = "3";
    if (_c['miktar']!.text.isEmpty) _c['miktar']!.text = "100";
    if (_c['barkod']!.text.isEmpty) _c['barkod']!.text = _c['stok_kod']!.text;

    Map<String, dynamic> row = {
      'STOK_KOD': _c['stok_kod']!.text,
      'STOK_ADI': _c['stok_adi']!.text,
      'BARKOD': _c['barkod']!.text,
      'ALIS': _c['alis']!.text,
      'SATIS': _c['satis']!.text,
      'DALIS': _c['dolar_alis']!.text,
      'OZEL': _c['dolar_satis']!.text,
      'OZEL2': _c['euro_satis']!.text,
      'MIKTAR': _c['miktar']!.text,
      'weight': _c['weight']!.text,
      'minimum': _c['min_adet']!.text,
      'LOT': _c['lot']!.text,
    };

    try {
      if (_seciliStok == null) {
        await _db!.insert('STOK', row);
        _mesajGoster("Yeni ürün eklendi.");
      } else {
        await _db!.update(
          'STOK',
          row,
          where: 'KIMLIK = ?',
          whereArgs: [_seciliStok!.id],
        );
        _mesajGoster("Ürün güncellendi.");
      }
      _verileriGetir();
    } catch (e) {
      _mesajGoster("Hata: $e");
    }
  }

  void _formuDoldur(Stok urun) {
    setState(() {
      _seciliStok = urun;
      _c['stok_kod']!.text = urun.stokKod ?? "";
      _c['stok_adi']!.text = urun.stokAdi;
      _c['barkod']!.text = urun.barkod;
      _c['alis']!.text = urun.alisFiyati ?? "";
      _c['satis']!.text = urun.satisFiyati ?? "";
      _c['dolar_alis']!.text = urun.dolarAlis ?? "";
      _c['dolar_satis']!.text = urun.dolarSatis ?? "";
      _c['euro_satis']!.text = urun.euroSatis ?? "";
      _c['miktar']!.text = urun.miktar ?? "";
    });
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MrmDesk Stok Yönetimi'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _seciliStok = null),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _stokKaydet),
        ],
      ),
      body: !_isDbInitialized
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sol Liste
                Container(
                  width: 500,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _stokListesi.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(_stokListesi[index].stokAdi),
                      subtitle: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Barkod: ${_stokListesi[index].barkod} ",
                            ),
                            TextSpan(
                              text: "-  ${_stokListesi[index].miktar}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      onTap: () => _formuDoldur(_stokListesi[index]),
                    ),
                  ),
                ),
                // Sağ Detay Paneli
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.blueAccent,
                        tabs: const [
                          Tab(text: "Stok Bilgisi"),
                          Tab(text: "Web"),
                          Tab(text: "Lojistik"),
                          Tab(text: "Barkodlar"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _stokBilgisiSekmesi(),
                            const Center(child: Text("Web Ayarları")),
                            const Center(child: Text("Lojistik")),
                            const Center(child: Text("Ek Barkodlar")),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stokBilgisiSekmesi() {
    if (_seciliStok == null) {
      return const Center(child: Text("Lütfen bir ürün seçin."));
    }

    // --- 1. Dinamik Yol Hesaplama ---
    String stokAdi = _c['stok_adi']!.text;
    String stokKod = _c['stok_kod']!.text;
    String marka = stokAdi.isNotEmpty ? stokAdi.split(' ')[0] : "Genel";

    // Desteklenen uzantıları listeleyelim
    List<String> uzantilar = ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG'];
    String anaDizin = r'\\server\MrmDeskCe\image\catalog\';

    // Varsayılan bir yol belirleyelim (bulunamazsa kullanılacak)
    String bulunanTamYol = '';
    String bulunanUzanti = '.jpg'; // Hata mesajında göstermek için

    // Döngü ile dosyayı arıyoruz (Lazarus: FileExists kontrolü gibi)
    for (String uzanti in uzantilar) {
      String testYolu = '$anaDizin$marka\\$stokKod$uzanti';
      if (File(testYolu).existsSync()) {
        bulunanTamYol = testYolu;
        bulunanUzanti = uzanti;
        break; // Dosyayı bulduğumuz an döngüden çıkıyoruz
      }
    }

    // Eğer hiçbir uzantı ile dosya bulunamadıysa varsayılan yolu oluştur (Hata ikonu için)
    if (bulunanTamYol.isEmpty) {
      bulunanTamYol = '$anaDizin$marka\\$stokKod.jpg';
    }

    File resimDosyasi = File(bulunanTamYol);

    // --- 2. Görsel Düzenleme ---
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL TARAF: Inputlar
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _input("Stok Kodu", 'stok_kod', 180),
                _input("Barkod", 'barkod', 180),
                _input("Stok Adı", 'stok_adi', 380),
                const Divider(),
                _input("Alış (TL)", 'alis', 120),
                _input("Satış (TL)", 'satis', 120),
                _input("Miktar", 'miktar', 100),
                const Divider(),

                _input("Dolar Alış (\$)", 'dolar_alis', 120),
                _input("Dolar Satış (\$)", 'dolar_satis', 120),
                _input("Euro Satış (€)", 'euro_satis', 120),
                _input("Marj %", 'marj', 100),
                _input("KDV %", 'kdv', 100),
                const Divider(),
              ],
            ),
          ),

          // SAĞ TARAF: Resim Önizleme
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: resimDosyasi.existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            resimDosyasi,
                            fit: BoxFit.contain,
                            // Resim dosyası bozuksa veya erişim hatası varsa
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.red,
                                ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Resim yok",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                "$marka / $stokKod (jpg/jpeg/png)",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton.icon(
                    onPressed:
                        _stokKaydet, // Yukarıda yazdığımız fonksiyonu çağırır
                    icon: const Icon(Icons.save),
                    label: Text(
                      _seciliStok == null
                          ? "Yeni Kaydet"
                          : "Değişiklikleri Güncelle",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "Klasör: $marka",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, String key, double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _c[key],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
