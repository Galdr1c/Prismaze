# Prismaze — Unity Yerel Geliştirme Kurulumu

## Mevcut durum — 2026-09-06

Unity 6000.3.17f1 `D:/Unity/6000.3.17f1/Editor/Unity.exe` konumuna kuruldu.
Unity Personal lisansı etkinleştirildi. Gerçek editör import/derlemesi ile
4 EditMode ve 3 PlayMode testi geçti. Saf C# çekirdeğinde ayrıca 723 kontrol
geçti. Android APK ve fiziksel cihaz QA'sı henüz yapılmadı.
Ana uygulamanın ProjectSettings/ProjectVersion.txt pin'i 6000.3.17f1 olarak gözlendi.
Resmi sürüm kaydı: [6000.3.17f1](https://unity.com/releases/editor/whats-new/6000.3.17f1);
bu, en yeni sürüm iddiası değildir. Bu belge hiçbir araç indirmez.

Önceki ortam kaydı Git, Android Studio, Android SDK Platform 36, Build Tools
36.0.0, Platform Tools 37.0.1, Android 36 emulator imajları, Microsoft OpenJDK 17
ve ANDROID_HOME/ANDROID_SDK_ROOT/JAVA_HOME içeriyordu. Paylaşılan SDK/JDK
silinmedi; bunların Unity'nin seçilen sürümüyle uyumu yeniden doğrulanmalıdır.

Godot winget paketi kaldırıldı. Temizlenen Godot export template TPZ
(1.281.349.702 bayt), template android_debug.apk (127.260.725), checksums,
.godot cache (45.587.563), eski exports/android/prismaze-debug.apk (95.691.220)
ve motor dosyaları (181.057.040) yaklaşık 1,6 GiB alan açtı.
Bunlar önceki temizlik raporudur; bu belge çalışması ek silme yapmadı.
Godot kaynakları LegacyGodot/ içinde korunur.

## Lisansı etkinleştirme ve projeyi açma

1. [Unity Hub](https://unity.com/download) uygulamasını aç veya kur, hesabına giriş yap.
2. Settings/Preferences → Licenses → Add license yolundan lisansını etkinleştir.
   Personal koşullarına uygunsan ücretsiz Personal seçeneğini kullan.
3. Installs → Locate ile `D:/Unity/6000.3.17f1/Editor/Unity.exe` dosyasını seç.
   Editörü tekrar indirmen gerekmez.
4. Projects → Add ile `D:/Prismaze` klasörünü ekle.
5. Import bittikten sonra `Prismaze > Open Game` menüsü Boot sahnesini ve
   URP 2D ayarlarını hazırlar. Play ile oyuna girilir.

```powershell
.\tools\Test-Core.ps1
dotnet build Tests/UnityCompile/RuntimeCompile.csproj -c Release
.\tools\Test-Unity.ps1
```

Üç komut da geçti; Unity testi etkinleştirilmiş editör lisansını kullanır.
Unity test logları `artifacts/unity/` altında tutulur.

## Android ve editör kabulü

1. Unity Hub'a D:/Prismaze kökünü ekle; ProjectVersion.txt ile aynı Editor'ü kullan.
2. Seçilen Editor için Android Build Support ve desteklenen SDK/NDK/OpenJDK
   modüllerini kur/doğrula. Eski Godot NDK r28b ve CMake pin'lerini uygulama.
   Ortak SDK'yı değiştirmek yerine Unity'nin kendi araç modüllerini tercih et.
3. Import tamamlandıktan sonra Console derleme hatalarını çöz; URP paket pin'i
   ve 2D Renderer asset referanslarını Graphics ile etkin Quality seviyelerinde denetle.
4. Orthographic Camera, Canvas/CanvasScaler, safe-area, EventSystem ve Boot
   girişini kontrol et. Android Build Profile'da portre ve doğru sahne/bootstrap
   girişini seç. Başlangıç sahne adı gerçek uygulamadan alınır.
5. EditMode ve PlayMode testlerini Unity Test Runner'da çalıştır; sonuç XML/loglarını
   sakla. Saf C# runner komutunu Core çalışmasının gerçek proje yolundan al.
6. Android debug APK üretip fiziksel cihazda uçak modu, 12 bölüm, tutorial,
   startup sesi, touch ve save/pause/resume testlerini yap.
7. Release için IL2CPP/ARM64, stripping/JSON, imzalı AAB, birleşik manifest ve
   paket içeriğini ayrıca doğrula. Keystore ve parolalar repoya yazılmaz.
   Google Play hedef API şartları yayın tarihinde yeniden kontrol edilir.

URP ayarları ve Editor/build/test girişleri ana uygulamanın sorumluluğundadır;
bu adımlar hazır proje veya başarı raporu anlamına gelmez.

## Yerel asset ve kayıt yolları

| İçerik | Aktif yol |
|---|---|
| DynaPuff fontlar | Assets/Resources/Fonts/DynaPuff-*.ttf |
| Menü/oyun müziği ve SFX | Assets/Resources/Audio/runtime/ |
| Açılış stinger | Assets/Resources/Audio/stingers/starting_sound.mp3 |
| El yapımı bölümler (hedef) | Assets/Resources/Levels/ ScriptableObject asset'leri |
| Oyuncu kaydı | Application.persistentDataPath/save-unity-v1.json |
| Son geçerli backup | Application.persistentDataPath/save-unity-v1.backup.json |
| Ayarlar | Aynı oyuncu JSON'undaki Settings alanı |

Resources.Load kullanıldığında anahtar Resources'a göre ve uzantısızdır;
örneğin Audio/stingers/starting_sound. Asset eksikliği kontrollü ele alınır.
Runtime ScriptableObject'i değiştirmez; save DTO'ları ayrı tutulur.
[persistentDataPath resmi API](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Application-persistentDataPath.html)

Düzenlenebilir kaynaklar artifacts/ gibi Assets dışı dizinlerde tutulur.
Unity .gdignore kullanmaz; Resources altındaki gereksiz dosyalar da build'e
girebilir. LegacyGodot ve kaynak dosyaları Assets'e kopyalanmaz.
Noto Sans mevcut envanterde yoktur; lisanslı dosyalar ve Unity fallback/glyph
ayarları eklenmeden tipografi kabulü tamamlandı sayılmaz.
[Lisans kaydı](ASSET_LICENSES.md) release öncesi tamamlanmalıdır.

## Doğrulama kanıtı

Rapor Editor tam sürümü, import sonucu, test runner/kapsam/sonuç, build profili,
artifact yolu ve cihaz/OS bilgisini içermelidir. C# test geçişi Unity import
başarısı değildir; APK üretimi fiziksel cihaz QA başarısı değildir.
Eski Godot test sayıları ve silinen APK bu kapılara kanıt oluşturmaz.

Geliştirme APK'sı AdMob, UMP consent ve Unity IAP adapter'larını test
kimlikleriyle içerir; bu nedenle INTERNET, ağ durumu ve Billing izinleri
manifestte görülebilir. Temel oynanış, bölüm yükleme, kayıt ve ilerleme uçak
modunda çalışmaya devam etmelidir. Gerçek reklam kimlikleri, ürün kimliği,
privacy metinleri ve mağaza imzası release öncesi değiştirilir.

APK'yı USB hata ayıklaması açık tek bir Android cihazda kurup başlatmak için:

```powershell
.\tools\Install-Android.ps1
```

Birden fazla cihaz varsa `-DeviceSerial SERIAL` kullan. Cihaz kabulünde uçak
modunda bölüm oynama/kayıt, bağlantı geldiğinde consent, test reklamı ve Billing
fallback akışları ayrı ayrı kontrol edilir.
iOS için daha sonra macOS, uyumlu Xcode, imzalama ve fiziksel cihaz QA gerekir.

[Aktif uygulama planı](docs/superpowers/plans/2026-09-06-prismaze-unity-implementation-plan.md)
