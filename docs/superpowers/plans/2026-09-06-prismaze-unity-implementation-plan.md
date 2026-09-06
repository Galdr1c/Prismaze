# Prismaze — Unity Uygulama Planı

**Tarih:** 2026-09-06  
**Tasarım:** [Unity tasarım sözleşmesi](../specs/2026-09-06-prismaze-unity-design.md)  
**Proje kökü:** `D:/Prismaze/`  
**Durum:** Unity geçişi sürüyor. Editor tespit edilmedi; Unity import, EditMode,
PlayMode, APK/AAB ve cihaz kabulü doğrulanmadı. Bu plan kabul hedefidir.

## 1. Teslim ve sorumluluk sınırları

İlk teslim Android portre ekranında internet olmadan oynanabilen 12 el yapımı
bölümdür. Unity + C# + URP 2D + ScriptableObject bölüm içeriği + JSON yerel
kayıt onaylıdır. Olası iOS sonraki hedeftir. Solver, solved-state deterministik
generator ve seed kataloğu dikey dilimden sonra gelir. Monetization ilk dilimde yoktur.

- Ana uygulama çalışması: Unity runtime/UI, Editor araçları, sahneler,
  ProjectSettings, Packages ve kesin Editor pin'i.
- Core çalışması: UnityEngine bağımlılığı olmayan C# mantık ve anlamlı Core testleri.
- Belge çalışması: README.md, SETUP.md, ASSET_LICENSES.md ve docs/**;
  ihtiyaç halinde tools/Prepare-Unity.ps1. Core/UI veya proje ayarlarını değiştirmez.
- Godot kaynakları `LegacyGodot/{scripts,scenes,data,tests,tools,project.godot,
  export_presets.cfg}` altında tarihsel referanstır. Unity runtime bunları yüklemez.

Bu plan görev sahiplerine yeni dosya adları dayatmaz. Tasarımdaki sınıf ve dizin
adları sorumluluk sözleşmesidir; ana uygulamanın gerçek yolları teslim raporuyla eşlenir.

## 2. Aşama 0 — Editor ve proje hazırlığı

1. Unity 6.3 LTS için resmi olarak doğrulanmış başlangıç adayı `6000.3.17f1`;
   ana uygulama kesin sürümü ProjectVersion.txt içinde sabitler. Daha yeni
   uygun sürüm seçilirse resmi kayıt ve gerekçesi kaydedilir. Otomatik indirme yoktur.
2. Editor mevcut olduğunda proje kökünü Hub'a ekle; Android Build Support ve
   bu Editor'ün SDK/NDK/OpenJDK modüllerini doğrula. Ortak Android Studio SDK/JDK
   korunur; eski Godot NDK/CMake pin'leri Unity gereksinimi değildir.
3. Graphics ve Quality için URP Asset + 2D Renderer ata, orthographic Camera,
   portre yönü ve Android Build Profile/başlangıç sahnesini doğrula.
4. Core, runtime, Editor, EditMode ve PlayMode assembly sınırlarını kur.
   Core UnityEngine kullanmaz; Editor/test kodu player'a girmez.
5. Bootstrap servislerini tekilleştir; sahne geçişi yeni AudioService veya
   ikinci input aboneliği oluşturmasın.
6. Mevcut Resources font/audio yollarını kullan; metadata/GUID referanslarını koru.

Kabul: Editor import/derleme hatasız, menü erişilebilir, URP referansları her
kalitede geçerli, Türkçe font metinleri okunur, eksik stinger açılışı bozmaz.
Editor yoksa kaynak hazırlanabilir; bu kabul kutusu açık kalır.

## 3. Aşama 1 — Saf C# Core ve ışın kuralları

Davranış testleri önce tanımlanır; gerçek başarısızlık gözlenir, implementasyon
sonrası aynı testler çalıştırılır. Test komutu, runner ve sonuç sayısı raporlanır.

1. GridPosition: integer 6×12 sınırlar, eşitlik/hash, komşu ve yön adımı.
2. Direction: dört ilerleme yönü, dönüş, karşı yön; dört dokunuş başlangıca döner.
3. LightColor: RGB bitmask, OR karışım, hedefte tam eşleşme.
4. Source/Mirror/Prism/Target/Wall verisi; benzersiz id ve bir hücrede tek nesne.
5. LevelState: başlangıç ve aktif yönler, hamle/süre; içerik asset'ini değiştirmez.
6. RayTracer: integer `(x,y,direction,colorMask)` visited anahtarı, sonlu trace.
7. WinChecker ve canonical HintService; Unity fizik raycast'i kullanılmaz.

Kabul matrisi:

| Davranış | Beklenen sonuç |
|---|---|
| Dört ayna yönü | Tasarım §5.2 tablosu; uygunsuz giriş sonlanır |
| Kaynak/boş hücre | Başka ışına engel olmaz; kesişim karıştırmaz |
| Target | Gelen maskeleri OR toplar, ışını geçirir, fazla renk kazanmaz |
| Wall | Arkaya ışın geçmez |
| Prism | Yalnız RGB beyaz ayrılır; diğer maskeler düz geçer |
| Prism orientation 0 | R kuzey, G doğu, B batı; diğer yönler 90° döner |
| Loop | Aynı ray state tekrarında güvenle sonlanır |
| Kazanma/hint | Tüm hedefler tam eşleşir; hint gösterir, oyuncu adına döndürmez |

Core test başarısı Unity yaşam döngüsü veya Android performansı kanıtı değildir.

## 4. Aşama 2 — ScriptableObject içerik ve 12 bölüm

1. Serializable obje/tutoryal kayıtları içeren bölüm ScriptableObject'i oluştur:
   id, boardSize, objects, canonicalSolution, parMoves, tutorialSteps, visualTheme.
2. Adapter immutable Core tanımına kopyalar; her session kendi mutable state'ini kurar.
3. Editor validation sınırlar, id, maskeler, orientation ve canonical replay'i denetler.
4. Bölüm 1–3 temel yol, 4–6 ayna/duvar, 7–9 renk hedefleri, 10–12 prizma.
5. Bölüm 1 tam bir kaynak, bir ayna ve bir hedef içerir; tek gerçek tap ile çözülür.
6. Paketlenen 12 asset'i EditMode'da yükle, çözümlerini gerçek adapter üzerinden replay et.

Kabul: 12/12 canonical replay kazanır; başlangıçlar çözülmemiştir; en az bir
hamle gerekir. Aynı asset iki session açıldığında yönler birbirine sızmaz.

## 5. Aşama 3 — GameSession, board ve input

1. GameSession kabul edilen komutta modeli, trace'i, kazanmayı ve save snapshot'ını
   üretir; MonoBehaviour view yalnız sonuç gösterir.
2. BoardLayout tek ekran/kamera/grid dönüşümüdür. Canvas safe-area ve HUD alanı
   çıkarıldıktan sonra `min(width/6,height/12)` hücre boyutu kullanılır.
3. EventSystem/GraphicRaycaster UI önceliğini belirler; InputRouter tek board
   pointer'ı kabul eder ve tutorial gating'i uygular.
4. AppFlowController Boot/Menu/Loading/Tutorial/Playing/Paused/Completed/Result/
   Transition/Recovery durumlarını yönetir. Loading/Completed/Transition input'u kapatır.
5. Reset başlangıç state'ine döner. Her bölümün bir ücretsiz canonical hint'i offline
   kullanılabilir. Hamle/süre ve yıldız eşikleri tasarım §5.6 ile aynıdır.
6. Hızlı tap'ler sırayla modele uygulanır; görsel animasyon son yöne retarget eder.
   Next geçişi idempotenttir. Son bölüm kampanya tamamlanmasını sunar; bölüm 13 aranmaz.

Kabul: PlayMode'da doğru hücre, UI tıklamasında board'un değişmemesi, çift Next,
reset/hint, pause ve sonuç akışı doğrulanır. Fiziksel touch testi ayrıca gerekir.

## 6. Aşama 4 — Tutorial, UI ve erişilebilirlik

1. Boot → Başla/Devam Et, Bölüm Seçimi, Ayarlar/Yardım, Game HUD, Pause, Result
   ve offline legal/lisans ekranlarını bağla; Store/Restore/Consent gizli kalır.
2. TutorialController veri adımlarını okur: kaynak/hedef açıklaması, dim/spotlight,
   “Aynayı döndürmek için dokun”, animasyonlu el ve tap ring.
3. El yaklaşık 20 dp üstte, 8 dp hareket ve 1→0.88→1 scale ile üç döngü oynar;
   sonra statik kalır, gerekirse 3 saniye sonra tek hatırlatma yapar.
4. El raycast tüketmez; yalnız beklenen aynanın gerçek InputRouter komutu ilerletir.
   Geri/Duraklat/Atla çalışır. Atla tamamlandı yazar; Yardım'dan tekrar başlatılır.
5. tutorialVersion/step/completed JSON'da saklanır; kapanıp açılınca adım sürer.
6. Reduced Motion statik pointer/metin ve focus ring kullanır; tüm motion token'ları
   global override alır. High Contrast, Reduced Glow, Color Assist korunur.
7. Compact/Standard/Tablet, 360×640, 360×800, 412×915 ve çentik testlerini yap.
   HUD dokunma alanı ≥48 dp, görsel hedef ≥40 dp; Canvas unit = dp varsayılmaz.
8. DynaPuff kısa display metinlerinde, paketlenmiş Noto Sans uzun metinde hedeflenir.
   Noto Sans henüz envanterde yoktur; fallback/Türkçe glyph ve 1.0/1.3 ölçek QA gerekir.

Kabul: Tutorial otomatik hamle yapmaz; layout sonrası el doğru hücreye bağlıdır.
5 yeni oyuncunun en az 4'ü menü CTA'sını 10 saniyede, ilk tap'i 15 saniyede ve
Hint/Reset/Pause'u 5 saniyede bulur. Kullanıcı testi yapılmadan eşikler geçti denmez.

## 7. Aşama 5 — Görsel sunum ve ses

1. Crystal Lab görünümü: board contrast plate, ortak pivot/silüet, gölge, beam core
   ve kontrollü glow. Görsel katman TraceResult dışında oyun sonucu üretmez.
2. Low/Medium/High kalite; Low'da glow ve yoğun parçacık/parallax kapanır.
3. Tasarım §12.8 motion token'ları: 60/120/220/320/600 ms; kutlama toplam ≤1 saniye.
4. Resources audio: menu/gameplay loop; click/rotate/complete SFX; ayrı stinger.
5. AudioSource/AudioMixer Master/Music/SFX/stinger ayrımı, cooldown ve varyasyon
   veya ±%2 pitch; tüm dosyalar offline paketlenir.
6. Settings önce yüklenir; startup stinger logo reveal'de uygulama oturumu başına
   yalnız bir kez, loop olmadan denenir. Mute/Master=0/Music=0 veya eksik clip
   açılışı bekletmez. Guard atlanan denemede de tüketilir.
7. Kalıcı servis scene reload, menü dönüşü ve pause/resume'da tekrar çalmaz.
   Yeni Editor Play oturumu guard'ı sıfırlar; domain reload kapalı durum test edilir.

Kabul: PlayMode duplicate audio ve mute testleri; 10 dakika gerçek cihazda
clipping/üst üste binme kontrolü. Düşük cihaz stabil 30 FPS, orta/üst 60 FPS hedefi
Profiler ile ölçülür; masaüstü gözlemi yeterli değildir.

## 8. Aşama 6 — JSON save, recovery ve Android lifecycle

1. Save adapter `Application.persistentDataPath` altında save_v1.json,
   save_v1.backup.json ve settings_v1.json kullanır; testte geçici dizin enjekte edilir.
2. Versioned DTO: bölüm/açılma durumu, obje id/yönleri, hamle/süre/yıldız,
   tutorial, ses/titreşim/kalite/accessibility; gelecekte catalog kimliği ve signature.
3. Her kabul edilen hamle sonrası sıralı temp-write → flush/close → güvenli
   replace/rename; son geçerli backup korunur. Eski async yazma yenisini ezmez.
4. Bozuk ana dosya → backup; ikisi bozuk → açıklayıcı mesaj ve yeni kayıt.
   Yazma hatası memory state ile devam eder ve bir kez tekrar denenir.
5. Bilinmeyen schema, eksik obje ve geçersiz yön doğrulanır; bilinmeyen yeni
   schema sessizce ezilmez. Eksik kritik bölüm → Retry/Safe Level/Menu.
6. OnApplicationPause/Focus tekilleştirilir; timer/input/audio askıya alınır.
   Resume aktif bölümü PAUSED açar. OnApplicationQuit'e tek başına güvenilmez.
7. Android Back davranışları tasarım §13.4 ile aynıdır; en üst overlay önceliklidir.

Kabul: Disk adapter testleri + PlayMode lifecycle; uçak modunda 12 bölüm,
process kill sonrası son kabul edilmiş hamle ve bozuk save recovery cihazda doğrulanır.

## 9. Aşama 7 — Dikey dilim Android kabulü

1. Unity import/compile ve EditMode/PlayMode sonuç XML/loglarını sakla.
2. Android debug APK üret; merged manifest'te INTERNET/ads/billing yokluğunu,
   build raporunda kaynak/arşiv dosyalarının paketlenmediğini denetle.
3. Düşük/orta/üst fiziksel cihazlarda safe-area, input, offline, ses, suspend/resume,
   save, Türkçe metin, erişilebilirlik ve 12 bölüm tamamlamayı test et.
4. Unity IL2CPP/ARM64, stripping/serializer ve imzalı AAB ayrıca doğrulanır.
5. Font/audio kaynak hakları ve offline lisans dosyaları release öncesi tamamlanır.

Kabul raporu Editor tam sürümü, test kapsamı/sonucu, build komutu/profili,
artifact yolu, cihaz/OS ve kalan sorunları içerir. APK üretimi cihaz QA değildir.
Unity Editor yoksa bu aşama açık kalır; eski Godot APK ve 872 kontrol devralınmaz.

## 10. Dikey dilim sonrası — Solver, generator ve seed kataloğu

1. Saf C# LayoutGenerator topoloji kurar; SolvedBoardBuilder geçerli ışık yolu,
   canonical yönler ve hedef maskelerini üretir.
2. ScrambleService sürümlü deterministik RNG ile yönleri karıştırır; yalnız
   canonical'dan farklı olması yeterli değildir, başlangıç WinChecker ile çözülmemiş olmalıdır.
3. BFS Solver tek nesneye 90° hamlelerle shortest solution bulur. Solution-count
   sinyali 2+ seviyesinde durabilir. Aynı state'e farklı hamle sıraları ayrı
   çözülmüş board sayılmaz; metrik anlamı testle sabitlenir.
4. DifficultyValidator tasarım §6.4–6.5 ağırlık, profil ve alakasız nesne
   sözleşmesini uygular. Eksik metrik sıfırla gizlenip tamamlandı sayılmaz.
5. Seed/hash byte formatı, obje sırası, taşma ve RNG algoritması sürümle sabitlenir;
   System.Random sürüm davranışı veya UnityEngine.Random'a güvenilmez.
6. Editor/development aracı en az 10.000 aday tarar; kabul edilen seed, sürüm,
   levelIndex, signature, profil ve metrikleri katalog asset'ine kaydeder.
7. Runtime yalnız doğrulanmış entry'yi yeniden üretir; solver/BFS ve rastgele retry
   oyuncu cihazında çalışmaz. Signature hatasında doğrulanmış emergency entry kullanılır.
8. Yayınlanan generator sürümü değişmez; kaldırılacaksa frozen bölüm snapshot'ı tutulur.

Kabul: Aynı version/seed aynı signature ve bölümü üretir; bütün katalog
canonical replay'leri ve profil eşikleri geçer. Godot v1 seed/signature uyumluluğu
varsayılmaz; port yeni sürüm kimliği veya kanıtlanmış uyumluluk gerektirir.
Campaign 30–50 bölüme genişleyebilir; endless kabulü campaign'i bekletmez.

## 11. Sonraki opsiyonel servisler ve iOS

Ads/billing/consent adapter'ları ancak ayrı yayın kapsamıyla eklenir. İlk 5 bölüm
interstitial yok, sonra en fazla 3 tamamlamada bir; gameplay banner/app-open yok.
Rewarded yalnız açık talep ve earned-reward callback'iyle bir kez kredi verir.
Consent veya bağlantı hatası oyunu durdurmaz. remove_ads/premium_theme_pack
non-consumable; pending entitlement vermez, restore idempotenttir. SDK sürümleri
entegrasyon tarihinde doğrulanır. Ayrıntılar tasarım §8'de korunmuştur.

iOS için macOS/Xcode ve cihaz QA ayrıca gerekir. Backend, hesap, cloud save,
günlük etkinlik ve tüketilebilir ekonomi bu planın ilk teslimine dahil değildir.

## 12. Kanıt ve mevcut durum

- [x] Unity mimarisi kullanıcı tarafından onaylandı.
- [x] Godot kaynakları LegacyGodot'a taşındı; eski tasarım/plan tarihsel arşive alındı.
- [x] Resources altında dört DynaPuff TTF ve altı runtime/stinger MP3 gözlendi.
- [x] Aktif Unity tasarımı, planı ve kök dokümantasyon uyarlandı.
- [ ] Unity Editor kurulumu/pin ile import ve derleme doğrulaması.
- [ ] Saf C# test sonuçlarının Core sorumlusundan raporlanması.
- [ ] Unity EditMode/PlayMode sonuçları.
- [ ] Android APK/AAB ve fiziksel cihaz kabul raporu.
- [ ] Noto Sans/fallback, lisans/hak manifesti ve kullanıcı testleri.
- [ ] Sonraki solver/generator/katalog ve opsiyonel servis kabulü.

Eşzamanlı geliştirme sırasında kaynakların varlığı test başarısı değildir.
Ana uygulama sonuçları geldikçe yalnız kanıtlanan kalemler kapatılır.
