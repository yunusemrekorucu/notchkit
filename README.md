<p align="center">
  <img src="App/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png" width="128" alt="NotchKit ikonu">
</p>

<h1 align="center">NotchKit</h1>

<p align="center">
  MacBook'unun notch'unu kullanışlı bir alana çeviren, SwiftUI ile yazılmış açık kaynak bir macOS uygulaması.<br>
  Müzik, takvim, notlar, görevler, Pomodoro ve dosyalar. Hepsi ekranın en tepesinde.
</p>

---

## Özellikler

- **Notch davranışı:** Üzerine gelince hafifçe büyür. Tıklayınca ya da iki parmakla aşağı kaydırınca açılır, fare çıkınca ya da dışarı tıklayınca kapanır. Açılırken haptik geri bildirim verir.
- **Nook (widget'lar):** Notch'un genişliği seçtiğin widget'lara göre ayarlanır.
  - **Medya oynatıcı:** sistem genelinde çalan medya (Spotify, Apple Music, tarayıcılar…), albüm kapağı, ilerleme çubuğu ve kontroller
  - **Takvim:** gün şeridi, etkinlikler, Google Meet, Zoom, Teams ve Webex için "Katıl" butonu
  - **Pomodoro:** odak, kısa mola ve uzun mola döngüsü, ses bildirimi
  - **Notlar** ve **Yapılacaklar**
  - **Hızlı Uygulamalar:** sabitlediğin uygulamaları tek tıkla aç
  - **Kestirmeler:** macOS Kestirmeler uygulamasındaki kestirmeleri çalıştır
  - **Ayna:** kamerayı ayna olarak kullan
- **Tray:** Notch'a sürüklenen dosyaları saklayan bir tepsi ve AirDrop bırakma alanı.
- **Canlı aktiviteler:** Notch kapalıyken iki yanında küçük göstergeler belirir: çalan medya (kapak ve ses çubukları), Pomodoro geri sayımı, şarj, yaklaşan etkinlik ve tepsideki dosya sayısı.
- **Hareketler:** Notch üzerinde yatay kaydırarak sonraki veya önceki parçaya geçilir. Sağ tık menüsünden ayarlara ulaşılır.
- **Ayarlar:** Widget'ları canlı önizlemeyle ekleyip çıkarabilir, sürükleyerek sıralayabilir ve her widget'ı ayrı ayrı ayarlayabilirsin.

## Gereksinimler

- macOS 14.6 veya üzeri (notch'lu MacBook önerilir; notch'suz ekranlarda da çalışır)
- Xcode 16 veya üzeri
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) ve [CMake](https://cmake.org)

```bash
brew install xcodegen cmake
```

## Derleme

```bash
git clone --recursive https://github.com/yunusemrekorucu/notchkit.git
cd notchkit
xcodegen generate
open Nook.xcodeproj   # ya da:
xcodebuild -project Nook.xcodeproj -scheme Nook -configuration Release -derivedDataPath build/DD build
```

Medya köprüsü (`vendor/mediaremote-adapter`) ilk derlemede otomatik olarak derlenir. Uygulama `Nook.app` adıyla oluşur. `/Applications` klasörüne kopyalayıp çalıştırabilirsin.

> Repoyu `--recursive` olmadan klonladıysan alt modülü şu komutla çek: `git submodule update --init`

## İzinler

Her izin, yalnızca ilgili özellik ilk kez kullanıldığında istenir:

| İzin | Kullanıldığı yer |
|---|---|
| Takvim | Takvim widget'ı ve yaklaşan etkinlik göstergesi |
| Kamera | Ayna widget'ı |
| Otomasyon (Apple Events) | Medya kontrolü |

## Nasıl çalışır?

- Her ekranda, menü çubuğu seviyesinde, tam genişlikte ve şeffaf bir `NSPanel` bulunur. Notch bu panelin içinde SwiftUI ile çizilir ve animasyonla büyür.
- Şimdi çalan bilgisi macOS'un özel MediaRemote framework'ünden gelir. macOS 15.4 ve sonrasında bu framework'e doğrudan erişilemediği için açık kaynak [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) projesi kullanılır.
- Ayarlar [Defaults](https://github.com/sindresorhus/Defaults) ile saklanır. Girişte başlatma özelliği [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin-Modern) ile sağlanır.

## Proje yapısı

```
App/Sources
├── App/             Uygulama girişi, ayarlar penceresi
├── Notch/           Panel, notch şekli, durum makinesi, fare/sürükleme takibi
├── Nook/            Widget'lar (medya, takvim, Pomodoro, notlar…)
├── Tray/            Dosya tepsisi ve AirDrop
├── LiveActivities/  Kapalı notch göstergeleri, pil izleme
├── Media/           mediaremote-adapter köprüsü
├── Settings/        Ayarlar ekranları
└── Shared/          Ayar anahtarları, yardımcılar
design/AppIcon.svg   Uygulama ikonunun kaynağı
```

## Lisans

[MIT](LICENSE). `vendor/mediaremote-adapter` kendi lisansıyla (BSD-3-Clause) dağıtılır.

NotchKit bağımsız bir projedir ve herhangi bir ticari notch uygulamasıyla bağlantısı yoktur.

---

<sub>**English:** NotchKit is an open-source SwiftUI app that turns the MacBook notch into a home for widgets (media, calendar, Pomodoro, notes, to-dos, quick apps, shortcuts), a file tray with AirDrop, and live activities. Build with `xcodegen generate` and Xcode 16+ on macOS 14.6+.</sub>
