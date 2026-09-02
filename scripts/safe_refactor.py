import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add imports
    content = content.replace("import '../services/db_helper.dart';", "import '../services/db_helper.dart';\nimport 'package:get/get.dart';\nimport '../controllers/stock_list_controller.dart';\nimport '../controllers/stock_form_controller.dart';\nimport '../controllers/opencart_controller.dart';\nimport '../controllers/settings_controller.dart';\nimport '../controllers/printer_controller.dart';")

    # 2. Inject controllers
    content = content.replace("final DbHelper dbHelper = DbHelper();", "final DbHelper dbHelper = DbHelper();\n  final SettingsController settingsController = Get.put(SettingsController());\n  final PrinterController printerController = Get.put(PrinterController());\n  final StockListController stockListController = Get.put(StockListController());\n  final StockFormController stockFormController = Get.put(StockFormController());\n  final OpenCartController openCartController = Get.put(OpenCartController());")

    # 3. Safe Replacements using word boundaries
    reps = {
        r'\b_stokListesi\b': 'stockListController.stokListesi',
        r'\b_filtreliListe\b': 'stockListController.filtreliListe',
        r'\b_seciliSiralama\b': 'stockListController.seciliSiralama.value',
        r'\b_aramaController\b': 'stockListController.aramaController',
        r'\b_aramaFocusNode\b': 'stockListController.aramaFocusNode',
        r'\b_listScrollController\b': 'stockListController.listScrollController',
        r'\b_isOcConnected\b': 'openCartController.isOcConnected.value',
        r'\b_ocProductId\b': 'openCartController.ocProductId.value',
        r'\b_seciliYazici\b': 'printerController.seciliYazici.value',
        r'\b_yaziciListesi\b': 'printerController.yaziciListesi',
        r'\b_seciliTl\b': 'settingsController.seciliTl.value',
        r'\b_seciliEuro\b': 'settingsController.seciliEuro.value',
        r'\b_seciliDolar\b': 'settingsController.seciliDolar.value',
        r'\b_autoSync\b': 'settingsController.autoSync.value',
        r'\b_isPasswordVisible\b': 'settingsController.isPasswordVisible.value',
        r'\b_basilacakBarkodKey\b': 'stockFormController.basilacakBarkodKey',
        r'\b_adetController\b': 'stockFormController.adetController',
        r'\b_c\b': 'stockFormController.c',
        r'\b_seciliStok\b': 'stockFormController.seciliStok.value',
        r'\bocData\b': 'openCartController.ocData'
    }

    for old, new in reps.items():
        content = re.sub(old, new, content)

    # 4. Method usages
    content = content.replace("_fiyatHesapla();", "stockFormController.fiyatHesapla();")
    content = content.replace("_fiyatHesapla,", "stockFormController.fiyatHesapla,")
    content = content.replace("_fiyatHesapla)", "stockFormController.fiyatHesapla)")
    content = content.replace("_formuTemizle();", "stockFormController.formuTemizle();")
    content = content.replace("_formuDoldur(stok);", "stockFormController.formuDoldur(stok);")
    content = content.replace("_formuDoldur(Stok(", "stockFormController.formuDoldur(Stok(")
    content = content.replace("_stokKaydet,", "() => stockFormController.stokKaydet(_mesajGoster, _urunSec),")
    content = content.replace("_stokKaydet();", "stockFormController.stokKaydet(_mesajGoster, _urunSec);")
    content = content.replace("_stokSilOnayli,", "() => stockFormController.stokSil(_mesajGoster),")
    content = content.replace("_stokSilOnayli);", "() => stockFormController.stokSil(_mesajGoster));")
    content = content.replace("_stokDataUrunKopyala,", "() => stockFormController.urunKopyala(_mesajGoster, _urunSec),")

    content = content.replace("_guncelKurlariCek", "settingsController.guncelKurlariCek")
    content = content.replace("_ocBaglantisiniYonet", "openCartController.ocBaglantisiniYonet")
    content = content.replace("_ocSenkronizeEt", "openCartController.senkronizeEt")
    content = content.replace("_ocDurumGuncelle", "openCartController.durumGuncelle")
    content = content.replace("_ocUrunuTamamenSil", "openCartController.urunuTamamenSil")
    content = content.replace("_barkodBasimiBaslat", "printerController.barkodBasimiBaslat")
    content = content.replace("_aramaYap", "stockListController.aramaYap")
    content = content.replace("_hizliAra", "stockListController.hizliAra")
    content = content.replace("_stokSiralamaDegistir", "stockListController.stokSiralamaDegistir")
    content = content.replace("_stokDataSil", "stockFormController.stokSil")
    
    # Clean up the dead variables
    content = re.sub(r'Map<String, dynamic> openCartController\.ocData = \{\};.*?\n', '', content)
    content = re.sub(r'List<Stok> stockListController\.stokListesi = \[\];.*?\n', '', content)
    content = re.sub(r'List<Stok> stockListController\.filtreliListe = \[\];.*?\n', '', content)
    content = re.sub(r'String stockListController\.seciliSiralama\.value = "LDATE";\n', '', content)
    content = re.sub(r'final FocusNode stockListController\.aramaFocusNode =.*?FocusNode\(\);\n', '', content, flags=re.DOTALL)
    content = re.sub(r'final TextEditingController stockListController\.aramaController =.*?TextEditingController\(\);\n', '', content, flags=re.DOTALL)
    content = re.sub(r'final ScrollController stockListController\.listScrollController = ScrollController\(\);\n', '', content)
    content = re.sub(r'Timer\?\s*_scrollSelectionTimer;\s*\n', '', content)
    content = re.sub(r'bool openCartController\.isOcConnected\.value = false;\s*\n', '', content)
    content = re.sub(r'String\? openCartController\.ocProductId\.value;\s*\n', '', content)
    content = re.sub(r'Stok\? stockFormController\.seciliStok\.value;\s*\n', '', content)
    content = re.sub(r'bool settingsController\.autoSync\.value = false;\s*\n', '', content)
    content = re.sub(r'bool settingsController\.isPasswordVisible\.value = false;\s*\n', '', content)
    content = re.sub(r'String\? printerController\.seciliYazici\.value;\s*\n', '', content)
    content = re.sub(r'List<String> printerController\.yaziciListesi = \[\];\s*\n', '', content)
    content = re.sub(r'bool settingsController\.seciliTl\.value = true;\s*\n', '', content)
    content = re.sub(r'bool settingsController\.seciliEuro\.value = false;\s*\n', '', content)
    content = re.sub(r'bool settingsController\.seciliDolar\.value = false;\s*\n', '', content)
    content = re.sub(r"String stockFormController\.basilacakBarkodKey = 'barkod';\s*\n", '', content)
    content = re.sub(r'final TextEditingController stockFormController\.adetController = TextEditingController\(\s*text: "1",\s*\);\s*\n', '', content, flags=re.DOTALL)
    content = re.sub(r'final Map<String, TextEditingController> stockFormController\.c = \{.*?\};\n', '', content, flags=re.DOTALL)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

process_file('lib/views/stok_ana_sayfa.dart')
