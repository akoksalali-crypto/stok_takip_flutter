import re

def split_ui():
    with open('lib/controllers/stok_controller.dart', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    controller_lines = []
    ui_lines = []
    
    in_widget = False
    brace = 0
    skip_next = False
    
    for i, line in enumerate(lines):
        if not in_widget:
            if line.strip() == '@override' and i+1 < len(lines) and (lines[i+1].strip().startswith("Widget ") or lines[i+1].strip().startswith("Widget? ")):
                ui_lines.append(line)
                continue
                
            if line.strip().startswith("Widget ") or line.strip().startswith("Widget? "):
                in_widget = True
                ui_lines.append(line)
                
                l = line
                while '"' in l:
                    p1 = l.find('"')
                    p2 = l.find('"', p1+1)
                    if p2 == -1: break
                    l = l[:p1] + l[p2+1:]
                while "'" in l:
                    p1 = l.find("'")
                    p2 = l.find("'", p1+1)
                    if p2 == -1: break
                    l = l[:p1] + l[p2+1:]
                brace = l.count('{') - l.count('}')
                if brace <= 0 and '{' in l and '}' in l:
                    in_widget = False
            else:
                controller_lines.append(line)
        else:
            ui_lines.append(line)
            l = line
            while '"' in l:
                p1 = l.find('"')
                p2 = l.find('"', p1+1)
                if p2 == -1: break
                l = l[:p1] + l[p2+1:]
            while "'" in l:
                p1 = l.find("'")
                p2 = l.find("'", p1+1)
                if p2 == -1: break
                l = l[:p1] + l[p2+1:]
                
            brace += l.count('{')
            brace -= l.count('}')
            if brace <= 0:
                in_widget = False

    with open('lib/controllers/stok_controller.dart', 'w', encoding='utf-8') as f:
        f.writelines(controller_lines)
        
    # Now create stok_ana_sayfa.dart
    ui_content = "".join(ui_lines)
    
    # We need to replace property access with controller.property
    props = [
        'c', 'stokListesi', 'filtreliListe', 'seciliStok', 'seciliSiralama',
        'aramaController', 'aramaFocusNode', 'stokKodFocusNode', 'listScrollController',
        'isOcConnected', 'ocProductId', 'seciliYazici', 'basilacakBarkodKey',
        'adetController', 'resimBytes', 'ilkAcilis', 'isKurlarLoading', 'isLoading',
        'kurlariHesapla', 'hizliAra', 'aramaYap', 'stokSiralamaDegistir', 'stokDetayGetir',
        'yeniKayit', 'stokKaydet', 'stokDataSil', 'stokSilOnayli', 'generateBarkodDialog',
        'barkodUret', 'mesajGoster', 'ocSenkronizeEt', 'ocUrunuTamamenSil', 'ocDurumGuncelle',
        'guncelKurlariCek', 'resimYukle', 'resimSil', 'cikisOnayi', 'barkodBasimiBaslat',
        'topluDegistirIslemi', 'dbHelper', 'mounted'
    ]
    
    for p in props:
        ui_content = re.sub(r'\b' + p + r'\b', f'controller.{p}', ui_content)
        
    # However, 'context' shouldn't be prefixed if we passed it in, but we didn't add context in props.
    
    ana_sayfa_code = f"""
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/stok_controller.dart';
import '../models/stok_model.dart';
import 'widgets/resim_goster_widget.dart';
import 'widgets/opencart_preview_widget.dart';
import 'widgets/toplu_duzenleme_tab_widget.dart';
import 'widgets/doviz_fiyatlar_tab_widget.dart';
import 'widgets/kur_fiyat_alani_widget.dart';
import 'widgets/barkodlar_tab_widget.dart';
import 'widgets/ayarlar_tab_widget.dart';
import 'widgets/sol_urun_listesi_widget.dart';
import 'widgets/stok_detay_form_widget.dart';

class StokAnaSayfa extends GetView<StokController> {{
  const StokAnaSayfa({{super.key}});

{ui_content}
}}
"""
    with open('lib/views/stok_ana_sayfa.dart', 'w', encoding='utf-8') as f:
        f.write(ana_sayfa_code)

if __name__ == '__main__':
    split_ui()
