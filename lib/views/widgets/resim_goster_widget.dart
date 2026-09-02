import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/ui_utils.dart';

class ResimGosterWidget extends StatefulWidget {
  final String stokAdi;
  final String stokKod;
  final String resimAnaYolu;
  final ValueChanged<String> onWhatsappIlePaylas;
  final bool seciliTl;
  final bool seciliEuro;
  final bool seciliDolar;
  final ValueChanged<bool> onSeciliTlChanged;
  final ValueChanged<bool> onSeciliEuroChanged;
  final ValueChanged<bool> onSeciliDolarChanged;
  final bool isOcConnected;
  final VoidCallback onOcBaglantisiniYonet;
  final VoidCallback onStokKaydet;
  final VoidCallback onStokSilOnayli;
  final VoidCallback onStokDataUrunKopyala;
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
  final TextEditingController webLinkController;
  final ValueChanged<String> onLinkiAc;
  final String fiyatTl;
  final String fiyatEuro;
  final String fiyatDolar;

  const ResimGosterWidget({
    super.key,
    required this.stokAdi,
    required this.stokKod,
    required this.resimAnaYolu,
    required this.onWhatsappIlePaylas,
    required this.seciliTl,
    required this.seciliEuro,
    required this.seciliDolar,
    required this.onSeciliTlChanged,
    required this.onSeciliEuroChanged,
    required this.onSeciliDolarChanged,
    required this.isOcConnected,
    required this.onOcBaglantisiniYonet,
    required this.onStokKaydet,
    required this.onStokSilOnayli,
    required this.onStokDataUrunKopyala,
    required this.buildInput,
    required this.webLinkController,
    required this.onLinkiAc,
    this.fiyatTl = '0',
    this.fiyatEuro = '0',
    this.fiyatDolar = '0',
  });

  @override
  State<ResimGosterWidget> createState() => _ResimGosterWidgetState();
}

class _ResimGosterWidgetState extends State<ResimGosterWidget> {
  String _bulunanTamYol = '';
  static const List<String> _uzantilar = ['.jpg', '.jpeg', '.png', '.JPG', '.JPEG'];

  @override
  void initState() {
    super.initState();
    _resimYolunuBul();
  }

  @override
  void didUpdateWidget(covariant ResimGosterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stokKod != widget.stokKod ||
        oldWidget.stokAdi != widget.stokAdi ||
        oldWidget.resimAnaYolu != widget.resimAnaYolu) {
      _resimYolunuBul();
    }
  }

  Future<void> _resimYolunuBul() async {
    final stokKod = widget.stokKod.trim();
    final stokAdi = widget.stokAdi.trim();
    final resimAnaYolu = widget.resimAnaYolu.trim();

    if (stokKod.isEmpty || resimAnaYolu.isEmpty) {
      if (mounted) setState(() => _bulunanTamYol = '');
      return;
    }

    String marka = "Genel";
    if (stokAdi.isNotEmpty) {
      marka = stokAdi.split(' ')[0].toUpperCase();
    }

    String anaDizin = resimAnaYolu;
    if (!anaDizin.endsWith('\\') && !anaDizin.endsWith('/')) {
      anaDizin += '\\';
    }

    String sonuc = '';
    for (String uzanti in _uzantilar) {
      String testYolu = '$anaDizin$marka\\$stokKod$uzanti';
      try {
        if (await File(testYolu).exists()) {
          sonuc = testYolu;
          break;
        }
      } catch (_) {}
    }

    if (sonuc.isEmpty) {
      for (String uzanti in _uzantilar) {
        String testYolu = '$anaDizin$stokKod$uzanti';
        try {
          if (await File(testYolu).exists()) {
            sonuc = testYolu;
            break;
          }
        } catch (_) {}
      }
    }

    if (mounted && widget.stokKod.trim() == stokKod) {
      setState(() => _bulunanTamYol = sonuc);
    }
  }

  String _olusturMesajMetni() {
    String stokAdi = widget.stokAdi.isNotEmpty ? widget.stokAdi : "Ürün";
    String mesaj = "*$stokAdi*\n\n";

    if (widget.seciliTl) {
      mesaj += "💰 Fiyat: ${widget.fiyatTl.isNotEmpty ? widget.fiyatTl : '0'} TL\n";
    }
    if (widget.seciliEuro) {
      mesaj += "💶 Euro: ${widget.fiyatEuro.isNotEmpty ? widget.fiyatEuro : '0'} €\n";
    }
    if (widget.seciliDolar) {
      mesaj += "💵 Dolar: ${widget.fiyatDolar.isNotEmpty ? widget.fiyatDolar : '0'} \$\n";
    }
    return mesaj;
  }

  void _resmiBuyut(BuildContext context) {
    if (_bulunanTamYol.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.stokAdi,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Image.file(
                        File(_bulunanTamYol),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bulunanTamYol,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _klasordeGoster() async {
    if (_bulunanTamYol.isEmpty) return;
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,', _bulunanTamYol]);
      } else {
        final dir = File(_bulunanTamYol).parent.path;
        await launchUrl(Uri.parse('file://$dir'));
      }
    } catch (e) {
      UiUtils.showMessage("Klasör açılamadı: $e", hata: true);
    }
  }

  Future<void> _beklenenKlasoruAc() async {
    final resimAnaYolu = widget.resimAnaYolu.trim();
    if (resimAnaYolu.isEmpty) {
      UiUtils.showMessage("Ana resim klasörü yolu ayarlanmamış!", hata: true);
      return;
    }

    String marka = "Genel";
    if (widget.stokAdi.isNotEmpty) {
      marka = widget.stokAdi.split(' ')[0].toUpperCase();
    }

    String anaDizin = resimAnaYolu;
    if (!anaDizin.endsWith('\\') && !anaDizin.endsWith('/')) {
      anaDizin += '\\';
    }

    String hedefKlasor = '$anaDizin$marka';
    try {
      final dir = Directory(hedefKlasor);
      if (!await dir.exists()) {
        hedefKlasor = anaDizin;
      }

      if (Platform.isWindows) {
        await Process.run('explorer.exe', [hedefKlasor]);
      } else {
        await launchUrl(Uri.parse('file://$hedefKlasor'));
      }
    } catch (e) {
      UiUtils.showMessage("Klasör açılamadı: $e", hata: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    String marka = "Genel";
    if (widget.stokAdi.isNotEmpty) {
      marka = widget.stokAdi.split(' ')[0].toUpperCase();
    }

    final hasImage = _bulunanTamYol.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // --- 1. GÖRSEL KARTI & EYLEMLERİ ---
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasImage
                  ? GestureDetector(
                      onTap: () => _resmiBuyut(context),
                      child: Image.file(
                        File(_bulunanTamYol),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _resimYokWidget(marka, widget.stokKod),
                      ),
                    )
                  : _resimYokWidget(marka, widget.stokKod),

              // Görsel Sağ Üst Hızlı Eylemler (Zoom & Klasör)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasImage) ...[
                      _imageActionButton(
                        icon: Icons.zoom_in_rounded,
                        tooltip: "Büyük Görseli İncele",
                        onPressed: () => _resmiBuyut(context),
                      ),
                      const SizedBox(width: 6),
                      _imageActionButton(
                        icon: Icons.folder_open_rounded,
                        tooltip: "Görseli Klasörde Seç",
                        onPressed: _klasordeGoster,
                      ),
                    ] else
                      _imageActionButton(
                        icon: Icons.folder_open_rounded,
                        tooltip: "Ürünün Bulunması Gereken Klasörü Aç",
                        onPressed: _beklenenKlasoruAc,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // --- 2. WHATSAPP & PAYLAŞIM KARTI ---
        _buildSectionCard(
          title: "WhatsApp & Paylaşım",
          icon: Icons.share_rounded,
          children: [
            // Para Birimi Seçicileri
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  _fiyatChip("₺ TL", widget.seciliTl, widget.onSeciliTlChanged, AppColors.tlColor),
                  _fiyatChip("€ EUR", widget.seciliEuro, widget.onSeciliEuroChanged, AppColors.eurColor),
                  _fiyatChip("\$ USD", widget.seciliDolar, widget.onSeciliDolarChanged, AppColors.usdColor),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Canlı Mesaj Önizleme Alanı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                _olusturMesajMetni().trim(),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Paylaş & Panoya Kopyala Butonları
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onWhatsappIlePaylas(_bulunanTamYol),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text("WhatsApp ile Paylaş"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.whatsappGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _olusturMesajMetni()));
                      UiUtils.showMessage("Mesaj panoya kopyalandı!");
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text("Kopyala"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // --- 3. GÖRSEL YOLU & WEB BAĞLANTISI KARTI ---
        _buildSectionCard(
          title: "Görsel Yolu & Web Linki",
          icon: Icons.link_rounded,
          children: [
            widget.buildInput("Resim Dosya Adı / Yolu", 'image', double.infinity),
            const SizedBox(height: 10),
            TextField(
              controller: widget.webLinkController,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: "Web Ürün Linki",
                labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                  tooltip: "Tarayıcıda Aç",
                  onPressed: () => widget.onLinkiAc(widget.webLinkController.text),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _imageActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(6),
        onPressed: onPressed,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resimYokWidget(String marka, String stokKod) {
    return InkWell(
      onDoubleTap: _beklenenKlasoruAc,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              "Görsel Bulunamadı",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$marka / $stokKod",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_rounded, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    "Klasörü açmak için çift tıklayın",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fiyatChip(
    String label,
    bool isSelected,
    Function(bool) onSelected,
    Color activeColor,
  ) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? activeColor : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: activeColor.withValues(alpha: 0.12),
      checkmarkColor: activeColor,
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.borderLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
