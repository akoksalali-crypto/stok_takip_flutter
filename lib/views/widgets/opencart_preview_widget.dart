import 'package:flutter/material.dart';

class OpenCartPreviewWidget extends StatelessWidget {
  final bool isOcConnected;
  final String? ocProductId;
  final Map<String, dynamic>? ocData; // <--- Yeni eklendi
  final VoidCallback onSenkronizeEt;
  final bool autoSync;
  final ValueChanged<bool?> onAutoSyncChanged;
  final Future<void> Function(String) onDurumGuncelle;
  final VoidCallback onUrunuTamamenSil;
  final VoidCallback onStateUpdate;

  const OpenCartPreviewWidget({
    super.key,
    required this.isOcConnected,
    required this.ocProductId,
    required this.ocData, // <--- Yeni eklendi
    required this.onSenkronizeEt,
    required this.autoSync,
    required this.onAutoSyncChanged,
    required this.onDurumGuncelle,
    required this.onUrunuTamamenSil,
    required this.onStateUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOcConnected) {
      return const SizedBox.shrink();
    }

    if (ocProductId == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, color: Colors.orange.shade800),
                const SizedBox(width: 10),
                Text(
                  "Ürün Web Sitesinde Yüklü Değil",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSenkronizeEt,
                icon: const Icon(Icons.cloud_upload),
                label: const Text("OPENCART'A ŞİMDİ YÜKLE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final data = ocData;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final dynamic statusVerisi = data['status'];
    final bool isActive =
        (statusVerisi.toString() == "1" || statusVerisi == 1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.blue.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.cloud_sync : Icons.cloud_off,
                color: isActive ? Colors.blue : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "OpenCart Canlı: ${data['name'] ?? ''}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: isActive ? Colors.blue : Colors.red),
          Row(
            children: [
              Checkbox(
                value: autoSync,
                activeColor: Colors.blue,
                onChanged: onAutoSyncChanged,
              ),
              const Text(
                "Otomatik Senkronize Et",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Wrap(
            spacing: 30,
            runSpacing: 12,
            children: [
              _ocVeriSutunu(
                "MİKTAR",
                "${data['quantity'] ?? 0} Adet",
                Icons.inventory,
              ),
              _ocVeriSutunu(
                "FİYAT",
                "${double.tryParse(data['price'].toString())?.toStringAsFixed(2) ?? '0.00'} TL",
                Icons.sell,
              ),
              _ocVeriSutunu(
                "KDV",
                "${double.tryParse(data['tax_class_id'].toString())?.toStringAsFixed(2) ?? '0.00'} %",
                Icons.sell,
              ),
              _ocVeriSutunu(
                "BARKOD",
                "${data['ean'] ?? '-'}",
                Icons.qr_code,
              ),
              _ocVeriSutunu(
                "SKU",
                "${data['sku'] ?? '-'}",
                Icons.qr_code,
              ),
              _ocVeriSutunu(
                "Ürün ID",
                data['product_id']?.toString() ?? '-',
                Icons.vpn_key,
              ),
              _ocVeriSutunu(
                "BEDEN",
                "${data['description'] ?? '-'}",
                Icons.straighten,
              ),
              _ocVeriSutunu(
                "LOT",
                "${data['minimum'] ?? '-'}",
                Icons.countertops,
              ),
              _ocVeriSutunu(
                "Ağırlık",
                "${num.tryParse(data['weight'].toString()) ?? 0} gr",
                Icons.monitor_weight_outlined,
              ),
              _ocVeriSutunu(
                "Image URL",
                (data['image'] != null &&
                        data['image'].toString().isNotEmpty)
                    ? data['image'].toString()
                    : "-",
                Icons.link,
              ),
              _ocVeriSutunu(
                "Date Mod.",
                (data['date_modified'] != null &&
                        data['date_modified'].toString().isNotEmpty)
                    ? data['date_modified'].toString()
                    : "-",
                Icons.link,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isOcConnected) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSenkronizeEt,
                    icon: Icon(
                      ocProductId == null
                          ? Icons.cloud_upload
                          : Icons.sync,
                      size: 18,
                    ),
                    label: Text(
                      ocProductId == null ? "OC3 YÜKLE" : "OC3 GÜNCELLE",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String yeniDurum = isActive ? "0" : "1";
                    String islemAdi = isActive ? "KAPATMAK" : "YAYINLAMAK";

                    bool? onay = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Ürünü $islemAdi"),
                        content: Text(
                          "Bu ürünü web sitesinde $islemAdi istediğinize emin misiniz?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("VAZGEÇ"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("EVET"),
                          ),
                        ],
                      ),
                    );

                    if (onay == true) {
                      await onDurumGuncelle(yeniDurum);
                      onStateUpdate();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? const Color.fromARGB(255, 90, 144, 224)
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    isActive ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(
                    isActive ? "KAPAT" : "YAYINLA",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (ocProductId != null)
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: onUrunuTamamenSil,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text(
                      "ÜRÜNÜ SİL",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                        255,
                        228,
                        95,
                        95,
                      ),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ocVeriSutunu(String baslik, String deger, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.blueGrey),
            const SizedBox(width: 4),
            Text(
              baslik,
              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
            ),
          ],
        ),
        Text(
          deger,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
