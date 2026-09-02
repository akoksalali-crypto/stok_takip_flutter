import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/stok_model.dart';
import '../../utils/app_theme.dart';
import '../../services/db_helper.dart';

class SolUrunListesiWidget extends StatelessWidget {
  final TextEditingController aramaController;
  final FocusNode aramaFocusNode;
  final Function(String) onAramaChanged;
  final VoidCallback onAramaClear;
  final String seciliSiralama;
  final Function(String) onSiralamaDegistir;
  final List<Stok> filtreliListe;
  final Stok? seciliStok;
  final ScrollController listScrollController;
  final Function(Stok) onUrunTap;

  const SolUrunListesiWidget({
    super.key,
    required this.aramaController,
    required this.aramaFocusNode,
    required this.onAramaChanged,
    required this.onAramaClear,
    required this.seciliSiralama,
    required this.onSiralamaDegistir,
    required this.filtreliListe,
    required this.seciliStok,
    required this.listScrollController,
    required this.onUrunTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // --- 1. ARAMA ÇUBUĞU ---
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: TextField(
              controller: aramaController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(text: newValue.text.toUpperCase());
                }),
              ],
              focusNode: aramaFocusNode,
              onChanged: onAramaChanged,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Ürün Adı, Kod veya Barkod ile Ara...",
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                suffixIcon: aramaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel, size: 18, color: AppColors.textMuted),
                        onPressed: onAramaClear,
                        tooltip: "Aramayı Temizle",
                      )
                    : null,
              ),
            ),
          ),

          // --- 2. SIRALAMA SEÇENEKLERİ & BİLGİ ROZETİ ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              border: Border(
                top: BorderSide(color: AppColors.borderLight, width: 0.8),
                bottom: BorderSide(color: AppColors.borderLight, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Toplam Ürün Sayacı Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${filtreliListe.length} Ürün",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sıralama Butonları (Segmented Chips)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _sortChip("STOK_ADI", "Ad"),
                        const SizedBox(width: 4),
                        _sortChip("LDATE", "Son Giriş"),
                        const SizedBox(width: 4),
                        _sortChip("FDATE", "İlk Giriş"),
                        const SizedBox(width: 4),
                        _sortChip("KIMLIK", "Kayıt No"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. ÜRÜN LİSTESİ ---
          Expanded(
            child: filtreliListe.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Eşleşen ürün bulunamadı",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: listScrollController,
                    itemCount: filtreliListe.length,
                    itemBuilder: (context, index) {
                      final stok = filtreliListe[index];
                      final bool isSelected = seciliStok?.id == stok.id;

                      return _buildUrunKarti(context, stok, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sortChip(String key, String label) {
    final bool isSelected = seciliSiralama == key;

    return InkWell(
      onTap: () => onSiralamaDegistir(key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildUrunKarti(BuildContext context, Stok stok, bool isSelected) {
    final double miktarDeger = double.tryParse(stok.miktar ?? '0') ?? 0;

    Color miktarBgColor;
    Color miktarTextColor;
    String miktarMetni;

    if (miktarDeger <= 0) {
      miktarBgColor = AppColors.danger.withValues(alpha: 0.12);
      miktarTextColor = AppColors.danger;
      miktarMetni = "Tükendi";
    } else if (miktarDeger <= 5) {
      miktarBgColor = AppColors.warning.withValues(alpha: 0.15);
      miktarTextColor = const Color(0xFFB45309);
      miktarMetni = "${miktarDeger.toInt()} Ad (Kritik)";
    } else {
      miktarBgColor = AppColors.success.withValues(alpha: 0.12);
      miktarTextColor = const Color(0xFF047857);
      miktarMetni = "${miktarDeger.toInt()} Adet";
    }

    return InkWell(
      onTap: () => onUrunTap(stok),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3.5,
            ),
            bottom: const BorderSide(
              color: AppColors.borderLight,
              width: 0.7,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mini Ürün Görseli (Thumbnail)
            _ProductThumbnail(
              stok: stok,
              resimAnaYolu: DbHelper.resimAnaYolu,
            ),
            const SizedBox(width: 10),

            // Ürün Bilgi Alanı
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Satır: Ürün Adı
                  Text(
                    stok.stokAdi,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // 2. Satır: Kod / Barkod & Stok Rozeti
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${stok.stokKod ?? ''} ${stok.barkod.isNotEmpty ? '• ${stok.barkod}' : ''}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: miktarBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          miktarMetni,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: miktarTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 3. Satır: Fiyat Rozetleri (TL, USD, EUR)
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      // TL Fiyatı
                      _fiyatEtiketi(
                        "${stok.satisFiyati ?? '0.00'} ₺",
                        AppColors.tlColor,
                        isPrimary: true,
                      ),

                      // Dolar Fiyatı
                      if ((stok.dolarSatis ?? '').isNotEmpty && (stok.dolarSatis != '0'))
                        _fiyatEtiketi(
                          "${stok.dolarSatis} \$",
                          AppColors.usdColor,
                        ),

                      // Euro Fiyatı
                      if ((stok.euroSatis ?? '').isNotEmpty && (stok.euroSatis != '0'))
                        _fiyatEtiketi(
                          "${stok.euroSatis} €",
                          AppColors.eurColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fiyatEtiketi(String metin, Color renk, {bool isPrimary = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPrimary ? 6 : 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        metin,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
          color: renk,
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatefulWidget {
  final Stok stok;
  final String resimAnaYolu;

  const _ProductThumbnail({required this.stok, required this.resimAnaYolu});

  @override
  State<_ProductThumbnail> createState() => _ProductThumbnailState();
}

class _ProductThumbnailState extends State<_ProductThumbnail> {
  String? _resimYolu;
  static final Map<String, String> _pathCache = {};
  static const List<String> _uzantilar = ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG'];

  @override
  void initState() {
    super.initState();
    _bulAsync();
  }

  @override
  void didUpdateWidget(covariant _ProductThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stok.id != widget.stok.id ||
        oldWidget.stok.stokKod != widget.stok.stokKod ||
        oldWidget.stok.image != widget.stok.image ||
        oldWidget.resimAnaYolu != widget.resimAnaYolu) {
      _bulAsync();
    }
  }

  Future<void> _bulAsync() async {
    final stokKod = widget.stok.stokKod?.trim() ?? '';
    final stokAdi = widget.stok.stokAdi.trim();
    final resimAnaYolu = widget.resimAnaYolu.trim();

    if (resimAnaYolu.isEmpty || (stokKod.isEmpty && (widget.stok.image ?? '').isEmpty)) {
      if (mounted) setState(() => _resimYolu = null);
      return;
    }

    final cacheKey = '$resimAnaYolu|$stokKod|${widget.stok.image}';
    if (_pathCache.containsKey(cacheKey)) {
      final cached = _pathCache[cacheKey]!;
      if (mounted) setState(() => _resimYolu = cached.isEmpty ? null : cached);
      return;
    }

    String anaDizin = resimAnaYolu;
    if (!anaDizin.endsWith('\\') && !anaDizin.endsWith('/')) {
      anaDizin += '\\';
    }

    String? bulunan;

    // 1. stok.image alanı tanımlıysa önce onu kontrol et
    if (widget.stok.image != null && widget.stok.image!.isNotEmpty) {
      String test1 = '$anaDizin${widget.stok.image}';
      try {
        if (await File(test1).exists()) {
          bulunan = test1;
        }
      } catch (_) {}
    }

    // 2. Marka klasörünü kontrol et
    if (bulunan == null && stokKod.isNotEmpty) {
      String marka = "Genel";
      if (stokAdi.isNotEmpty) {
        marka = stokAdi.split(' ')[0].toUpperCase();
      }

      for (String uzanti in _uzantilar) {
        String testYolu = '$anaDizin$marka\\$stokKod$uzanti';
        try {
          if (await File(testYolu).exists()) {
            bulunan = testYolu;
            break;
          }
        } catch (_) {}
      }
    }

    // 3. Doğrudan ana dizindeki stok kodunu kontrol et
    if (bulunan == null && stokKod.isNotEmpty) {
      for (String uzanti in _uzantilar) {
        String testYolu = '$anaDizin$stokKod$uzanti';
        try {
          if (await File(testYolu).exists()) {
            bulunan = testYolu;
            break;
          }
        } catch (_) {}
      }
    }

    _pathCache[cacheKey] = bulunan ?? '';
    if (mounted && widget.stok.stokKod == stokKod) {
      setState(() => _resimYolu = bulunan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: _resimYolu != null && _resimYolu!.isNotEmpty
          ? Image.file(
              File(_resimYolu!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            )
          : const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
    );
  }
}
