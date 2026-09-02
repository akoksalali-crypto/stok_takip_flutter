import 'package:flutter_test/flutter_test.dart';
import 'package:stok_takip_flutter/models/stok_model.dart';

void main() {
  group('Stok model', () {
    test('veritabanı kaydındaki ondalıklı miktarı tam sayıya dönüştürür', () {
      final stok = Stok.fromMap({
        'KIMLIK': 42,
        'STOK_KOD': 'URUN-42',
        'STOK_ADI': 'Deneme Ürün',
        'BARKOD': '8690000000042',
        'MIKTAR': '12.0',
        'ALIS': '85.50',
        'SATIS': '120.00',
      });

      expect(stok.id, 42);
      expect(stok.stokKod, 'URUN-42');
      expect(stok.miktar, '12');
      expect(stok.satisFiyati, '120.00');
    });

    test('bozuk, virgüllü veya boş miktar değerlerinde çökmeden varsayılan 0 atar', () {
      final stokVirgul = Stok.fromMap({'MIKTAR': '15,7'});
      final stokBos = Stok.fromMap({'MIKTAR': ''});
      final stokGecersiz = Stok.fromMap({'MIKTAR': 'abc'});
      final stokNull = Stok.fromMap({'MIKTAR': null});

      expect(stokVirgul.miktar, '15');
      expect(stokBos.miktar, '0');
      expect(stokGecersiz.miktar, '0');
      expect(stokNull.miktar, '0');
    });

    test('toMap güncelleme için kimliği ve stok alanlarını korur', () {
      final stok = Stok(
        id: 7,
        stokKod: 'KOD-7',
        stokAdi: 'Body',
        barkod: '123456789',
        miktar: '5',
        kdv: '10',
      );

      final map = stok.toMap();

      expect(map['KIMLIK'], 7);
      expect(map['STOK_KOD'], 'KOD-7');
      expect(map['BARKOD'], '123456789');
      expect(map['MIKTAR'], '5');
      expect(map['KDV'], '10');
    });
  });
}
