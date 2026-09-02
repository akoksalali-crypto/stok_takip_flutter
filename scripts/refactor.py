import os
import re

def process_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements.items():
        # Using regex to replace whole words only to avoid replacing inside other words
        content = re.sub(r'\b' + old + r'\b', new, content)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

replacements = {
    '_c': 'c',
    '_stokListesi': 'stokListesi',
    '_filtreliListe': 'filtreliListe',
    '_seciliStok': 'seciliStok',
    '_seciliSiralama': 'seciliSiralama',
    '_aramaController': 'aramaController',
    '_aramaFocusNode': 'aramaFocusNode',
    '_stokKodFocusNode': 'stokKodFocusNode',
    '_listScrollController': 'listScrollController',
    '_isOcConnected': 'isOcConnected',
    '_ocProductId': 'ocProductId',
    '_seciliYazici': 'seciliYazici',
    '_basilacakBarkodKey': 'basilacakBarkodKey',
    '_adetController': 'adetController',
    '_resimBytes': 'resimBytes',
    '_ilkAcilis': 'ilkAcilis',
    '_isKurlarLoading': 'isKurlarLoading',
    '_isLoading': 'isLoading',
    '_kurlariHesapla': 'kurlariHesapla',
    '_hizliAra': 'hizliAra',
    '_aramaYap': 'aramaYap',
    '_stokSiralamaDegistir': 'stokSiralamaDegistir',
    '_stokDetayGetir': 'stokDetayGetir',
    '_yeniKayit': 'yeniKayit',
    '_stokKaydet': 'stokKaydet',
    '_stokDataSil': 'stokDataSil',
    '_stokSilOnayli': 'stokSilOnayli',
    '_generateBarkodDialog': 'generateBarkodDialog',
    '_barkodUret': 'barkodUret',
    '_mesajGoster': 'mesajGoster',
    '_ocSenkronizeEt': 'ocSenkronizeEt',
    '_ocUrunuTamamenSil': 'ocUrunuTamamenSil',
    '_ocDurumGuncelle': 'ocDurumGuncelle',
    '_guncelKurlariCek': 'guncelKurlariCek',
    '_resimYukle': 'resimYukle',
    '_resimSil': 'resimSil',
    '_cikisOnayi': 'cikisOnayi',
    '_barkodBasimiBaslat': 'barkodBasimiBaslat',
    '_topluDegistirIslemi': 'topluDegistirIslemi',
    '_scrollSelectionTimer': 'scrollSelectionTimer'
}

# 1. Update stok_controller.dart
process_file('lib/controllers/stok_controller.dart', replacements)

# 2. Update stok_ana_sayfa.dart
process_file('lib/views/stok_ana_sayfa.dart', replacements)

print("Replacement done.")
