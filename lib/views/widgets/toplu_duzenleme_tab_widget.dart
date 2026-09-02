import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class TopluDuzenlemeTabWidget extends StatelessWidget {
  final int filtreliSonuclarLength;
  final Widget solHizliAramaListesi;
  final TextEditingController findController;
  final ValueChanged<String> onHizliAra;
  final TextEditingController replaceController;
  final VoidCallback onTopluDegistir;

  const TopluDuzenlemeTabWidget({
    super.key,
    required this.filtreliSonuclarLength,
    required this.solHizliAramaListesi,
    required this.findController,
    required this.onHizliAra,
    required this.replaceController,
    required this.onTopluDegistir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SOL: GİRDİ FORMU & EYLEM KARTI ---
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionCard(
                  title: "Toplu Ürün Adı Bul & Değiştir",
                  icon: Icons.find_replace_rounded,
                  children: [
                    TextField(
                      controller: findController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: onHizliAra,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Aranan Kelime / Metin",
                        labelStyle: const TextStyle(fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: replaceController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Yeni Kelime / Değer",
                        labelStyle: const TextStyle(fontSize: 12.5),
                        prefixIcon: const Icon(Icons.edit_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bilgilendirme Kutusu
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Aranan kelimeyi yazdığınızda sağ panelde etkilenecek tüm ürünler listelenir. 'Tümünü Güncelle' butonuna bastığınızda onayınızla birlikte veritabanı toplu olarak güncellenir.",
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Güncelle Butonu
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: filtreliSonuclarLength > 0 ? onTopluDegistir : null,
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: Text(
                          filtreliSonuclarLength > 0
                              ? "TÜMÜNÜ GÜNCELLE ($filtreliSonuclarLength ÜRÜN)"
                              : "TÜMÜNÜ GÜNCELLE",
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // --- SAĞ: ETKİLENECEK ÜRÜNLER LİSTESİ ---
          Expanded(
            child: _buildSectionCard(
              title: "Etkilenecek Ürünler (${filtreliSonuclarLength > 0 ? '$filtreliSonuclarLength Kayıt' : 'Eşleşen Yok'})",
              icon: Icons.list_alt_rounded,
              trailing: filtreliSonuclarLength > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$filtreliSonuclarLength Eşleşme",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    )
                  : null,
              children: [
                if (filtreliSonuclarLength == 0)
                  Container(
                    height: 300,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Arama kutusuna en az 2 karakter yazarak ürünleri listeleyin.",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 450,
                    child: solHizliAramaListesi,
                  ),
              ],
            ),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
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
