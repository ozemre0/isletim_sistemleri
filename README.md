# isletim_sistemleri_odev

Bu proje, işlem zamanlama algoritmalarını (FCFS, SJF, Öncelik vb.) görselleştiren bir Flutter uygulamasıdır. Aşağıdaki adımları izleyerek çalıştırabilirsiniz.

## Notlar
- Gerekirse `flutter doctor` ile eksik araçları tamamlayın.
- Kodda yer alan örnek veri dosyaları `assets/odev1_case*.txt` altında. Uygulamada CSV yükleme/sonuç alma bölümleri bunları kullanıyor.
- Flutter nasıl kurulacağını anlatan video (14dakika) : https://www.youtube.com/watch?v=VFDbZk2xhO4
- GitHub Pages üzerinde yayınlandı, kodu çalıştırmadan bakmak isterseniz doğrudan web üzerinden çalışan halini görebilirsiniz böylece flutter kurmanıza gerek yok projenin çıktısını görebilmek için. Kodların ana kısmı (algoritmalar...) `lib/` klasöründe.
- https://ozemre0.github.io/isletim_sistemleri/  (github pages linki)
- web dosyalarını ben yazmadım , benim yazdığım kodlar lib içindeki dart kodlarıdır. Flutter in cross platform özelliği sayesinde web e deploy ettim. Web kodlarıni ben web e build ederken oluşturuldu.

## Gereksinimler
- Flutter SDK (3.x önerilir) kurulu olmalı.
- `flutter doctor` çıktısında eksik bileşen olmaması (Android Studio ya da VS Code eklentileri, emulator/simulator, Chrome).

## Kurulum ve Çalıştırma
1. Bağımlılıkları indirin:
   ```bash
   flutter pub get
   ```
2. Mobil (Android/iOS) için bir cihaz ya da emulator açın, ardından:
   ```bash
   flutter run
   ```
3. Web için (Chrome):
   ```bash
   flutter run -d chrome
   ```

## Flutter nasıl kurulur? (özet)
- **İndir**: https://docs.flutter.dev/get-started/install adresinden işletim sistemini seçip SDK’yı indirin.
- **PATH ekleyin**: SDK içindeki `flutter/bin` klasörünü sistem PATH’ine ekleyin.
- **Bileşenler**: Android Studio (SDK/Platform Tools) ya da VS Code + Flutter/Dart eklentileri. iOS için Xcode (macOS).
- **Kontrol**: Terminalde `flutter doctor` çalıştırın; eksik görünen bileşenleri tamamlayın.

