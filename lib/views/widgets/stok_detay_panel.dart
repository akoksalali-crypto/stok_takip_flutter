import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class StokDetayPanel extends StatefulWidget {
  const StokDetayPanel({super.key});

  @override
  State<StokDetayPanel> createState() => _StokDetayPanelState();
}

class _StokDetayPanelState extends State<StokDetayPanel> {
  // Lazarus'taki Barkod, Barkod2...Barkod7 kontrolcüleri
  final List<TextEditingController> _barkodControllers = List.generate(
    7,
    (_) => TextEditingController(),
  );
  final _stokAdiController = TextEditingController();
  final _alisFiyatController = TextEditingController();
  final _satisFiyatController = TextEditingController();
  final _marjController = TextEditingController();
  final _kdvController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOL TARAF: Temel Bilgiler ve Çoklu Barkodlar
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _inputGrup("Ürün Kimliği", [
                      _ozelTextField(
                        _stokAdiController,
                        "Stok Adı",
                        3,
                        flex: 3,
                      ),
                      _ozelTextField(TextEditingController(), "Stok Kodu", 1),
                    ]),
                    SizedBox(height: 10),
                    // Lazarus'taki Barkod1'den Barkod7'ye kadar olan yapı
                    _barkodGirisAlani(),
                  ],
                ),
              ),
              SizedBox(width: 20),
              // SAĞ TARAF: Fiyatlandırma ve Resim (Lazarus'taki ResimBox ve KurPanel)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _resimOnizlemeKutusu(),
                    SizedBox(height: 15),
                    _fiyatlandirmaPaneli(),
                    SizedBox(height: 15),
                    _barkodOnizleme(), // TBarcodeQR karşılığı
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI BİLEŞENLER ---

  Widget _barkodGirisAlani() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Barkodlar (1-7)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Divider(),
          // Barkodları Lazarus'taki gibi alt alta veya yan yana dizebiliriz
          Wrap(
            spacing: 10,
            children: List.generate(
              7,
              (index) => SizedBox(
                width: 150,
                child: _ozelTextField(
                  _barkodControllers[index],
                  "Barkod ${index + 1}",
                  1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fiyatlandirmaPaneli() {
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "Fiyatlandırma",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _ozelTextField(_alisFiyatController, "Alış Fiyatı", 1),
            _ozelTextField(_marjController, "Kâr Marjı (%)", 1),
            _ozelTextField(_satisFiyatController, "Satış Fiyatı", 1),
            _ozelTextField(_kdvController, "KDV (%)", 1),
          ],
        ),
      ),
    );
  }

  Widget _resimOnizlemeKutusu() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.white,
      ),
      child: Icon(
        Icons.image,
        size: 50,
        color: Colors.grey,
      ), // Lazarus'taki TImage
    );
  }

  Widget _barkodOnizleme() {
    return BarcodeWidget(
      barcode: Barcode.code128(),
      data: _barkodControllers[0].text.isEmpty
          ? "000000"
          : _barkodControllers[0].text,
      width: 200,
      height: 80,
    );
  }

  // Ortak TextField Yapısı (Lazarus'taki TEdit tasarımı için)
  Widget _ozelTextField(
    TextEditingController controller,
    String label,
    int maxLines, {
    int flex = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
        ),
        onChanged: (val) =>
            setState(() {}), // Barkod/Fiyat değişimini anlık yansıtmak için
      ),
    );
  }

  Widget _inputGrup(String baslik, List<Widget> children) {
    return Row(
      children: children
          .map(
            (w) => Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: w,
              ),
            ),
          )
          .toList(),
    );
  }
}
