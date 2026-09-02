# Stok Takip

Flutter ile geliştirilmiş, yerel SQLite stok veritabanını kullanan ve OpenCart ürün kayıtlarıyla çalışabilen masaüstü stok takip uygulaması.

## Desteklenen platformlar

Uygulamanın mevcut kullanım akışı Windows masaüstüne odaklanır. Ağ paylaşımı, yerel SQLite dosyası, Windows yazıcıları ve pencere yönetimi bu akışın parçalarıdır.

## Gereksinimler

- Flutter SDK (projedeki `pubspec.yaml` ile uyumlu sürüm)
- Windows'ta çalışıyorsanız Visual Studio C++ masaüstü geliştirme bileşenleri
- Stok veritabanına erişim izni
- Ağ veritabanı kullanılacaksa ilgili paylaşım yoluna erişim izni

## Başlatma

```bash
flutter pub get
flutter run -d windows
```

Testleri çalıştırmak için:

```bash
flutter test
```

## Veritabanı yapılandırması

Uygulama başlangıçta aşağıdaki kaynakları sırayla kontrol eder:

1. Ayarlardan daha önce kaydedilmiş veritabanı yolu
2. Uygulama klasöründeki `data/data.s3db`
3. Ağ paylaşımındaki `\\server\MrmDeskCe\data.s3db`
4. Uygulamanın destek veri dizinindeki mevcut `data.s3db`

Her aday dosyanın varlığı ve okunabilirliği denetlenir. Geçerli bir dosya bulunamazsa uygulama boş bir veritabanı oluşturmaz; açılan ekranda geçerli `.s3db` dosyasının tam yolunu girmeniz gerekir. Bu yol doğrulandıktan sonra kaydedilir ve sonraki açılışlarda öncelikli olarak kullanılır.

Örnek ağ yolu:

```text
\\sunucu\paylasim\data.s3db
```

## Yedekleme

Veritabanı dosyasını değiştirmeden, uygulamayı güncellemeden veya toplu stok işlemi yapmadan önce:

1. Uygulamayı tüm kullanıcılar için kapatın.
2. Aktif `.s3db` dosyasını güvenli bir konuma kopyalayın.
3. Ağ paylaşımı kullanılıyorsa yedeğin tamamlandığını ve dosya boyutunun kaynakla uyumlu olduğunu doğrulayın.
4. Geri yükleme gerektiğinde uygulamayı kapatıp yedek dosyayı aktif veritabanı yoluna geri koyun.

SQLite dosyası ağ paylaşımında kullanılıyorsa, aynı anda birden fazla yazma işlemini sınırlamak veri bütünlüğü açısından önemlidir.

## OpenCart bağlantısı

OpenCart ürün ekleme, güncelleme ve silme operasyonları transaction içinde çalışır; işlemde hata oluşursa yapılan yazmalar geri alınır.

Bağlantı ayarları uygulamanın Ayarlar bölümünden yönetilir. Üretim erişim bilgilerini kaynak koda, README'ye veya sürüm kontrolüne eklemeyin.

## Geliştirme notları

- Statik analiz: `flutter analyze`
- Biçimlendirme: `dart format lib test`
- Uygulama testleri: `flutter test`
- Değişiklikleri küçük ve anlamlı Git commit'leri halinde kaydetmeniz önerilir.
