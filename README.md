# Better Windows Aesthetic

Temiz bir Windows 11 (Tiny11 dahil) kurulumunu tek sihirbazla şeffaf ve animasyonlu bir masaüstüne çevirir.

One wizard that turns a fresh Windows 11 (Tiny11 included) install into a transparent, animated desktop.

## Kurulum

1. [Releases](https://github.com/Ege-BULUT/better-windows-aesthetic/releases/latest) sayfasından `BetterWindowsAesthetic-Setup.exe` dosyasını indir.
2. Çalıştır. Bileşenlerin hepsi seçili gelir; istemediklerinin tikini kaldır.
3. İnternet bağlantısı gerekir: uygulamalar kurulum sırasında kendi resmi GitHub sürümlerinden indirilir.

Hata olursa ayrıntılar `%TEMP%\better-windows-aesthetic.log` dosyasındadır.

## Bileşenler

| Bileşen | Ne yapar |
|---|---|
| Koyu tema + şeffaf Başlat menüsü | Koyu modu ve Windows saydamlık efektlerini açar |
| Şeffaf görev çubuğu | [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB) (portable), tamamen şeffaf ayarla, açılışta başlar |
| Lively Wallpaper | [Lively](https://github.com/rocksdanister/lively) animasyonlu duvar kağıdı uygulaması |
| Windows XP Bliss Night | [Bliss Night](https://livelywallpaper.app/live-wallpapers/windows-xp-bliss-night/) videosunu indirir ve duvar kağıdı yapar |
| Zen Browser | [Zen Browser](https://github.com/zen-browser/desktop) |
| Transparent Zen | [Transparent Zen](https://github.com/Ege-BULUT/transparent-zen) eklentisi, `userChrome.css` ve `user.js` ile şeffaf arayüz |
| Saat ve takvim widget'ı | [WinWidgets](https://github.com/beyluta/WinWidgets) + şeffaf saat/takvim widget'ı, açılışta başlar |
| Arama çubuğu | [Flow Launcher](https://github.com/Flow-Launcher/Flow.Launcher), macOS Spotlight benzeri, `Alt+Space` |

## Kaldırma

Sihirbaz kendi kaldırıcısını kurmaz. Her uygulama Windows Ayarlar > Uygulamalar'dan ayrı ayrı kaldırılır. TranslucentTB portable olduğu için `%LOCALAPPDATA%\Programs\TranslucentTB` klasörünü sil ve `HKCU\...\Run` altındaki `TranslucentTB` kaydını kaldır.

## Geliştirme

- `setup.iss`: [Inno Setup 6](https://jrsoftware.org/isinfo.php) sihirbazı. Derlemek için: `iscc setup.iss`
- `install.ps1`: her bileşenin kurulum adımı. Tek adım denemek için: `powershell -ExecutionPolicy Bypass -File install.ps1 -Step theme`
- `assets/`: widget, Zen ve TranslucentTB ayar dosyaları
- `v*` etiketi push edilince GitHub Actions exe'yi derleyip Release'e ekler.
