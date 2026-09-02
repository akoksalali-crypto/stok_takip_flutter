import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class BarkodlarTabWidget extends StatelessWidget {
  final bool isStokSelected;
  final String stokAdi;
  final String satisFiyati;
  final String basilacakBarkodDegeri;
  final String basilacakBarkodKey;
  final ValueChanged<String>? onBasilacakBarkodKeyChanged;
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
  })
  buildInput;
  final List<String> yaziciListesi;
  final String? seciliYazici;
  final ValueChanged<String?> onYaziciChanged;
  final TextEditingController adetController;
  final void Function(BuildContext context, {String? tiklananBarkodKey})
  barkodBasimiBaslat;

  const BarkodlarTabWidget({
    super.key,
    required this.isStokSelected,
    this.stokAdi = '',
    this.satisFiyati = '0',
    this.basilacakBarkodDegeri = '',
    required this.basilacakBarkodKey,
    this.onBasilacakBarkodKeyChanged,
    required this.buildInput,
    required this.yaziciListesi,
    required this.seciliYazici,
    required this.onYaziciChanged,
    required this.adetController,
    required this.barkodBasimiBaslat,
  });

  @override
  Widget build(BuildContext context) {
    if (!isStokSelected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              "Barkodları ve etiket önizlemesini görmek için bir ürün seçin.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final barkodListesi = [
      {'label': 'Barkod 1 (Ana Barkod)', 'key': 'barkod'},
      {'label': 'Barkod 2', 'key': 'barkod2'},
      {'label': 'Barkod 3', 'key': 'barkod3'},
      {'label': 'Barkod 4', 'key': 'barkod4'},
      {'label': 'Barkod 5', 'key': 'barkod5'},
      {'label': 'Barkod 6', 'key': 'barkod6'},
      {'label': 'Barkod 7', 'key': 'barkod7'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SOL KOLON: EK BARKOD TANIMLARI ---
          Expanded(
            flex: 3,
            child: _buildSectionCard(
              title: "Ek Barkod Tanımları (1 - 7)",
              icon: Icons.qr_code_rounded,
              children: [
                const Text(
                  "Ürüne ait alternatif barkodları buradan tanımlayabilirsiniz. Tanımlı tüm barkodlar hızlı aramada geçerlidir.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                ...barkodListesi.map((b) {
                  final key = b['key']!;
                  final label = b['label']!;
                  final isSelectedForPrint = (basilacakBarkodKey == key);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: buildInput(
                            label,
                            key,
                            double.infinity,
                            themeColor: isSelectedForPrint
                                ? AppColors.success
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: "Etiket basımı için bu barkodu seç",
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (onBasilacakBarkodKeyChanged != null) {
                                onBasilacakBarkodKeyChanged!(key);
                              }
                            },
                            icon: Icon(
                              isSelectedForPrint
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: isSelectedForPrint
                                  ? AppColors.success
                                  : AppColors.textMuted,
                            ),
                            label: Text(
                              isSelectedForPrint ? "Basılacak" : "Seç",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelectedForPrint
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelectedForPrint
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelectedForPrint
                                  ? AppColors.success.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isSelectedForPrint
                                    ? AppColors.success
                                    : AppColors.borderLight,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // --- SAĞ KOLON: CANLI TERMAL ETİKET MOCKUP ÖNİZLEMESİ & YAZDIRMA ---
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSectionCard(
                  title: "Canlı Etiket Önizleme (50x30 mm)",
                  icon: Icons.label_rounded,
                  children: [Center(child: _buildThermalLabelMockup())],
                ),
                const SizedBox(height: 14),

                // Yazdırma Kontrol Paneli
                _buildSectionCard(
                  title: "Etiket Yazdırma Kontrolleri",
                  icon: Icons.print_rounded,
                  children: [
                    // Yazıcı Seçimi
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: (yaziciListesi.contains(seciliYazici))
                              ? seciliYazici
                              : null,
                          isExpanded: true,
                          hint: const Text(
                            "Yazıcı Seçin...",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          items: yaziciListesi.map((String p) {
                            return DropdownMenuItem<String>(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: onYaziciChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Adet Kontrolü & Yazdır Butonu
                    Row(
                      children: [
                        // Hızlı Adet Azalt / Artır
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  int current =
                                      int.tryParse(adetController.text) ?? 1;
                                  if (current > 1) {
                                    adetController.text = (current - 1)
                                        .toString();
                                  }
                                },
                              ),
                              SizedBox(
                                width: 44,
                                child: TextField(
                                  controller: adetController,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 40,
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  int current =
                                      int.tryParse(adetController.text) ?? 1;
                                  adetController.text = (current + 1)
                                      .toString();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Yazdır Butonu
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () => barkodBasimiBaslat(
                                context,
                                tiklananBarkodKey: basilacakBarkodKey,
                              ),
                              icon: const Icon(Icons.print_rounded, size: 18),
                              label: const Text("ETİKET YAZDIR"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalLabelMockup() {
    final barkodVerisi = basilacakBarkodDegeri.trim().isNotEmpty
        ? basilacakBarkodDegeri.trim()
        : "869000000001";
    final urunBaslik = stokAdi.isNotEmpty ? stokAdi : "ÜRÜN ADI";
    final fiyatMetni = satisFiyati.isNotEmpty ? satisFiyati : "0.00";

    return Container(
      width: 250,
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mağaza Adı & Ürün Başlığı
          Column(
            children: [
              const Text(
                "KÖKSAL BEBE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                urunBaslik,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),

          // Barkod Çizimi
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: SizedBox(
              height: 48,
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: barkodVerisi,
                drawText: true,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                errorBuilder: (context, error) => Center(
                  child: Text(
                    "Geçersiz Barkod: $barkodVerisi",
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ),
              ),
            ),
          ),

          // Fiyat Alanı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  "KDV DAHİL DEĞİLDİR",
                  style: TextStyle(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "$fiyatMetni ₺",
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
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
