# Prismaze — Unity Yerel Geliştirme Kurulumu

## Mevcut durum — 2026-09-06

Unity 6.3 LTS + C# + URP 2D geçişi onaylıdır. Bu çalışma sırasında Unity Editor
tespit edilmedi; kurulum, import, Unity testleri veya APK başarısı iddia edilmez.
Ana uygulama kesin sürümü ProjectSettings/ProjectVersion.txt içinde seçer.
Resmi doğrulanmış başlangıç adayı [6000.3.17f1](https://unity.com/releases/editor/whats-new/6000.3.17f1);
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

## Editor mevcut olduğunda

1. Unity Hub'a D:/Prismaze kökünü ekle; ProjectVersion.txt ile aynı Editor'ü kullan.
   Pin henüz oluşmadıysa ana uygulamanın seçiminden önce farklı sürümle yükseltme yapma.
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
| Oyuncu kaydı | Application.persistentDataPath/save_v1.json |
| Son geçerli backup | Application.persistentDataPath/save_v1.backup.json |
| Ayarlar | Application.persistentDataPath/settings_v1.json |

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

Dikey dilim ads/billing/consent SDK'sı veya INTERNET izni paketlemez. Merged
manifest ve build raporu denetlenir; uçak modunda gerçek oynanış ayrıca sınanır.
iOS için daha sonra macOS, uyumlu Xcode, imzalama ve fiziksel cihaz QA gerekir.

[Aktif uygulama planı](docs/superpowers/plans/2026-09-06-prismaze-unity-implementation-plan.md)
