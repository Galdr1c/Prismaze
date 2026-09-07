# Prismaze

Android öncelikli, offline-first, portre 2D optik bulmaca oyunu.
Temel oynanış, bölümler, kayıt ve ilerleme bağlantısız çalışır. Reklam, consent
ve Google Play Billing ayrı Android servisleridir; bağlantı olmadığında oyun
oynanmaya devam eder. Aktif teknoloji Unity 6.3 LTS, C#, URP 2D,
ScriptableObject ve JSON yerel kayıttır. iOS daha sonraki olası hedeftir.

## Aktif belgeler

- [Unity tasarımı](docs/superpowers/specs/2026-09-06-prismaze-unity-design.md)
- [Unity uygulama planı ve kabul kapıları](docs/superpowers/plans/2026-09-06-prismaze-unity-implementation-plan.md)
- [Yerel kurulum ve doğrulama](SETUP.md)
- [Asset kaynak/lisans kaydı](ASSET_LICENSES.md)
- [Godot tarihsel arşivi](docs/archive/godot/README.md)

## Kapsam ve durum

İlk dikey dilim 12 el yapımı bölümdür: kaynak, ayna, prizma, hedef, duvar,
deterministik ışın çözümü, reset, ücretsiz canonical hint, kayıt/devam ve
ilk bölümde gerçek dokunuşu bekleyen animasyonlu el tutorial'ı.
Startup stinger yeni uygulama oturumunda yalnız bir kez çalar; bütün müzik,
fontlar, bölümler ve kayıt internet olmadan çalışır.

Unity 6000.3.17f1, `D:/Unity/6000.3.17f1/Editor/Unity.exe` konumuna kuruldu.
URP 17.3.0, uGUI 2.0.0 ve Test Framework 1.6.0 sürümleri sabitlendi.
Saf C# çekirdeğinde **723 kontrol geçti**. Kurulu Unity'nin gerçek API'leri ve
uGUI kaynaklarıyla bağımsız runtime C# derlemesi **0 hata, 0 uyarı** verdi.
Unity Personal lisansı etkinleştirildi. Gerçek Unity import/derlemesi,
4 EditMode testi ve 3 PlayMode testi geçti. Monetization adapter'ları test
kimlikleriyle geliştirme APK'sına dahil edildi. Fiziksel cihaz ve grafik
performansı doğrulaması henüz yapılmadı.

## Açma ve test

Unity lisansını etkinleştirdikten sonra bu proje kökünü editörde aç.
`Prismaze > Open Game` menüsü URP 2D ayarlarını ve Boot sahnesini hazırlar;
12 bölüm `Assets/Resources/Levels` altında ScriptableObject dosyalarıdır.
Play düğmesi oyunu açar.

```powershell
.\tools\Test-Core.ps1
dotnet build Tests/UnityCompile/RuntimeCompile.csproj -c Release
.\tools\Test-Unity.ps1
```

`Prismaze > Build Android Development APK` menüsü veya
`.\tools\Build-Android.ps1`, `Builds/Android/Prismaze-dev.apk` üretir.
Geliştirme APK'sı AdMob/UMP/Billing test adapter'larını ve ilgili izinleri içerir.
Bağlı cihazda kurulum için `.\tools\Install-Android.ps1` kullanılabilir.
Yeni kayıt `Application.persistentDataPath/save-unity-v1.json` dosyasındadır;
eski Godot kayıt formatı otomatik içeri alınmaz.

Dikey dilimden sonra solved-state → scramble → solver → difficulty validation
ile deterministik generator ve doğrulanmış seed kataloğu gelir. Runtime'da
solver araması veya rastgele retry yapılmaz. Backend, online hesap, cloud save
ve tüketilebilir ekonomi ilk dilime dahil değildir. Reklam, consent ve satın alma
bağlantı yoksa temel ilerlemeyi engellemez.

Godot kaynakları LegacyGodot/ altındadır; eski test/APK sonuçları yalnız
tarihsel kayıttır. PLAYER_PSYCHOLOGY_GUIDE.md eski fikir referansıdır; içindeki
tamamlanma ve ekonomi ifadeleri aktif Unity kapsamı sayılmaz.
