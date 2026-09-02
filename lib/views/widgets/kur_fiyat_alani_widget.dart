import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class KurFiyatAlaniWidget extends StatelessWidget {
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

  const KurFiyatAlaniWidget({
    super.key,
    required this.buildInput,
    required this.fiyatlariDovizeCevir,
    required this.sabitfiyatlariDovizeCevir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Canlı / Reel Kur Grubu
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Canlı Döviz Kurları İle Hesaplama",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildInput("Dolar Kuru (₺)", 'kur_dolar', 130),
                  buildInput("Euro Kuru (₺)", 'kur_euro', 130),
                  ElevatedButton.icon(
                    onPressed: fiyatlariDovizeCevir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.calculate_rounded, size: 16),
                    label: const Text("Reel Kurla Çevir"),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Sabit Kur Grubu
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sabit Döviz Kurları İle Hesaplama",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  buildInput("Sabit Dolar (₺)", 'sabit_dolar', 130),
                  buildInput("Sabit Euro (₺)", 'sabit_euro', 130),
                  ElevatedButton.icon(
                    onPressed: sabitfiyatlariDovizeCevir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.calculate_rounded, size: 16),
                    label: const Text("Sabit Kurla Çevir"),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. Hesaplanan Döviz Satış & Parite Alanları
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            buildInput("Dolar Satış (\$)", 'dolar_satis', 130, readOnly: true),
            buildInput("Euro Satış (€)", 'euro_satis', 130, readOnly: true),
            buildInput("EUR/USD Parite", 'parite_euro_dolar', 150, readOnly: true),
            buildInput("USD/EUR Parite", 'parite_dolar_euro', 150, readOnly: true),
          ],
        ),
      ],
    );
  }
}
