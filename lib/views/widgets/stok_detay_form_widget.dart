import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/stock_form_controller.dart';
import '../../utils/app_theme.dart';

class StokDetayFormWidget extends StatelessWidget {
  final Widget Function(
    String label,
    String key,
    double width, {
    bool buyukHarf,
    FocusNode? focusNode,
    Color? themeColor,
  }) buildInput;
  final Widget tabDovizFiyatlar;
  final Widget openCartPreview;
  final FocusNode stokKodFocusNode;

  const StokDetayFormWidget({
    super.key,
    required this.buildInput,
    required this.tabDovizFiyatlar,
    required this.openCartPreview,
    required this.stokKodFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final stockFormController = Get.find<StockFormController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- KART 1: TEMEL ÜRÜN BİLGİLERİ ---
          _buildSectionCard(
            title: "Temel Ürün Bilgileri",
            icon: Icons.inventory_2_outlined,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildInput(
                    "Stok Kodu",
                    'stok_kod',
                    180,
                    buyukHarf: true,
                    focusNode: stokKodFocusNode,
                  ),
                  buildInput("Ana Barkod", 'barkod', 180),
                  buildInput("Barkod 2", 'barkod2', 180),
                  buildInput("Beden", 'beden', 130),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: buildInput(
                      "Stok / Ürün Adı",
                      'stok_adi',
                      double.infinity,
                      buyukHarf: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  buildInput("İlk Giriş Tarihi", 'Fdate', 180),
                  buildInput("Son Giriş Tarihi", 'Ldate', 180),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- KART 2: FİYATLANDIRMA, KÂR & STOK YÖNETİMİ ---
          _buildSectionCard(
            title: "Fiyatlandırma & Kâr Marjı",
            icon: Icons.payments_outlined,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildInput(
                    "Alış Fiyatı (₺)",
                    'alis',
                    140,
                    themeColor: AppColors.primary,
                  ),
                  buildInput("Kâr Marjı %", 'marj', 110),
                  buildInput("KDV %", 'kdv', 110),
                  buildInput(
                    "Satış Fiyatı (₺)",
                    'satis',
                    140,
                    themeColor: AppColors.tlColor,
                  ),
                  buildInput(
                    "Miktar (Stok)",
                    'miktar',
                    120,
                    themeColor: AppColors.secondary,
                  ),
                  buildInput("Dolar Alış (\$)", 'dolar_alis', 120),
                ],
              ),
              const SizedBox(height: 12),

              // Canlı Kâr & Stok Özeti Paneli
              _buildProfitSummary(stockFormController),
            ],
          ),
          const SizedBox(height: 12),

          // --- KART 3: DÖVİZ KURLARI & ÇEVİRİCİ ---
          _buildSectionCard(
            title: "Döviz Kurları & Çevirici",
            icon: Icons.currency_exchange_rounded,
            children: [
              tabDovizFiyatlar,
            ],
          ),
          const SizedBox(height: 12),

          // --- KART 4: FİZİKSEL & PAKETLEME BİLGİLERİ ---
          _buildSectionCard(
            title: "Fiziksel Özellikler & Paketleme",
            icon: Icons.straighten_rounded,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  buildInput("Lot (Paket Adedi)", 'lot', 150),
                  buildInput("Ağırlık (gr / kg)", 'weight', 150),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- KART 5: E-TİCARET & SEO BİLGİLERİ ---
          _buildSectionCard(
            title: "E-Ticaret & SEO Bilgileri",
            icon: Icons.language_rounded,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  buildInput("Meta Title", 'metaTitle', 300),
                  buildInput("SEO URL", 'seoUrl', 300),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: buildInput(
                      "Meta Anahtar Kelimeler",
                      'metaKeyword',
                      double.infinity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: buildInput(
                      "Meta Açıklama",
                      'metaDescription',
                      double.infinity,
                    ),
                  ),
                ],
              ),
              openCartPreview,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kart Başlığı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),

          // Kart İçeriği
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitSummary(StockFormController stockFormController) {
    final controllers = [
      stockFormController.c['alis'],
      stockFormController.c['satis'],
      stockFormController.c['marj'],
      stockFormController.c['miktar'],
      stockFormController.c['dolar_alis'],
      stockFormController.c['dolar_satis'],
      stockFormController.c['euro_satis'],
    ].whereType<TextEditingController>().toList();

    return AnimatedBuilder(
      animation: Listenable.merge(controllers),
      builder: (context, _) {
        final double alis = double.tryParse(
              stockFormController.c['alis']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0;
        final double satis = double.tryParse(
              stockFormController.c['satis']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0;
        final double marj = double.tryParse(
              stockFormController.c['marj']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0;
        final double miktar =
            double.tryParse(stockFormController.c['miktar']?.text ?? '0') ?? 0;
        final double dolarAlis = double.tryParse(
              stockFormController.c['dolar_alis']?.text.replaceAll(',', '.') ?? '0',
            ) ??
            0;
        final String dolarSatis =
            stockFormController.c['dolar_satis']?.text.trim() ?? '0.00';
        final String euroSatis =
            stockFormController.c['euro_satis']?.text.trim() ?? '0.00';

        final double netKar = satis - alis;
        final double toplamTutar = satis * miktar;
        final bool isDolarAlisli = dolarAlis > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDolarAlisli
                ? AppColors.usdColor.withValues(alpha: 0.04)
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDolarAlisli
                  ? AppColors.usdColor.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _summaryItem(
                    isDolarAlisli ? "Birim Alış (₺ Çevrilen)" : "Birim Alış",
                    "${alis.toStringAsFixed(2)} ₺",
                    AppColors.textSecondary,
                  ),
                  _summaryItem(
                    "Birim Satış",
                    "${satis.toStringAsFixed(2)} ₺",
                    AppColors.tlColor,
                    isBold: true,
                  ),
                  _summaryItem(
                    "Birim Kâr",
                    "${netKar >= 0 ? '+' : ''}${netKar.toStringAsFixed(2)} ₺",
                    netKar >= 0 ? AppColors.success : AppColors.danger,
                    isBold: true,
                  ),
                  _summaryItem(
                    "Kâr Oranı",
                    "%${marj.toStringAsFixed(1)}",
                    AppColors.usdColor,
                  ),
                  _summaryItem(
                    "Dolar Satış",
                    "$dolarSatis \$",
                    AppColors.usdColor,
                    isBold: true,
                  ),
                  _summaryItem(
                    "Euro Satış",
                    "$euroSatis €",
                    AppColors.eurColor,
                    isBold: true,
                  ),
                  _summaryItem(
                    "Toplam Stok Değeri",
                    "${toplamTutar.toStringAsFixed(2)} ₺",
                    AppColors.primary,
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isDolarAlisli
                        ? Icons.bolt_rounded
                        : Icons.lock_clock_rounded,
                    size: 13,
                    color: isDolarAlisli
                        ? AppColors.usdColor
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDolarAlisli
                        ? "Hesaplama Modu: Canlı Dolar Kuru (Dolar Alış: \$$dolarAlis)"
                        : "Hesaplama Modu: Sabit Döviz Kurları (TL Alış Bazlı)",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDolarAlisli
                          ? AppColors.usdColor
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
