// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/opencart_controller.dart';
import '../controllers/printer_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/stock_form_controller.dart';
import '../controllers/stock_list_controller.dart';
import '../models/stok_model.dart';
import '../services/db_helper.dart';
import '../services/kur_service.dart';
import '../utils/app_theme.dart';
import '../utils/ui_utils.dart';

import 'widgets/ayarlar_tab_widget.dart';
import 'widgets/barkodlar_tab_widget.dart';
import 'widgets/custom_input_widget.dart';
import 'widgets/doviz_fiyatlar_tab_widget.dart';
import 'widgets/kur_fiyat_alani_widget.dart';
import 'widgets/opencart_preview_widget.dart';
import 'widgets/resim_goster_widget.dart';
import 'widgets/sol_urun_listesi_widget.dart';
import 'widgets/stok_detay_form_widget.dart';
import 'widgets/toplu_duzenleme_tab_widget.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Güvenlik: Sadece localhost, yerel ağ veya bilinen sunucu ipleri için SSL hatalarını yoksay.
        if (host == 'localhost' || 
            host == '127.0.0.1' || 
            host.startsWith('192.168.') || 
            host.startsWith('10.') || 
            host == '93.89.225.215') {
          return true;
        }
        return false;
      };
  }
}

class StokAnaSayfa extends StatefulWidget {
  const StokAnaSayfa({super.key});

  @override
  State<StokAnaSayfa> createState() => _StokAnaSayfaState();
}

class _StokAnaSayfaState extends State<StokAnaSayfa>
    with SingleTickerProviderStateMixin {
  late final StockFormController stockFormController;
  late final StockListController stockListController;
  late final OpenCartController openCartController;
  late final PrinterController printerController;
  late final SettingsController settingsController;

  final DbHelper dbHelper = DbHelper();
  final KurService _kurService = KurService(); // Canlı Döviz Kur Servisi

  late TabController _tabController; // Sekme kontrolcüsü

  // Veritabanı bağlantısının tamamlanma durumu StockListController üzerinden takip ediliyor
  // Paylaşılacak fiyat verileri seçimleri
  final RxBool _seciliTl = true.obs;
  final RxBool _seciliEuro = false.obs;
  final RxBool _seciliDolar = false.obs;

  final TextEditingController _adetController = TextEditingController(
    text: "1",
  );
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  Timer? _aramaTimer;

  @override
  void initState() {
    super.initState();
    settingsController = Get.put(SettingsController());
    stockFormController = Get.put(StockFormController());
    stockListController = Get.put(StockListController());
    openCartController = Get.put(OpenCartController());
    printerController = Get.put(PrinterController());
    // SSL Sertifika hatalarını (özellikle yerel wamp / server bağlantıları için) küresel olarak yok sayıyoruz
    HttpOverrides.global = MyHttpOverrides();

    _tabController = TabController(length: 5, vsync: this);

    _guncelKurlariCek(); // Kurları başlangıçta çek

    settingsController.c['kur_dolar']?.addListener(
      stockFormController.kurlariHesapla,
    ); // Dolar kuru değiştiğinde pariteyi tetikle
    settingsController.c['kur_euro']?.addListener(
      stockFormController.kurlariHesapla,
    ); // Euro kuru değiştiğinde pariteyi tetikle
  }

  @override
  void dispose() {
    settingsController.c['kur_dolar']?.removeListener(
      stockFormController.kurlariHesapla,
    );
    settingsController.c['kur_euro']?.removeListener(
      stockFormController.kurlariHesapla,
    );
    _adetController.dispose();
    _tabController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    _aramaTimer?.cancel();
    Get.delete<PrinterController>();
    Get.delete<OpenCartController>();
    Get.delete<StockListController>();
    Get.delete<StockFormController>();
    Get.delete<SettingsController>();
    super.dispose();
  }

  void _aramaOdaklan() {
    stockListController.aramaFocusNode.requestFocus();
    stockListController.aramaController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: stockListController.aramaController.text.length,
    );
  }

  void _aramaTemizle() {
    if (stockListController.aramaController.text.isNotEmpty) {
      stockListController.aramaController.clear();
      _aramaYap("");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => stockListController.isDbInitialized.value
        ? CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.f2): _yeniUrunHazirla,
              const SingleActivator(LogicalKeyboardKey.f3): _aramaOdaklan,
              const SingleActivator(LogicalKeyboardKey.keyF, control: true): _aramaOdaklan,
              const SingleActivator(LogicalKeyboardKey.f5): () async {
                await _verileriGetir();
                await _guncelKurlariCek();
              },
              const SingleActivator(LogicalKeyboardKey.keyS, control: true): _stokKaydet,
              const SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
                if (stockFormController.seciliStok.value != null) {
                  _barkodBasimiBaslat(context);
                }
              },
              const SingleActivator(LogicalKeyboardKey.keyD, control: true): _stokDataUrunKopyala,
              const SingleActivator(LogicalKeyboardKey.delete): () {
                if (stockFormController.seciliStok.value != null) {
                  _stokSilOnayli();
                }
              },
              const SingleActivator(LogicalKeyboardKey.escape): _aramaTemizle,
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: AppColors.bgLight,
                appBar: AppBar(
                  toolbarHeight: 52,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: AppColors.borderLight),
                  ),
                  title: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Uygulama Logosu & Başlık
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Stok Takip & Yönetim",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _openCartStatusBadge(),
                      ],
                    ),
                  ),
                  actions: [
                    _headerActionButton(
                      icon: Icons.sync_rounded,
                      label: "Yenile",
                      shortcut: "F5",
                      onPressed: () async => await _verileriGetir(),
                    ),
                    _headerActionButton(
                      icon: Icons.currency_exchange_rounded,
                      label: "Kurlar",
                      onPressed: _guncelKurlariCek,
                    ),
                    _headerActionButton(
                      icon: Icons.copy_rounded,
                      label: "Kopyala",
                      shortcut: "Ctrl+D",
                      onPressed: _stokDataUrunKopyala,
                    ),
                    _headerActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: "Yeni Ürün",
                      shortcut: "F2",
                      isAccent: true,
                      onPressed: _yeniUrunHazirla,
                    ),
                    _headerActionButton(
                      icon: Icons.save_rounded,
                      label: "Kaydet",
                      shortcut: "Ctrl+S",
                      isPrimary: true,
                      onPressed: _stokKaydet,
                    ),
                    Obx(
                      () => stockFormController.seciliStok.value == null
                          ? const SizedBox.shrink()
                          : _headerActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: "Sil",
                              shortcut: "Del",
                              isDanger: true,
                              onPressed: _stokSilOnayli,
                            ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: "Programdan Çıkış Yap",
                      icon: const Icon(Icons.power_settings_new_rounded, color: AppColors.danger, size: 22),
                      onPressed: () => _cikisOnayi(context),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // --- 1. KOLON: ANA ÜRÜN LİSTESİ ---
                          Container(
                            width: 380,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                right: BorderSide(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Obx(() => _buildSolUrunListesi()),
                          ),

                          // --- 2. KOLON: TAB YAPISI (Orta) ---
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Container(
                                  color: Colors.white,
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: AppColors.primary,
                                    unselectedLabelColor: AppColors.textSecondary,
                                    indicatorColor: AppColors.primary,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    isScrollable: true,
                                    tabs: const [
                                      Tab(text: "Stok Bilgisi"),
                                      Tab(text: "Barkodlar"),
                                      Tab(text: "Döviz & Fiyatlar"),
                                      Tab(text: "Bul ve Değiştir"),
                                      Tab(text: "Ayarlar"),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _stokBilgisiSekmesi(),
                                      Obx(() => BarkodlarTabWidget(
                                        isStokSelected: stockFormController.seciliStok.value != null,
                                        stokAdi: stockFormController.c['stok_adi']?.text ?? '',
                                        satisFiyati: stockFormController.c['satis']?.text ?? '0',
                                        basilacakBarkodDegeri: stockFormController.c[stockFormController.basilacakBarkodKey.value]?.text ?? '',
                                        basilacakBarkodKey: stockFormController.basilacakBarkodKey.value,
                                        onBasilacakBarkodKeyChanged: (k) => stockFormController.basilacakBarkodKey.value = k,
                                        buildInput: _input,
                                        yaziciListesi: printerController.yaziciListesi.toList(),
                                        seciliYazici: printerController.seciliYazici.value,
                                        onYaziciChanged: (val) {
                                          if (val != null) {
                                            printerController.seciliYazici.value = val;
                                          }
                                        },
                                        adetController: _adetController,
                                        barkodBasimiBaslat: _barkodBasimiBaslat,
                                      )),
                                      Obx(() => DovizFiyatlarTabWidget(
                                        buildInput: _input,
                                        fiyatlariDovizeCevir: () => stockFormController.fiyatlariDovizeCevir(),
                                        sabitfiyatlariDovizeCevir: () => stockFormController.sabitfiyatlariDovizeCevir(),
                                        guncelKurlariCek: _guncelKurlariCek,
                                        sabitAyarlariYaz: settingsController.sabitAyarlariYaz,
                                        isStokSelected: stockFormController.seciliStok.value != null,
                                        stokAdi: stockFormController.c['stok_adi']?.text ?? '',
                                        satisFiyati: stockFormController.c['satis']?.text ?? '0',
                                        dolarSatis: stockFormController.c['dolar_satis']?.text ?? '0',
                                        euroSatis: stockFormController.c['euro_satis']?.text ?? '0',
                                      )),
                                      TopluDuzenlemeTabWidget(
                                        filtreliSonuclarLength: stockListController.filtreliSonuclar.length,
                                        solHizliAramaListesi: _solHizliAramaListesi(),
                                        findController: _findController,
                                        onHizliAra: _hizliAra,
                                        replaceController: _replaceController,
                                        onTopluDegistir: _topluDegistirIslemi,
                                      ),
                                      _ayarlarSekmesi(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- 3. KOLON: RESİM ALANI (En Sağ) ---
                          Obx(
                            () => (stockFormController.seciliStok.value != null ||
                                    stockListController.formAcikMi.value)
                                ? Container(
                                    width: 300,
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: AppColors.borderLight,
                                        ),
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Obx(() => ResimGosterWidget(
                                        stokAdi: stockFormController.c['stok_adi']?.text ?? "",
                                        stokKod: stockFormController.c['stok_kod']?.text ?? "",
                                        resimAnaYolu: DbHelper.resimAnaYolu,
                                        fiyatTl: stockFormController.c['satis']?.text ?? '0',
                                        fiyatEuro: stockFormController.c['euro_satis']?.text ?? '0',
                                        fiyatDolar: stockFormController.c['dolar_satis']?.text ?? '0',
                                        onWhatsappIlePaylas: _whatsappIlePaylas,
                                        seciliTl: _seciliTl.value,
                                        seciliEuro: _seciliEuro.value,
                                        seciliDolar: _seciliDolar.value,
                                        onSeciliTlChanged: (v) => _seciliTl.value = v,
                                        onSeciliEuroChanged: (v) => _seciliEuro.value = v,
                                        onSeciliDolarChanged: (v) => _seciliDolar.value = v,
                                        isOcConnected: openCartController.isOcConnected.value,
                                        onOcBaglantisiniYonet: _ocBaglantisiniYonet,
                                        onStokKaydet: _stokKaydet,
                                        onStokSilOnayli: _stokSilOnayli,
                                        onStokDataUrunKopyala: _stokDataUrunKopyala,
                                        buildInput: _input,
                                        webLinkController: stockFormController.c['webLink']!,
                                        onLinkiAc: _linkiAc,
                                      )),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    _statusBar(context),
                  ],
                ),
              ),
            ),
          )
        : const Scaffold(body: Center(child: CircularProgressIndicator())));
  }

  Widget _openCartStatusBadge() {
    return Obx(() {
      final bool isConnected = openCartController.isOcConnected.value;
      return InkWell(
        onTap: _ocBaglantisiniYonet,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: isConnected ? "OpenCart Bağlantısını Kes" : "OpenCart'a Bağlan",
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected ? AppColors.success : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? AppColors.success : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? "OC3 Bağlı" : "OC3 Çevrimdışı",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _headerActionButton({
    required IconData icon,
    required String label,
    String? shortcut,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isAccent = false,
    bool isDanger = false,
  }) {
    Color bg;
    Color fg;
    BorderSide border;

    if (isPrimary) {
      bg = AppColors.primary;
      fg = Colors.white;
      border = BorderSide.none;
    } else if (isAccent) {
      bg = AppColors.secondary.withValues(alpha: 0.12);
      fg = AppColors.secondary;
      border = BorderSide(color: AppColors.secondary.withValues(alpha: 0.3), width: 1);
    } else if (isDanger) {
      bg = AppColors.danger.withValues(alpha: 0.1);
      fg = AppColors.danger;
      border = BorderSide(color: AppColors.danger.withValues(alpha: 0.3), width: 1);
    } else {
      bg = Colors.white;
      fg = AppColors.textPrimary;
      border = const BorderSide(color: AppColors.borderLight, width: 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: Tooltip(
        message: shortcut != null ? "$label ($shortcut)" : label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (shortcut != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shortcut,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _cikisOnayi(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış"),
        content: const Text("Programı kapatmak istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => exit(0),
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );
  }

  void _topluDegistirIslemi() async {
    String eskiKelime = _findController.text.trim();
    String yeniKelime = _replaceController.text.trim();

    if (eskiKelime.isEmpty || stockListController.filtreliSonuclar.isEmpty) {
      UiUtils.showMessage("Önce değiştirilecek geçerli bir kelime aratın.", hata: true);
      return;
    }

    bool? onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Toplu Değişiklik Onayı"),
        content: Text(
          "Şu anda listede görünen ${stockListController.filtreliSonuclar.length} adet kayıtta "
          "'$eskiKelime' kelimesi '$yeniKelime' olarak değiştirilecek.\n\n"
          "Emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Evet, Değiştir"),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final etkilenenSatir = await stockListController.topluIsimGuncelleVeYenile(
        eskiKelime,
        yeniKelime,
      );

      UiUtils.showMessage("$etkilenenSatir kayıt başarıyla güncellendi.");

      _findController.clear();
      _replaceController.clear();
      // setState kaldırıldı, UI zaten dinliyor.
    } catch (e) {
      UiUtils.showMessage("Hata oluştu: $e", hata: true);
    }
  }

  Widget _solHizliAramaListesi() {
    return Obx(() => ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: stockListController.filtreliSonuclar.length,
      itemBuilder: (context, index) {
        final urun = stockListController.filtreliSonuclar[index];
        return ListTile(
          title: Text(urun['STOK_ADI'] ?? ""),
          subtitle: Text(urun['STOK_KOD'] ?? ""),
        );
      },
    ));
  }

  void _hizliAra(String kelime) {
    if (_aramaTimer?.isActive ?? false) _aramaTimer!.cancel();

    if (kelime.trim().length < 2) {
      if (stockListController.filtreliSonuclar.isNotEmpty) {
        stockListController.filtreliSonuclar.clear();
      }
      return;
    }

    _aramaTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final sonuclar = await dbHelper.stokAra(kelime.trim());
        if (mounted) {
          stockListController.filtreliSonuclar.assignAll(sonuclar);
        }
      } catch (e) {
        print("Hızlı arama hatası: $e");
      }
    });
  }

  void _barkodBasimiBaslat(
    BuildContext context, {
    String? tiklananBarkodKey,
  }) async {
    String hedefKey = tiklananBarkodKey ?? 'barkod';

    String barkod = stockFormController.c[hedefKey]?.text.trim() ?? "";
    String ad = stockFormController.c['stok_adi']?.text.trim() ?? "";
    String fiyat = stockFormController.c['satis']?.text.trim() ?? "";
    String miktar = _adetController.text.trim().isEmpty
        ? "1"
        : _adetController.text.trim();

    printerController.barkodBasimiBaslat(
      barkod: barkod,
      ad: ad,
      fiyat: fiyat,
      miktar: miktar,
      hedefKey: hedefKey,
    );
  }



  Future<void> _urunSec(Stok stok) async {
    stockListController.urunSec(
      stok,
      stockFormController.formuDoldur,
      openCartController.connect,
    );

    await openCartController.seciliUrunuYukle(
      autoSync: openCartController.autoSync.value,
    );
  }

  Widget _buildSolUrunListesi() {
    return SolUrunListesiWidget(
      aramaController: stockListController.aramaController,
      aramaFocusNode: stockListController.aramaFocusNode,
      onAramaChanged: _aramaYap,
      onAramaClear: () {
        stockListController.aramaController.clear();
        _aramaYap("");
      },
      seciliSiralama: stockListController.seciliSiralama.value,
      onSiralamaDegistir: (yeni) => stockListController.siralamaDegistir(yeni),
      filtreliListe: stockListController.filtreliListe.toList(),
      seciliStok: stockFormController.seciliStok.value,
      listScrollController: stockListController.listScrollController,
      onUrunTap: (stok) {
        _urunSec(stok);
      },
    );
  }

  Widget _buildBosDurumMesaji() {
    return Center(
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
            "Düzenlemek için ürün seçin...",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _linkiAc(String urlString) async {
    if (urlString.isEmpty) {
      UiUtils.showMessage("Web adresi girilmemiş!", hata: true);
      return;
    }

    String tamUrl = urlString.trim();
    if (!tamUrl.startsWith('http')) {
      tamUrl = 'https://$tamUrl';
    }

    final Uri url = Uri.parse(tamUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      UiUtils.showMessage("Link açılamadı: $tamUrl", hata: true);
    }
  }

  Future<void> _verileriGetir() async {
    await stockListController.verileriGetir();
  }

  /// 7 Farklı Barkod Sütununu Da Kapsayan Dinamik Süzgeç
  void _aramaYap(String kelime) {
    stockListController.aramaYap(kelime);
  }



  void _fiyatHesapla() {
    stockFormController.fiyatHesapla();
  }

  void _dovizGirislefiyatHesapla() {
    stockFormController.fiyatHesapla();
  }

  void _yeniUrunHazirla() {
    stockFormController.formuTemizle();
  }

  void _stokSilOnayli() {
    stockFormController.stokSil(
      stockListController.verileriGetir,
    );
  }

  void _stokDataUrunKopyala() {
    if (stockFormController.kopyaOlarakHazirla() == null) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      stockFormController.stokKodFocusNode.requestFocus();
      stockFormController.c['stok_kod']?.selection =
          const TextSelection.collapsed(offset: 0);

      Future.microtask(() {
        int uzunluk = stockFormController.c['stok_kod']?.text.length ?? 0;
        if (uzunluk > 5) {
          stockFormController.c['stok_kod']?.selection = TextSelection(
            baseOffset: uzunluk - 5,
            extentOffset: uzunluk,
          );
        }
      });
    });
  }

  // 🚀 MÜKERRER BARKOD ÖNLEME SİSTEMİYLE GÜNCELLENEN KAYIT FONKSİYONU
  Future<void> _stokKaydet() async {
    await stockFormController.stokKaydet((s) => _urunSec(s));

    if (openCartController.isOcConnected.value) {
      // Eğer otomatik senkronize seçiliyse veya ürün zaten opencart'ta mevcutsa (güncelleme ise)
      if (openCartController.autoSync.value ||
          openCartController.ocProductId.value != null) {
        await _ocSenkronizeEt();
      }
    }

    // İşlem bitince kursörü tekrar arama alanına al ve içindeki metni seç
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        stockListController.aramaFocusNode.requestFocus();
        stockListController.aramaController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: stockListController.aramaController.text.length,
        );
      }
    });
  }

  Widget _statusBar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.toStringAsFixed(0);
    final height = size.height.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol Kısım: Telif ve Yazılım Bilgisi
          Flexible(
            child: Tooltip(
              message: "Yazılım Geliştirme: Köksal Bebe Bilgi İşlem",
              waitDuration: const Duration(milliseconds: 500),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      "Marmara HGS 2026. ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.copyright_outlined,
                    color: Colors.grey,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Sağ Kısım: Ekran Boyutu ve Aktif Veritabanı Bağlantısı (Yana Yana)
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Ekran Boyutu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Ekran: ${width}x$height",
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "|",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                  const SizedBox(width: 8),

                  // 2. Aktif Veritabanı Bağlantısı
                  Tooltip(
                    message:
                        "Yerel DB: ${DbHelper.dbPath}\nResim: ${DbHelper.resimAnaYolu}\nOpencart: ${settingsController.c['oc_host']?.text} / ${settingsController.c['oc_db']?.text}",
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storage_rounded,
                          size: 12,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Bağlantı: ${DbHelper.dbPath.split('\\').last}",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 YENİDEN TASARLANAN VE KUR SERVİSİNE BAĞLANAN METOT
  Future<void> _guncelKurlariCek() async {
    try {
      bool basarili = await _kurService.kurlariGuncelle();

      if (basarili) {
          settingsController.c['kur_dolar']?.text = _kurService.usd
              .toStringAsFixed(4);
          settingsController.c['kur_euro']?.text = _kurService.eur
              .toStringAsFixed(4);
          settingsController.c['parite_euro_dolar']?.text = _kurService
              .eurUsdParitesi
              .toStringAsFixed(4);
          settingsController.c['parite_dolar_euro']?.text = _kurService
              .usdEurParitesi
              .toStringAsFixed(4);

        stockFormController.fiyatHesapla();
        UiUtils.showMessage(
          "Kurlar güncellendi: USD: ${_kurService.usd.toStringAsFixed(2)} - EUR: ${_kurService.eur.toStringAsFixed(2)}",
        );
      } else {
        UiUtils.showMessage(
          "Kur çekme hatası: Döviz sağlayıcı sunucusuna erişilemedi.",
          hata: true,
        );
      }
    } catch (e) {
      UiUtils.showMessage("Bağlantı hatası: $e", hata: true);
    }
  }

  Widget _ayarlarSekmesi() {
    return AyarlarTabWidget(
      buildInput: (label, key, width, {bool isPassword = false}) {
        return _input(
          label,
          key,
          width,
          isPassword: isPassword,
          externalController: settingsController.c[key],
        );
      },
      onSave: settingsController.sabitAyarlariYaz,
    );
  }

  Widget _stokBilgisiSekmesi() {
    return Obx(() {
      if (stockFormController.seciliStok.value == null &&
          !stockListController.formAcikMi.value) {
        return _buildBosDurumMesaji();
      }

      return StokDetayFormWidget(
        stokKodFocusNode: stockFormController.stokKodFocusNode,
        tabDovizFiyatlar: KurFiyatAlaniWidget(
          buildInput: _input,
          fiyatlariDovizeCevir: () =>
              stockFormController.fiyatlariDovizeCevir(),
          sabitfiyatlariDovizeCevir: () =>
              stockFormController.sabitfiyatlariDovizeCevir(),
        ),
        openCartPreview: Obx(
          () => OpenCartPreviewWidget(
            isOcConnected: openCartController.isOcConnected.value,
            ocProductId: openCartController.ocProductId.value,
            onSenkronizeEt: _ocSenkronizeEt,
            ocData: openCartController.ocData.isNotEmpty
                ? openCartController.ocData
                : null,
            autoSync: openCartController.autoSync.value,
            onAutoSyncChanged: (val) {
              openCartController.autoSync.value = val ?? false;
            },
            onDurumGuncelle: _ocDurumGuncelle,
            onUrunuTamamenSil: _ocUrunuTamamenSil,
            onStateUpdate: () {},
          ),
        ),
        buildInput:
            (
              label,
              key,
              width, {
              bool buyukHarf = false,
              FocusNode? focusNode,
              Color? themeColor,
            }) {
              return _input(
                label,
                key,
                width,
                buyukHarf: buyukHarf,
                focusNode: focusNode,
                themeColor: themeColor,
              );
            },
      );
    });
  }

  Future<void> _whatsappIlePaylas(String resimYolu) async {
    String stokAdi = stockFormController.c['stok_adi']?.text ?? "Ürün";
    String mesaj = "*$stokAdi*\n\n";

    if (_seciliTl.value) {
      mesaj += "💰 Fiyat: ${stockFormController.c['satis']?.text ?? '0'} TL\n";
    }
    if (_seciliEuro.value) {
      mesaj +=
          "💶 Euro: ${stockFormController.c['euro_satis']?.text ?? '0'} €\n";
    }
    if (_seciliDolar.value) {
      mesaj +=
          "💵 Dolar: ${stockFormController.c['dolar_satis']?.text ?? '0'} \$\n";
    }

    try {
      if (resimYolu.isNotEmpty && File(resimYolu).existsSync()) {
        await Share.shareXFiles([XFile(resimYolu)], text: mesaj);
      } else {
        await Share.share(mesaj);
      }
    } catch (e) {
      print("WhatsApp Paylaşım Hatası: $e");
    }
  }

  Widget _input(
    String label,
    String key,
    double width, {
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    bool buyukHarf = false,
    bool isPassword = false,
    FocusNode? focusNode,
    TextEditingController? externalController,
    Color? themeColor,
  }) {
    return CustomInputWidget(
      label: label,
      inputKey: key,
      width: width,
      onChanged: onChanged,
      readOnly: readOnly,
      buyukHarf: buyukHarf,
      isPassword: isPassword,
      focusNode: focusNode,
      externalController: externalController,
      themeColor: themeColor,
      fiyatHesapla: _fiyatHesapla,
      dovizGirislefiyatHesapla: _dovizGirislefiyatHesapla,
      stokKaydet: _stokKaydet,
    );
  }

  void _ocBaglantisiniYonet() async {
    if (openCartController.isOcConnected.value) {
      await openCartController.disconnect();
    } else {
      openCartController.connect(stockFormController.c["stok_kod"]?.text ?? "");
    }
  }

  Future<void> _ocSenkronizeEt() async {
    await openCartController.senkronizeEt();
  }

  Future<void> _ocUrunuTamamenSil() async {
    await openCartController.urunSil();
  }

  Future<void> _ocDurumGuncelle(String yeniDurum) async {
    await openCartController.durumDegistir();
  }
}
