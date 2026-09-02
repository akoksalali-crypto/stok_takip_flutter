import re

def fix_all():
    # 1. Fix StokController private properties that were missed
    with open('lib/controllers/stok_controller.dart', 'r', encoding='utf-8') as f:
        c_content = f.read()

    missed_props = {
        '_seciliTl': 'seciliTl',
        '_seciliEuro': 'seciliEuro',
        '_seciliDolar': 'seciliDolar',
        '_autoSync': 'autoSync',
        '_fiyatlariDovizeCevir': 'fiyatlariDovizeCevir',
        '_sabitfiyatlariDovizeCevir': 'sabitfiyatlariDovizeCevir',
        '_stokGecmisiSekmesi': 'stokGecmisiSekmesi',
        '_ocService': 'ocService'
    }

    for old, new in missed_props.items():
        c_content = re.sub(r'\b' + old + r'\b', new, c_content)

    with open('lib/controllers/stok_controller.dart', 'w', encoding='utf-8') as f:
        f.write(c_content)


    # 2. Fix stok_ana_sayfa.dart
    with open('lib/views/stok_ana_sayfa.dart', 'r', encoding='utf-8') as f:
        v_content = f.read()

    # Fix missed props by prefixing with controller.
    for old, new in missed_props.items():
        v_content = re.sub(r'\b' + old + r'\b', f'controller.{new}', v_content)

    # Fix controller.paramName: to paramName:
    v_content = re.sub(r'controller\.([a-zA-Z0-9_]+)\s*:', r'\1:', v_content)

    # Fix setState(() { ... }) and setState((){})
    # Replace setState(() { ... }) with controller.update() and execute the block
    def replace_setstate(match):
        body = match.group(1)
        # We need to change `_isPasswordVisible = !_isPasswordVisible;` which might exist, but we fixed it in _input.
        # Wait, if there are assignments inside setState, we just keep the assignment and append controller.update();
        return f"{body}\ncontroller.update();"
    
    # Use a simpler approach: replace setState(() { with nothing, and }); with controller.update();
    # This is tricky because of nested braces. Let's just do it manually for known cases.
    
    # Known setState in stok_ana_sayfa.dart:
    # setState(() { controller.autoSync = val ?? false; });
    v_content = v_content.replace("setState(() {\n          controller.autoSync = val ?? false;\n        });", "controller.autoSync = val ?? false;\n        controller.update();")
    
    # setState(() { controller.seciliTl = true; controller.seciliEuro = false; controller.seciliDolar = false; });
    v_content = v_content.replace("setState(() {\n                      controller.seciliTl = true;\n                      controller.seciliEuro = false;\n                      controller.seciliDolar = false;\n                    });", "controller.seciliTl = true;\n                      controller.seciliEuro = false;\n                      controller.seciliDolar = false;\n                      controller.update();")
    v_content = v_content.replace("setState(() {\n                      controller.seciliTl = false;\n                      controller.seciliEuro = true;\n                      controller.seciliDolar = false;\n                    });", "controller.seciliTl = false;\n                      controller.seciliEuro = true;\n                      controller.seciliDolar = false;\n                      controller.update();")
    v_content = v_content.replace("setState(() {\n                      controller.seciliTl = false;\n                      controller.seciliEuro = false;\n                      controller.seciliDolar = true;\n                    });", "controller.seciliTl = false;\n                      controller.seciliEuro = false;\n                      controller.seciliDolar = true;\n                      controller.update();")
    v_content = v_content.replace("setState(() {})", "controller.update()")
    v_content = v_content.replace("setState(() {});", "controller.update();")
    v_content = v_content.replace("onStateUpdate: () => setState(() {}),", "onStateUpdate: () => controller.update(),")
    
    # Also add DbHelper import
    if "import '../services/db_helper.dart';" not in v_content:
        v_content = v_content.replace("import '../models/stok_model.dart';", "import '../models/stok_model.dart';\nimport '../services/db_helper.dart';")

    with open('lib/views/stok_ana_sayfa.dart', 'w', encoding='utf-8') as f:
        f.write(v_content)

if __name__ == '__main__':
    fix_all()
