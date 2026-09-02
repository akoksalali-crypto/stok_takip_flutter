import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stok_model.dart';
import '../services/db_helper.dart';

class StockListController extends GetxController {
  final DbHelper dbHelper = DbHelper();

  RxList<Stok> stokListesi = <Stok>[].obs;
  RxList<Stok> filtreliListe = <Stok>[].obs;
  RxList<Map<String, dynamic>> filtreliSonuclar = <Map<String, dynamic>>[].obs;
  RxString seciliSiralama = "LDATE".obs;
  RxBool isDbInitialized = false.obs;
  RxBool formAcikMi = false.obs;

  final FocusNode aramaFocusNode = FocusNode();
  final TextEditingController aramaController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  Timer? _scrollSelectionTimer;

  @override
  void onInit() {
    super.onInit();
    verileriGetir();
  }

  @override
  void onClose() {
    aramaFocusNode.dispose();
    aramaController.dispose();
    listScrollController.dispose();
    _scrollSelectionTimer?.cancel();
    super.onClose();
  }

  Future<void> verileriGetir() async {
    try {
      final list = await dbHelper.getStokListesi();
      stokListesi.value = list;
      aramaYap(aramaController.text);
    } catch (e) {
      debugPrint("Liste çekilemedi: $e");
    } finally {
      isDbInitialized.value = true;
    }
  }

  Future<int> topluIsimGuncelleVeYenile(String eskiKelime, String yeniKelime) async {
    final etkilenenSatir = await dbHelper.topluIsimGuncelle(
      eskiKelime,
      yeniKelime,
    );
    filtreliSonuclar.clear();
    await verileriGetir();
    return etkilenenSatir;
  }

  void aramaYap(String kelime, {Function(Stok)? onTekSonuc}) {
    List<Stok> geciciListe;

    if (kelime.isEmpty) {
      geciciListe = List<Stok>.from(stokListesi);
    } else {
      final aranan = kelime.toLowerCase().trim();
      geciciListe = stokListesi.where((stok) {
        final urunAdi = stok.stokAdi.toLowerCase();
        final stokKod = (stok.stokKod ?? "").toLowerCase();

        final b1 = stok.barkod.toLowerCase();
        final b2 = (stok.barkod2 ?? "").toLowerCase();
        final b3 = (stok.barkod3 ?? "").toLowerCase();
        final b4 = (stok.barkod4 ?? "").toLowerCase();
        final b5 = (stok.barkod5 ?? "").toLowerCase();
        final b6 = (stok.barkod6 ?? "").toLowerCase();
        final b7 = (stok.barkod7 ?? "").toLowerCase();

        return urunAdi.contains(aranan) ||
            stokKod.contains(aranan) ||
            b1 == aranan ||
            b2 == aranan ||
            b3 == aranan ||
            b4 == aranan ||
            b5 == aranan ||
            b6 == aranan ||
            b7 == aranan;
      }).toList();
    }

    geciciListe.sort((a, b) {
      switch (seciliSiralama.value) {
        case "LDATE":
          return (b.Ldate ?? "").compareTo(a.Ldate ?? "");
        case "FDATE":
          return (a.Fdate ?? "").compareTo(b.Fdate ?? "");
        case "KIMLIK":
          return (a.id ?? 0).compareTo(b.id ?? 0);
        case "STOK_ADI":
        default:
          return a.stokAdi.compareTo(b.stokAdi);
      }
    });

    filtreliListe.assignAll(geciciListe);

    if (filtreliListe.length == 1 && onTekSonuc != null) {
      final aranan = kelime.toLowerCase().trim();
      if (aranan.isNotEmpty) {
        final stok = filtreliListe.first;
        final b1 = stok.barkod.toLowerCase().trim();
        final b2 = (stok.barkod2 ?? "").toLowerCase().trim();
        final b3 = (stok.barkod3 ?? "").toLowerCase().trim();
        final b4 = (stok.barkod4 ?? "").toLowerCase().trim();
        final b5 = (stok.barkod5 ?? "").toLowerCase().trim();
        final b6 = (stok.barkod6 ?? "").toLowerCase().trim();
        final b7 = (stok.barkod7 ?? "").toLowerCase().trim();

        if (b1 == aranan ||
            b2 == aranan ||
            b3 == aranan ||
            b4 == aranan ||
            b5 == aranan ||
            b6 == aranan ||
            b7 == aranan) {
          onTekSonuc(stok);
        }
      }
    }
  }

  void urunSec(Stok stok, Function(Stok) formuDoldur, Function(String) connectOpenCart) {
    formuDoldur(stok);
    formAcikMi.value = true;
    // Otomatik bağlantı isteği üzerine kaldırıldı
  }

  void siralamaDegistir(String yeniSiralama) {
    seciliSiralama.value = yeniSiralama;
    aramaYap(aramaController.text);
  }

  void secimiScrollIleDegistir(int yeniIndex, Function(Stok) onStokSecildi) {
    if (yeniIndex < 0 || yeniIndex >= filtreliListe.length) return;

    final stok = filtreliListe[yeniIndex];
    onStokSecildi(stok);

    double hedefScroll = yeniIndex * 54.0 - 150.0;
    if (listScrollController.hasClients) {
      listScrollController.jumpTo(
        hedefScroll.clamp(0.0, listScrollController.position.maxScrollExtent),
      );
    }

    _scrollSelectionTimer?.cancel();
    _scrollSelectionTimer = Timer(const Duration(milliseconds: 200), () async {
      // Any debounced tasks like oc sync can go here if needed.
    });
  }
}
