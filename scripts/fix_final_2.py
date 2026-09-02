import re

def fix_all_2():
    with open('lib/controllers/stok_controller.dart', 'r', encoding='utf-8') as f:
        c_content = f.read()

    missed_props = {
        '_yazicilariGetir': 'yazicilariGetir',
        '_secimiScrollIleDegistir': 'secimiScrollIleDegistir',
        '_urunSec': 'urunSec',
        '_linkiAc': 'linkiAc',
        '_initDatabase': 'initDatabase',
        '_verileriGetir': 'verileriGetir',
        '_formuDoldur': 'formuDoldur',
        '_fiyatHesapla': 'fiyatHesapla',
        '_dovizGirislefiyatHesapla': 'dovizGirislefiyatHesapla',
        '_yeniUrunHazirla': 'yeniUrunHazirla',
        '_stokDataUrunKopyala': 'stokDataUrunKopyala',
        '_whatsappIlePaylas': 'whatsappIlePaylas',
        '_idSorgula': 'idSorgula',
        '_ocBaglantisiniYonet': 'ocBaglantisiniYonet',
        '_ocVerileriniYukle': 'ocVerileriniYukle',
        '_findController': 'findController',
        '_replaceController': 'replaceController',
        '_formAcikMi': 'formAcikMi'
    }

    for old, new in missed_props.items():
        c_content = re.sub(r'\b' + old + r'\b', new, c_content)

    with open('lib/controllers/stok_controller.dart', 'w', encoding='utf-8') as f:
        f.write(c_content)

    with open('lib/views/stok_ana_sayfa.dart', 'r', encoding='utf-8') as f:
        v_content = f.read()

    for old, new in missed_props.items():
        v_content = re.sub(r'\b' + old + r'\b', f'controller.{new}', v_content)

    # Fix widget named params
    params_to_fix = [
        'stokKodFocusNode', 'isOcConnected', 'ocProductId',
        'findController', 'replaceController', 'formAcikMi'
    ]
    for param in params_to_fix:
        v_content = re.sub(rf'controller\.{param}\s*:', f'{param}:', v_content)

    # In case there are other controller.param: matches
    # v_content = re.sub(r'controller\.([a-zA-Z0-9_]+)\s*:', r'\1:', v_content)

    with open('lib/views/stok_ana_sayfa.dart', 'w', encoding='utf-8') as f:
        f.write(v_content)

if __name__ == '__main__':
    fix_all_2()
