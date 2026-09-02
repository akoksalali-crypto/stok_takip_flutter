import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AyarlarTabWidget extends StatelessWidget {
  final Widget Function(String label, String key, double width, {bool isPassword}) buildInput;
  final VoidCallback onSave;

  const AyarlarTabWidget({
    super.key,
    required this.buildInput,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- KART 1: YEREL / AĞ DEPOLAMA VE VERİTABANI YOLLARI ---
          _buildSectionCard(
            title: "Veritabanı & Dosya Yolları",
            icon: Icons.folder_open_rounded,
            children: [
              buildInput("Yerel / Ağ Veritabanı Dosya Yolu (.s3db / .db)", 'db_path', double.infinity),
              const SizedBox(height: 12),
              buildInput("Ana Ürün Resim Klasörü Yolu", 'resimAnaYolu', double.infinity),
            ],
          ),
          const SizedBox(height: 16),

          // --- KART 2: OPENCART 3 UZAK SUNUCU VERİTABANI BAĞLANTISI ---
          _buildSectionCard(
            title: "Uzak Sunucu (OpenCart 3) MySQL Bağlantı Ayarları",
            icon: Icons.cloud_sync_rounded,
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: buildInput("Sunucu IP / Host Adresi", 'oc_host', double.infinity)),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: buildInput("Port", 'oc_port', double.infinity)),
                ],
              ),
              const SizedBox(height: 12),
              buildInput("MySQL Veritabanı Adı", 'oc_db', double.infinity),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: buildInput("Kullanıcı Adı", 'oc_user', double.infinity)),
                  const SizedBox(width: 12),
                  Expanded(child: buildInput("Kullanıcı Şifresi", 'oc_pass', double.infinity, isPassword: true)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- KAYDET BUTONU ---
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: const Text(
                "AYARLARI KAYDET",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
