import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class DovizFiyatlarTabWidget extends StatelessWidget {
  final Widget Function(
    String label,
    String key,
    double width, {
    ValueChanged<String>? onChanged,
    bool readOnly,
    bool buyukHarf,
    bool isPassword,
    FocusNode? focusNode,
    TextEditingController? externalController,
    Color? themeColor,
  }) buildInput;
  final VoidCallback fiyatlariDovizeCevir;
  final VoidCallback sabitfiyatlariDovizeCevir;
  final VoidCallback guncelKurlariCek;
  final VoidCallback sabitAyarlariYaz;
  final bool isStokSelected;
  final String stokAdi;
  final String satisFiyati;
  final String dolarSatis;
  final String euroSatis;

  const DovizFiyatlarTabWidget({
    super.key,
    required this.buildInput,
    required this.fiyatlariDovizeCevir,
    required this.sabitfiyatlariDovizeCevir,
    required this.guncelKurlariCek,
    required this.sabitAyarlariYaz,
    this.isStokSelected = false,
    this.stokAdi = '',
    this.satisFiyati = '0',
    this.dolarSatis = '0',
    this.euroSatis = '0',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- KART 1: CANLI DÖVİZ KURLARI & PARİTE ---
          _buildSectionCard(
            title: "Canlı Piyasa Döviz Kurları & Parite",
            icon: Icons.currency_exchange_rounded,
            trailing: ElevatedButton.icon(
              onPressed: guncelKurlariCek,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text("Kurları İnternetten Çek"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildInput(
                    "Dolar Alış (₺)",
                    'kur_dolar',
                    150,
                    themeColor: AppColors.usdColor,
                  ),
                  buildInput(
                    "Euro Alış (₺)",
                    'kur_euro',
                    150,
                    themeColor: AppColors.eurColor,
                  ),
                  buildInput(
                    "EUR / USD Parite",
                    'parite_euro_dolar',
                    150,
                    readOnly: true,
                  ),
                  buildInput(
                    "USD / EUR Parite",
                    'parite_dolar_euro',
                    150,
                    readOnly: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Canlı Kur Eylem Butonu
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: isStokSelected ? fiyatlariDovizeCevir : null,
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: Text(
                    isStokSelected
                        ? "Seçili Ürünü Reel Canlı Kurla Çevir & Güncelle"
                        : "Reel Kurla Çevirmek İçin Ürün Seçin",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- KART 2: VERİTABANI SABİT KURLARI ---
          _buildSectionCard(
            title: "Veritabanı Sabit Kurları (Offline / Sabit Fiyatlama)",
            icon: Icons.lock_clock_rounded,
            trailing: ElevatedButton.icon(
              onPressed: sabitAyarlariYaz,
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text("Sabit Kurları Kaydet"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            children: [
              const Text(
                "İnternet bağlantısından bağımsız olarak satış fiyatlarını sabit bir kur çarpanıyla hesaplamak için kullanılır.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  buildInput("Sabit Dolar (₺)", 'sabit_dolar', 150),
                  buildInput("Sabit Euro (₺)", 'sabit_euro', 150),
                ],
              ),
              const SizedBox(height: 14),

              // Sabit Kur Eylem Butonu
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: isStokSelected ? sabitfiyatlariDovizeCevir : null,
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    isStokSelected
                        ? "Seçili Ürünü Sabit Kurla Çevir & Güncelle"
                        : "Sabit Kurla Çevirmek İçin Ürün Seçin",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- KART 3: SEÇİLİ ÜRÜN DÖVİZ SATIŞ FİYATLARI ÖZETİ ---
          _buildSectionCard(
            title: "Seçili Ürün Döviz Satış Fiyatları",
            icon: Icons.price_check_rounded,
            children: [
              if (!isStokSelected)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: Text(
                    "Ürüne ait döviz satış fiyatlarını görmek için soldaki listeden bir ürün seçin.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                )
              else ...[
                Text(
                  stokAdi,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _fiyatKutusu("TL Satış Fiyatı", "$satisFiyati ₺", AppColors.tlColor),
                      _fiyatKutusu("Dolar Satış Fiyatı", "$dolarSatis \$", AppColors.usdColor),
                      _fiyatKutusu("Euro Satış Fiyatı", "$euroSatis €", AppColors.eurColor),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _fiyatKutusu(String baslik, String deger, Color renk) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          deger,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: renk,
          ),
        ),
      ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
