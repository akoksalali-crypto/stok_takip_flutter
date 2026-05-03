import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../services/opencart_service.dart'; // Oluşturduğumuz OpenCart servis dosyası
import '../models/stok_model.dart';
import '../services/db_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class StokAnaSayfa extends StatefulWidget {
  const StokAnaSayfa({super.key});

  @override
  State<StokAnaSayfa> createState() => _StokAnaSayfaState();
}

class _StokAnaSayfaState extends State<StokAnaSayfa>
    with SingleTickerProviderStateMixin {
  List<Stok> _stokListesi = []; // Veritabanından gelen orijinal tam liste
  List<Stok> _filtreliListe = []; // Ekranda süzülen (arama sonuçları) liste

  final OpenCartService _ocService = OpenCartService();
  bool _isOcConnected = false;
  String? _ocProductId; // Ürün varsa ID'sini burada tutacağız

  final TextEditingController _aramaController = TextEditingController();
  late TabController _tabController;
  Database? _db;
  bool _isDbInitialized = false;
  Stok? _seciliStok;
  bool _formAcikMi = false;

  // Kontrolcüler (Lazarus: TEdit karşılıkları) /_c haritasına (Map) şu yeni anahtarları ekleyelim:
  final Map<String, TextEditingController> _c = {
    'stok_kod': TextEditingController(),
    'stok_adi': TextEditingController(),
    'barkod': TextEditingController(),
    'barkod2': TextEditingController(),
    'barkod3': TextEditingController(),
    'barkod4': TextEditingController(),
    'barkod5': TextEditingController(),
    'barkod6': TextEditingController(),
    'barkod7': TextEditingController(),
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
    'metaTitle': TextEditingController(),
    'webLink': TextEditingController(),
    'Fdate': TextEditingController(),
    'Ldate': TextEditingController(),
    'beden': TextEditingController(),
    'kur_dolar': TextEditingController(),
    'kur_euro': TextEditingController(),
    'parite_euro_dolar': TextEditingController(),
    'parite_dolar_euro': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initDatabase();
    // Dolar veya Euro değiştiği an pariteyi hesapla (Sürekli dinleme modu)
    _c['kur_dolar']?.addListener(_kurlariHesapla);
    _c['kur_euro']?.addListener(_kurlariHesapla);
  }

  // Dispose ederken listener'ları temizlemeyi unutma (Bellek sağlığı için)
  @override
  void dispose() {
    _c['kur_dolar']?.removeListener(_kurlariHesapla);
    _c['kur_euro']?.removeListener(_kurlariHesapla);
    _c.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _idSorgula() async {
    // Artik _stokKodController yerine _c['stok_kod'] kullanıyoruz
    String arananKod = _c['stok_kod']?.text.trim() ?? "";

    if (arananKod.isNotEmpty) {
      String? id = await _ocService.urunIdSorgula(arananKod);
      setState(() {
        _ocProductId = id;
      });
      print("Sorgulama yapıldı: $arananKod -> ID: $id");
    } else {
      print("Sorgulama yapılamadı: Stok kodu alanı boş.");
    }
  }

  void _ocBaglantisiniYonet() async {
    if (!_isOcConnected) {
      bool sonuc = await _ocService.baglan(manuelBaslatma: true);
      setState(() {
        _isOcConnected = sonuc; // Servisten gelen gerçek sonucu ata
      });

      if (sonuc) {
        _idSorgula(); // Bağlantı kurulur kurulmaz seçili ürünü sorgula
      }
    } else {
      await _ocService.kapat();
      setState(() {
        _isOcConnected = false;
        _ocProductId = null;
      });
    }
  }

  // SENKRONİZASYON (YÜKLE/GÜNCELLE) DÜZELTİLMİŞ FONKSİYON
  void _ocSenkronizeEt() async {
    bool basarili = false;

    // DÜZELTME: Tüm verileri _c map'inden çekiyoruz
    String kod = _c['stok_kod']?.text ?? "";
    String ad = _c['stok_adi']?.text ?? "";
    String barkod = _c['barkod']?.text ?? "";
    double fiyat =
        double.tryParse(_c['satis']?.text.replaceAll(',', '.') ?? '0') ?? 0;
    int miktar = int.tryParse(_c['miktar']?.text ?? '0') ?? 0;
    String aciklama = _c['metaTitle']?.text ?? "";

    if (_ocProductId == null) {
      basarili = await _ocService.urunEkle(
        model: kod,
        ad: ad,
        barkod: barkod,
        fiyat: fiyat,
        miktar: miktar,
        aciklama: aciklama,
      );
    } else {
      basarili = await _ocService.urunGuncelle(
        productId: _ocProductId!,
        fiyat: fiyat,
        miktar: miktar,
        ad: ad,
      );
    }

    if (basarili) {
      String? yeniId = await _ocService.urunIdSorgula(kod.trim());
      if (!mounted) return;
      setState(() => _ocProductId = yeniId);
      _mesajGoster("OpenCart İşlemi Başarılı!");
    }
  }
  // ... _stokBilgisiSekmesi içindeki Column yapısı ve yerleşimi gönderdiğin dosyada doğruydu ...
  // Sadece butonların onPressed olaylarının bu yeni fonksiyonlara baktığından emin ol.

  Future<void> _linkiAc(String urlString) async {
    if (urlString.isEmpty) {
      _mesajGoster("Web adresi girilmemiş!", hata: true);
      return;
    }

    // Protokol kontrolü (http/https yoksa ekle)
    String tamUrl = urlString.trim();
    if (!tamUrl.startsWith('http')) {
      tamUrl = 'https://$tamUrl';
    }

    final Uri url = Uri.parse(tamUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _mesajGoster("Link açılamadı: $tamUrl", hata: true);
    }
  }

  void _kurlariHesapla() {
    // Virgülleri noktaya çevirip double'a dönüştür (Lazarus: StrToFloat)
    double usd =
        double.tryParse(_c['kur_dolar']!.text.replaceAll(',', '.')) ?? 0;
    double eur =
        double.tryParse(_c['kur_euro']!.text.replaceAll(',', '.')) ?? 0;

    if (usd > 0 && eur > 0) {
      double eurUsd = eur / usd;
      double usdEur = usd / eur;

      setState(() {
        // Değerleri yazarken anlık olarak UI'ı güncelliyoruz
        _c['parite_euro_dolar']?.text = eurUsd.toStringAsFixed(4);
        _c['parite_dolar_euro']?.text = usdEur.toStringAsFixed(4);
      });
    }
  }

  void _fiyatlariDovizeCevir() {
    // 1. Değerleri al (Virgül/Nokta temizliği yaparak)
    double tlSatis =
        double.tryParse(_c['satis']!.text.replaceAll(',', '.')) ?? 0;
    double kurUsd =
        double.tryParse(_c['kur_dolar']!.text.replaceAll(',', '.')) ?? 0;
    double kurEur =
        double.tryParse(_c['kur_euro']!.text.replaceAll(',', '.')) ?? 0;

    if (tlSatis <= 0) {
      _mesajGoster("Önce geçerli bir TL Satış Fiyatı giriniz!", hata: true);
      return;
    }

    if (kurUsd <= 0 || kurEur <= 0) {
      _mesajGoster("Kurlar henüz çekilmemiş veya girilmemiş!", hata: true);
      return;
    }

    // 2. Hesaplamaları yap ve editlere yaz
    setState(() {
      // Dolar Satış Fiyatımız = TL Satış / Dolar Kuru
      double dolarSatis = tlSatis / kurUsd;
      _c['dolar_satis']?.text = dolarSatis.toStringAsFixed(2);

      // Euro Satış Fiyatımız = TL Satış / Euro Kuru
      double euroSatis = tlSatis / kurEur;
      _c['euro_satis']?.text = euroSatis.toStringAsFixed(2);

      // Bilgi amaçlı pariteleri de yazalım
      _c['parite_euro_dolar']?.text = (kurEur / kurUsd).toStringAsFixed(4);
      _c['parite_dolar_euro']?.text = (kurUsd / kurEur).toStringAsFixed(4);
    });

    _mesajGoster("Döviz fiyatları başarıyla hesaplandı.");
  }

  Widget _tabFiyatlar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _input("TL Satış Fiyatı", 'satis', 120),
              _input("Dolar Kuru", 'kur_dolar', 120),
              _input("Euro Kuru", 'kur_euro', 120),

              // HESAPLA BUTONU (Lazarus'taki "Fiyatları Çevir" butonu gibi)
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Döviz Karşılıkları",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _input("Dolar Satış (\$)", 'dolar_satis', 120, readOnly: true),
              _input("Euro Satış (€)", 'euro_satis', 120, readOnly: true),
              _input(
                "EUR/USD Parite",
                'parite_euro_dolar',
                120,
                readOnly: true,
              ),
              _input(
                "USD/EUR Parite",
                'parite_dolar_euro',
                120,
                readOnly: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _fiyatlariDovizeCevir, // Sadece tıklandığında çalışır
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(double.infinity, 40),
            ),
            icon: const Icon(Icons.sync_alt),
            label: const Text("Döviz fiyatını Uygula"),
          ),
        ],
      ),
    );
  }

  Future<void> _initDatabase() async {
    try {
      // DİKKAT: openDatabase demiyoruz, DbHelper içindeki hazır bağlantıyı istiyoruz.
      _db = await DbHelper().db;

      if (_db != null && _db!.isOpen) {
        _mesajGoster(">>> Bağlantı başarılı, veriler çekiliyor...");
        setState(() {
          _isDbInitialized = true;
        });
        await _verileriGetir();
      } else {
        throw "Veritabanı bağlantısı açılamadı!";
      }
    } catch (e) {
      // print(">>> KRİTİK HATA: $e");
      _mesajGoster("Bağlantı kurulamadı: $e", hata: true);
    }
  }

  Future<void> _verileriGetir() async {
    if (_db == null) return;

    try {
      // Sorgu sonucunu beklerken (await) hata olursa catch yakalayacak
      final List<Map<String, dynamic>> maps = await _db!.query(
        'STOK',
        orderBy: 'LDATE DESC',
      );

      setState(() {
        _stokListesi = maps.map((item) => Stok.fromMap(item)).toList();
        _filtreliListe = List.from(_stokListesi);
      });
      _mesajGoster(
        ">>> Veriler başarıyla yüklendi: ${_stokListesi.length} adet.",
      );
    } catch (e) {
      //print(">>> Sorgu Hatası: $e");
      _mesajGoster("Liste çekilemedi: $e", hata: true);
      // Hata olsa bile halkayı durdurmak için:
      setState(() {
        _isDbInitialized = true;
      });
    }
  }

  void _aramaYap(String kelime) {
    setState(() {
      if (kelime.isEmpty) {
        _filtreliListe = _stokListesi;
      } else {
        final aranan = kelime.toLowerCase();
        _filtreliListe = _stokListesi.where((stok) {
          final urunAdi = stok.stokAdi.toLowerCase();
          final barkod = stok.barkod.toLowerCase();
          return urunAdi.contains(aranan) || barkod.contains(aranan);
        }).toList();
      }
    });
  }

  void _formuDoldur(Stok urun) {
    setState(() {
      _seciliStok = urun;
      _c['stok_kod']!.text = urun.stokKod ?? "";
      _c['stok_adi']!.text = urun.stokAdi;
      _c['barkod']!.text = urun.barkod;
      _c['barkod2']!.text = urun.barkod2 ?? "";
      _c['barkod3']!.text = urun.barkod3 ?? "";
      _c['barkod4']!.text = urun.barkod4 ?? "";
      _c['barkod5']!.text = urun.barkod5 ?? "";
      _c['barkod6']!.text = urun.barkod6 ?? "";
      _c['barkod7']!.text = urun.barkod7 ?? "";
      _c['alis']!.text = urun.alisFiyati ?? "";
      _c['satis']!.text = urun.satisFiyati ?? "";
      _c['dolar_alis']!.text = urun.dolarAlis ?? "";
      _c['dolar_satis']!.text = urun.dolarSatis ?? "";
      _c['euro_satis']!.text = urun.euroSatis ?? "";
      _c['miktar']!.text = urun.miktar ?? "";
      _c['marj']!.text = urun.marj ?? "";
      _c['kdv']!.text = urun.kdv ?? "";
      _c['lot']!.text = urun.lot ?? "";
      _c['weight']!.text = urun.weight ?? "";
      _c['metaTitle']!.text = urun.metaTitle ?? "";
      _c['webLink']!.text = urun.webLink ?? "";
      _c['Fdate']!.text = urun.Fdate ?? "";
      _c['Ldate']!.text = urun.Ldate ?? "";
      _c['beden']!.text = urun.beden ?? "";
    });
  }

  void _fiyatHesapla() {
    // Try-parse ile sayısal değerleri alıyoruz
    double alis = double.tryParse(_c['alis']?.text ?? '0') ?? 0;
    double marj = double.tryParse(_c['marj']?.text ?? '0') ?? 0;

    if (alis > 0) {
      // Toptan Satış Formülü: Alış + (Alış * Marj / 100)
      double sonSatis = (alis + (alis * marj / 100)).ceil().toDouble();

      setState(() {
        // Satış fiyatını 2 kuruş haneli olarak güncelle
        _c['satis']?.text = sonSatis.toStringAsFixed(2);
      });
    }
  }

  void _yeniUrunHazirla() {
    setState(() {
      _seciliStok = null; // Seçili ürünü sıfırla
      _formAcikMi = true; // Formun görünmesini sağla

      // Tüm metin kutularını boşalt
      _c.forEach((key, controller) {
        controller.clear();
      });

      // Bugünün tarihini al (GÜN.AY.YIL formatında)
      String bugun = DateFormat('dd.MM.yyyy').format(DateTime.now());

      // Zorunlu alanlara varsayılan değerler at (Lazarus'taki gibi)

      _c['miktar']?.text = "100";
      _c['kdv']?.text = "10";
      _c['marj']?.text = "12";
      _c['lot']?.text = "3";
      _c['weight']?.text = "1";
      _c['Fdate']?.text = bugun; // İlk Giriş
      _c['Ldate']?.text =
          bugun; // Son Giriş (Yeni üründe ilk girişle aynı olur)

      // Sekmeyi en başa (Stok Bilgisi) al
      _tabController.animateTo(0);
    });

    _mesajGoster("Yeni ürün girişi için form hazırlandı.");
  }

  Future<void> _stokSil(int id) async {
    if (_db == null) return;

    try {
      await _db!.delete('STOK', where: 'KIMLIK = ?', whereArgs: [id]);

      setState(() {
        _seciliStok = null; // Silinen ürünü seçimden kaldır
        _formAcikMi = false; // Formu kapat
      });

      _verileriGetir(); // Listeyi güncelle
      _mesajGoster("Ürün başarıyla silindi.");
    } catch (e) {
      _mesajGoster("Silme hatası: $e");
    }
  }

  void _silmeOnayiAl() {
    if (_seciliStok == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ürünü Sil"),
          content: Text(
            "'${_seciliStok!.stokAdi}' isimli ürünü silmek istediğinize emin misiniz?",
          ),
          actions: [
            TextButton(
              child: const Text("Vazgeç"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "Evet, Sil",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
                _stokSil(_seciliStok!.id!); // Silme işlemini başlat
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _stokKaydet() async {
    if (_db == null) return;

    // Zorunlu alan kontrolü
    if (_c['stok_adi']!.text.trim().isEmpty) {
      _mesajGoster("Hata: Stok adı boş bırakılamaz!");
      return;
    }

    // Barkod boşsa Stok Kodu'nu barkod yap (Lazarus'taki otomatik tamamlama)
    if (_c['barkod']!.text.isEmpty) {
      _c['barkod']!.text = _c['stok_kod']!.text;
    }

    // Otomatik tamamlama mantığı
    if (_c['weight']!.text.isEmpty) _c['weight']!.text = "1";
    if (_c['min_adet']!.text.isEmpty) _c['min_adet']!.text = "1";
    if (_c['lot']!.text.isEmpty) _c['lot']!.text = "3";
    if (_c['miktar']!.text.isEmpty) _c['miktar']!.text = "100";
    if (_c['barkod']!.text.isEmpty) _c['barkod']!.text = _c['stok_kod']!.text;
    // Ldate ve Fdate boşsa, bugünün tarihini atıyoruz
    String bugun = DateTime.now().toIso8601String().split('T')[0];
    if (_c['Fdate']!.text.isEmpty) _c['Fdate']!.text = bugun;
    if (_c['Ldate']!.text.isEmpty) _c['Ldate']!.text = bugun;
    _c['Ldate']!.text = bugun;

    // Model üzerinden veriyi hazırla
    Stok urun = Stok(
      id: _seciliStok?.id, // null ise INSERT, doluysa UPDATE yapar
      stokKod: _c['stok_kod']!.text,
      stokAdi: _c['stok_adi']!.text,
      barkod: _c['barkod']!.text,
      barkod2: _c['barkod2']!.text,
      barkod3: _c['barkod3']!.text,
      alisFiyati: _c['alis']!.text,
      satisFiyati: _c['satis']!.text,
      dolarAlis: _c['dolar_alis']!.text,
      dolarSatis: _c['dolar_satis']!.text,
      euroSatis: _c['euro_satis']!.text,
      miktar: _c['miktar']!.text,
      marj: _c['marj']!.text,
      kdv: _c['kdv']!.text,
      weight: _c['weight']!.text,
      lot: _c['lot']!.text,
      metaTitle: _c['metaTitle']!.text,
      webLink: _c['webLink']!.text,
      Fdate: _c['Fdate']!.text,
      Ldate: _c['Ldate']!.text,
      beden: _c['beden']!.text,
    );

    final row = urun.toMap();

    try {
      if (_seciliStok == null) {
        // YENİ EKLEME (INSERT)
        await _db!.insert('STOK', row);
        _mesajGoster("Ürün başarıyla kaydedildi.");
      } else {
        // GÜNCELLEME (UPDATE)
        await _db!.update(
          'STOK',
          row,
          where: 'KIMLIK = ?',
          whereArgs: [_seciliStok!.id],
        );
        _mesajGoster("Değişiklikler kaydedildi.");
      }

      _verileriGetir(); // Listeyi yenile
    } catch (e) {
      _mesajGoster("Veritabanı hatası: $e");
    }
  }

  // Mesaj gösterme fonksiyonu (Lazarus: ShowMessage veya Application.MessageBox gibi)
  void _mesajGoster(String mesaj, {bool hata = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: hata
            ? Colors.red
            : Colors.green, // Hata ise kırmızı, değilse yeşil
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MrmDesk Stok Yönetimi'),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (_seciliStok !=
              null) // Sadece mevcut bir ürün seçiliyse silme butonu çıksın
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Ürünü Sil",
              onPressed: _silmeOnayiAl,
            ),
          IconButton(
            icon: const Icon(Icons.currency_exchange, color: Colors.amber),
            tooltip: "Canlı Kurları Çek",
            onPressed: _guncelKurlariCek,
          ),

          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: "Yeni Ürün Ekle",
            onPressed: _yeniUrunHazirla,
          ),

          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Kaydet",
            onPressed: _stokKaydet,
          ),
        ],
      ),
      body: !_isDbInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Veritabanı bağlantısı kuruluyor..."),
                ],
              ),
            )
          : Row(
              children: [
                // --- SOL LİSTE (Arama ve Ürünler) ---
                Container(
                  width: 500, // Genişliği biraz optimize ettim
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _aramaController,
                          onChanged: _aramaYap,
                          decoration: InputDecoration(
                            labelText: "Hızlı Ara (Ad veya Barkod)",
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _aramaController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _aramaController.clear();
                                      _aramaYap("");
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filtreliListe.length,
                          itemBuilder: (context, index) {
                            final stok = _filtreliListe[index];
                            return ListTile(
                              dense: false,
                              visualDensity: const VisualDensity(
                                horizontal: 0,
                                vertical: -4,
                              ),
                              title: Text(
                                stok.stokAdi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: Text(
                                "Barkod: ${stok.barkod} | Stok: ${stok.miktar} |  Satış: ${stok.satisFiyati} TL | ${stok.dolarSatis} \$ | ${stok.euroSatis} €",
                              ),
                              selected: _seciliStok?.id == stok.id,
                              selectedTileColor: Colors.blue.withValues(
                                alpha: 0.1,
                              ),
                              onTap: () async {
                                // 1. Sadece 'varsa' uyandırır, yoksa zorlamaz (baglan içindeki kontrol sayesinde)
                                bool baglantiVarMi = await _ocService.baglan();

                                // 2. YEREL İŞLEMLER (Her zaman çalışır)
                                _formuDoldur(stok);
                                setState(() {
                                  _formAcikMi = false;
                                  _seciliStok = stok;
                                  _isOcConnected =
                                      baglantiVarMi; // Bağlantı durumunu güncel tutalım
                                });

                                // 3. OPENCART İŞLEMİ (Sadece bağlantı varsa)
                                if (baglantiVarMi) {
                                  _idSorgula();
                                } else {
                                  print(
                                    "OpenCart bağlantısı aktif değil, sadece yerel bilgiler yüklendi.",
                                  );
                                  // Burada SnackBar göstermene gerek yok, çünkü bağlantı kurmamak senin tercihin.
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --- SAĞ DETAY PANELİ ---
                Expanded(
                  child: (_seciliStok == null && !_formAcikMi)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Düzenlemek için listeden bir ürün seçin\nveya yeni eklemek için (+) butonuna basın.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: Colors.blueAccent,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blueAccent,
                              tabs: const [
                                Tab(text: "Stok Bilgisi"),
                                Tab(text: "Barkodlar"),
                                Tab(text: "Döviz & Fiyatlar"),
                                Tab(text: "Döviz Kurları"),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _stokBilgisiSekmesi(),
                                  _barkodlarSekmesi(),
                                  _tabFiyatlar(),
                                  _dovizBolumu(),
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

  Widget _statusBar() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Tooltip(
          message:
              "Veritabanı: ${DbHelper.dbPath}\nResim: ${DbHelper.resimAnaYolu}",
          child: Text(
            "Aktif Bağlantı: ${DbHelper.dbPath.split('\\').last}", // Sadece dosya adını gösterir
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guncelKurlariCek() async {
    try {
      // Ücretsiz ve hızlı bir döviz API'si (TCMB bazlı kurlar için alternatif)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/TRY'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];

        // API 1 TRY = X USD şeklinde verdiği için tersini alıyoruz (1 USD = ? TRY)
        double usdKur = 1 / rates['USD'];
        double eurKur = 1 / rates['EUR'];

        setState(() {
          _c['kur_dolar']?.text = usdKur.toStringAsFixed(4);
          _c['kur_euro']?.text = eurKur.toStringAsFixed(4);
        });

        // Zaten addListener kullandığımız için _kurlariHesapla() otomatik tetiklenecek!
        _mesajGoster(
          "Kurlar güncellendi: USD: ${usdKur.toStringAsFixed(2)} - EUR: ${eurKur.toStringAsFixed(2)}",
        );
      } else {
        _mesajGoster("Kur çekme hatası: Sunucu cevap vermedi", hata: true);
      }
    } catch (e) {
      _mesajGoster("Bağlantı hatası: İnternetini kontrol et!", hata: true);
    }
  }

  Widget _dovizBolumu() {
    return Column(
      children: [
        const Text(
          "Güncel Döviz & Parite",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _input(
              "Dolar Alış (₺)",
              'kur_dolar',
              120,
              onChanged: (v) => _kurlariHesapla(),
            ),
            _input(
              "Euro Alış (₺)",
              'kur_euro',
              120,
              onChanged: (v) => _kurlariHesapla(),
            ),
            const SizedBox(width: 20),
            _input("EUR/USD Parite", 'parite_euro_dolar', 120, readOnly: true),
            _input("USD/EUR Parite", 'parite_dolar_euro', 120, readOnly: true),

            // Kurları Getir Butonu (Lazarus: SpeedButton gibi)
            ElevatedButton.icon(
              onPressed: () => _guncelKurlariCek(),
              icon: const Icon(Icons.download),
              label: const Text("Kurları Güncelle"),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _stokBilgisiSekmesi() {
    // --- 1. Dinamik Yol Hesaplama (Hassas Ayar) ---
    String stokAdi = _c['stok_adi']!.text;
    String stokKod = _c['stok_kod']!.text;

    // Markayı alırken hata payını azaltıyoruz
    String marka = "Genel";
    if (stokAdi.isNotEmpty) {
      marka = stokAdi
          .split(' ')[0]
          .toUpperCase(); // Büyük harfe zorla (Klasör ismi için)
    }

    List<String> uzantilar = ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG'];

    // DbHelper'dan gelen yolun sonuna \ eklediğimizden emin oluyoruz
    String anaDizin = DbHelper.resimAnaYolu;
    if (!anaDizin.endsWith('\\')) anaDizin += '\\';

    String bulunanTamYol = '';

    // Döngü ile dosyayı arıyoruz
    for (String uzanti in uzantilar) {
      // Örn: C:\wamp\www\OC3\image\catalog\SAMSUNG\A50.jpg
      String testYolu = '$anaDizin$marka\\$stokKod$uzanti';
      if (File(testYolu).existsSync()) {
        bulunanTamYol = testYolu;
        break;
      }
    }

    // Eğer marka klasöründe yoksa, doğrudan catalog içinde aramayı dene (Alternatif)
    if (bulunanTamYol.isEmpty) {
      for (String uzanti in uzantilar) {
        String testYolu = '$anaDizin$stokKod$uzanti';
        if (File(testYolu).existsSync()) {
          bulunanTamYol = testYolu;
          break;
        }
      }
    }

    File resimDosyasi = File(bulunanTamYol);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL TARAF: Inputlar
          Expanded(
            flex: 1,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _input("Stok Kodu", 'stok_kod', 190),
                _input("Stok Adı", 'stok_adi', 400),
                const Divider(),
                _input("Barkod", 'barkod', 190),
                _input("Barkod 2", 'barkod2', 195),
                _input("Barkod 3", 'barkod3', 195),
                const Divider(),
                _input("Alış (TL)", 'alis', 120),
                _input("Marj %", 'marj', 120),
                _input("Satış (TL)", 'satis', 120),
                const Divider(),
                _input("Dolar Alış (\$)", 'dolar_alis', 120),
                _input("Dolar Satış (\$)", 'dolar_satis', 120),
                _input("Euro Satış (€)", 'euro_satis', 120),

                const Divider(),
                _input("Miktar", 'miktar', 120),
                _input("KDV %", 'kdv', 120),
                _input("Beden", 'beden', 120),
                _input("Lot", 'lot', 120),
                _input("Ağırlık", 'weight', 120),
                const Divider(),
                _tabFiyatlar(),
                const Divider(),
                _input("Meta Title", 'metaTitle', 380),

                _input("İlk Giriş Tarihi", 'Fdate', 380),
                _input("Son Giriş Tarihi", 'Ldate', 380),
                // _input("Web Link", 'webLink', 800),
                TextField(
                  controller: _c['webLink'],
                  decoration: InputDecoration(
                    labelText: "Web Link",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _linkiAc(_c['webLink']?.text ?? ""),
                    ),
                  ),
                ),

                // 1. BUTON: OPENCARTBAĞLANTI BUTONU
                const SizedBox(height: 1),
                ElevatedButton.icon(
                  onPressed: _ocBaglantisiniYonet,
                  icon: Icon(_isOcConnected ? Icons.link : Icons.link_off),
                  label: Text(
                    _isOcConnected
                        ? "OPENCART BAĞLANTISI AKTİF"
                        : "OPENCART'A BAĞLAN",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOcConnected
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),

                // 2. BUTON: OPENCART SENKRONİZASYONU BUTONU (Sadece bağlantı varken görünür)
                const SizedBox(height: 1),
                if (_isOcConnected)
                  ElevatedButton.icon(
                    onPressed: _ocSenkronizeEt,
                    // ID yoksa "Yükle", varsa "Güncelle" ikonu ve yazısı
                    icon: Icon(
                      _ocProductId == null ? Icons.cloud_upload : Icons.sync,
                    ),
                    label: Text(
                      _ocProductId == null
                          ? "ÜRÜNÜ OPENCART'A YÜKLE"
                          : "BİLGİLERİ GÜNCELLE",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),

                // 3. BUTON: STOK KAYDET/ GÜNCELLE BUTONU
                const SizedBox(height: 1),
                ElevatedButton.icon(
                  onPressed: _stokKaydet,
                  icon: const Icon(Icons.save),
                  label: const Text("KAYDET / GÜNCELLE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),

          // SAĞ TARAF: Resim Önizleme
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  //Resim gösteren kutu
                  height: 350, // Biraz daha büyüttüm
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: bulunanTamYol.isNotEmpty && resimDosyasi.existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            resimDosyasi,
                            fit: BoxFit.contain,
                            // Dosya sistemde var ama resim bozuksa:
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.orange,
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
                            Text(
                              "Resim Bulunamadı",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              "$marka\\$stokKod",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                ),

                if (_isOcConnected && _ocProductId != null) ...[
                  const SizedBox(height: 15),
                  _buildOpenCartKarsilastirmaPaneli(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barkodlarSekmesi() {
    if (_seciliStok == null) {
      return const Center(child: Text("Lütfen bir ürün seçin."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ek Barkod Tanımları",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),
          // Lazarus'taki yan yana dizilen Edit'ler gibi Wrap kullanıyoruz
          Wrap(
            spacing: 16, // Yatay boşluk
            runSpacing: 16, // Dikey boşluk
            children: [
              _input("Ek Barkod 3", 'barkod4', 220),
              _input("Ek Barkod 4", 'barkod5', 220),
              _input("Ek Barkod 5", 'barkod6', 220),
              _input("Ek Barkod 6", 'barkod7', 220),
            ],
          ),
          const Divider(height: 50),
          _statusBar(),
          // Bilgilendirme veya ekstra butonlar buraya gelebilir
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Bu barkodlar arama sonuçlarında da geçerlidir.",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    String key,
    double width, {
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        // İşte çift tıklama özelliği burada tanımlanıyor
        onDoubleTap: () {
          if (key == 'metaTitle') {
            setState(() {
              // Stok adı boş değilse Meta Title'a kopyala
              _c['metaTitle']?.text = _c['stok_adi']?.text ?? "";
            });
            _mesajGoster("Stok adı Meta Title alanına kopyalandı.");
          }
        },
        child: TextFormField(
          controller: _c[key],
          // --- ENTER'A BASINCA SONRAKİNE GEÇ ---
          textInputAction:
              TextInputAction.next, // Klavyede "İleri" butonu gösterir
          onFieldSubmitted: (value) {
            // Bu komut Delphi'deki SelectNext(ActiveControl, True, True) ile aynı işi yapar
            FocusScope.of(context).nextFocus();
          },
          // ------------------------------------
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            // Kullanıcıya çift tıklayabileceğini hissettirmek için bir ipucu (isteğe bağlı)
            suffixIcon: key == 'metaTitle'
                ? const Icon(Icons.copy, size: 16)
                : null,
          ),
          onChanged: (value) {
            if (key == 'alis' || key == 'marj') {
              _fiyatHesapla();
            }
            if (key == 'stok_kod' || key == 'stok_adi') {
              setState(() {}); // Resim önizlemesini yenilemek için
            }
          },
        ),
      ),
    );
  }

  // BU İKİSİ BAŞKA FONKSİYONLARIN İÇİNDE OLMAMALI, AYRI OLMALI
  Widget _buildOpenCartKarsilastirmaPaneli() {
    if (!_isOcConnected || _ocProductId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _ocService.urunDetayGetir(_ocProductId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          );
        }

        final ocData = snapshot.data;
        if (ocData == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_sync, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "OpenCart Canlı: ${ocData['name'] ?? ''}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.blue),
              Wrap(
                spacing: 30,
                runSpacing: 12,
                children: [
                  _ocVeriSutunu(
                    "STOK MİKTARI",
                    "${ocData['quantity'] ?? 0} Adet",
                    Icons.inventory,
                  ),
                  _ocVeriSutunu(
                    "FİYAT",
                    "${double.tryParse(ocData['price'].toString())?.toStringAsFixed(2) ?? '0.00'} TL",
                    Icons.sell,
                  ),
                  _ocVeriSutunu(
                    "BARKOD / SKU",
                    "${ocData['ean'] ?? '-'} / ${ocData['sku'] ?? '-'}",
                    Icons.qr_code,
                  ),

                  _ocVeriSutunu(
                    "BEDEN / LOT",
                    "${ocData['location'] ?? '-'}",
                    Icons.straighten,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ocVeriSutunu(String baslik, String deger, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey),
            const SizedBox(width: 4),
            Text(
              baslik,
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ],
        ),
        Text(
          deger,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
