import os
import re

def clean_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    methods_to_remove = [
        r'void\s+stockListController\.hizliAra\s*\(',
        r'void\s+printerController\.barkodBasimiBaslat\s*\(',
        r'void\s+stockListController\.aramaYap\s*\(',
        r'void\s+stockFormController\.formuDoldur\s*\(',
        r'void\s+stockFormController\.fiyatHesapla\s*\(',
        r'Future<void>\s+stockFormController\.stokSil\s*\(',
        r'void\s+\(\)\s*=>\s*stockFormController\.stokSil\(\_mesajGoster\)\s*\(',
        r'void\s+stockFormController\.urunKopyala\s*\(',
        r'Future<void>\s+\(\)\s*=>\s*stockFormController\.stokKaydet\(\_mesajGoster,\s*\_urunSec\)\s*\(',
        r'void\s+settingsController\.guncelKurlariCek\s*\(',
        r'Future<void>\s+openCartController\.ocBaglantisiniYonet\s*\(',
        r'Future<void>\s+openCartController\.senkronizeEt\s*\(',
        r'Future<void>\s+openCartController\.urunuTamamenSil\s*\(',
        r'Future<void>\s+openCartController\.durumGuncelle\s*\('
    ]

    for pattern in methods_to_remove:
        while True:
            match = re.search(pattern, content)
            if match:
                start_index = match.start()
                brace_idx = content.find('{', start_index)
                if brace_idx != -1:
                    brace_count = 1
                    curr_idx = brace_idx + 1
                    while brace_count > 0 and curr_idx < len(content):
                        if content[curr_idx] == '{':
                            brace_count += 1
                        elif content[curr_idx] == '}':
                            brace_count -= 1
                        curr_idx += 1
                    content = content[:start_index] + content[curr_idx:]
                    print(f"Removed method matching {pattern}")
                else:
                    break
            else:
                break

    # Clean up the corrupted definitions that might have different spacing or characters
    content = re.sub(r'void\s+\(\)\s*=>\s*stockFormController\.stokSil\(_mesajGoster\)\(\)\s*\{[^\}]+\}', '', content)
    content = re.sub(r'void\s+\(\)\s*=>\s*stockFormController\.urunKopyala\(_mesajGoster,\s*_urunSec\)\(\)\s*\{[^\}]+\}', '', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

clean_file('lib/views/stok_ana_sayfa.dart')
