import os

def clean_method(content, method_start):
    while True:
        start_idx = content.find(method_start)
        if start_idx == -1:
            break
        brace_idx = content.find('{', start_idx)
        if brace_idx != -1:
            brace_count = 1
            curr_idx = brace_idx + 1
            while brace_count > 0 and curr_idx < len(content):
                if content[curr_idx] == '{':
                    brace_count += 1
                elif content[curr_idx] == '}':
                    brace_count -= 1
                curr_idx += 1
            content = content[:start_idx] + content[curr_idx:]
            print(f"Removed method starting with: {method_start}")
        else:
            break
    return content

def clean_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    methods_to_remove = [
        "void stockListController.hizliAra(",
        "void printerController.barkodBasimiBaslat(",
        "void stockListController.aramaYap(",
        "Future<void> openCartController.ocBaglantisiniYonet(",
        "Future<void> openCartController.senkronizeEt(",
        "Future<void> openCartController.urunuTamamenSil(",
        "Future<void> openCartController.durumGuncelle(",
        "Future<void> stockFormController.stokSil(",
        "void () => stockFormController.stokSil(_mesajGoster)("
    ]

    for method in methods_to_remove:
        content = clean_method(content, method)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

clean_file('lib/views/stok_ana_sayfa.dart')
