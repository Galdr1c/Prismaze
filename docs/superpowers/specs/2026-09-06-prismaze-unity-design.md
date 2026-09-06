# Prismaze — Unity Tasarım Belgesi

**Tarih:** 2026-09-06  
**Durum:** Unity geçişi onaylandı; uygulama geliştirme aşamasında. Unity Editor import, EditMode/PlayMode ve Android build/cihaz doğrulaması henüz raporlanmadı.  
**Kapsam:** Android öncelikli, offline çalışan, 2D optik bulmaca oyunu

## 1. Belgenin amacı

Bu belge onaylanan Unity + C# + URP 2D mimarisinin aktif tasarım sözleşmesidir.
[Unity uygulama planı](../plans/2026-09-06-prismaze-unity-implementation-plan.md)
teslim ve doğrulama sırasını tanımlar. Önceki tasarımın oynanış, içerik, tutorial,
ses, erişilebilirlik ve offline gereksinimleri korunmuştur; motor entegrasyonu
Unity bileşenlerine göre yeniden tanımlanmıştır.

[Godot tasarımı](../../archive/godot/2026-09-04-prismaze-godot-design.md) ve
[eski plan](../../archive/godot/2026-09-04-prismaze-implementation-plan.md)
yalnız tarihsel kayıttır. Kaynakları `LegacyGodot/` altındadır. Oradaki test
sayıları, APK ve tamamlanma işaretleri Unity uygulamasının doğrulaması değildir.
Kökteki PLAYER_PSYCHOLOGY_GUIDE.md de eski referanstır; içindeki “implemented”
ifadeleri Unity durumu veya yeni ekonomi kapsamı sayılmaz.

## 2. Ürün tanımı

Prismaze, dikey mobil ekran için tasarlanmış, tek oyunculu ve offline çalışan bir
optik bulmaca oyunudur. Oyuncu sabit bir ızgara üzerindeki aynaları ve
prizmaları döndürerek ışığı doğru hedeflere ulaştırır.

Temel oynanış, bölüm içeriği ve kayıt sistemi internet bağlantısı olmadan
çalışır. İleride etkinleştirilecek reklam, satın alma ve restore işlemleri
bağlantı olduğunda çalışan isteğe bağlı bir Android katmanıdır; bağlantı
olmaması hiçbir zaman bölüm oynamayı veya temel ilerlemeyi engellemez.

Oyunun mantıksal zemini 6×12 hücrelik portre ızgaradır. Görsel sunum 2D kalır;
katmanlı çizimler, gölgeler, parallax, ışık parlaması, shader ve parçacık
efektleriyle 2.5D hissi oluşturulur. Gerçek 3D dünya ve fizik sistemi ilk
sürümün parçası değildir.

### 2.1. Temel oyun döngüsü

~~~
Bölüm yüklenir
    ↓
Oyuncu bir aynaya veya prizmaya dokunur
    ↓
Obje 90° döner
    ↓
RayTracer bütün ışınları yeniden hesaplar
    ↓
Işınlar ve hedef dolulukları görsel olarak güncellenir
    ↓
Bütün hedefler doğru renkliyse bölüm tamamlanır
~~~

### 2.2. İlk dikey dilim kapsamı

İlk dikey dilimde şunlar bulunur:

- Kaynak, ayna, prizma, hedef ve duvar nesneleri
- Dokunarak 90° döndürme
- Işın yansıması ve renk karışımı
- Bölüm sıfırlama
- İpucu ile sıradaki ilgili objeyi gösterme
- Bölüm ortasında yerel kayıt ve devam etme
- Sıralı bölüm ilerlemesi
- İlk girişte birinci bölüm için animasyonlu el ve açıklama kartlı onboarding
- Android cihaz desteği
- Düşük, orta ve yüksek görsel kalite seçenekleri

İlk dikey dilimde şunlar bulunmaz:

- Karakter hareketi
- Obje yerleştirme veya sürükleme
- Portal
- Zamanlı kaynak
- Hareketli engel
- Online hesap veya liderlik tablosu
- Reklam, mağaza veya uygulama içi satın alma
- Günlük/sezonluk etkinlik
- Bulut kayıt
- Gerçek 3D ortam

İlk 12 bölümlük dikey dilim monetization kapalı olarak geliştirilecektir.
Yayınlanabilir sürümde monetization etkinleştirilirse yalnızca Bölüm 8’deki
offline oynanış sözleşmesine uyan reklam ve ürünler eklenebilir.

## 3. Teknoloji kararı

### 3.1. Ana teknoloji

- Motor: Unity 6.3 LTS; doğrulanmış başlangıç adayı `6000.3.17f1`.
  Kesin pin ana uygulama tarafından `ProjectSettings/ProjectVersion.txt` içine
  yazılır; daha yeni sürüm yalnız resmi doğrulamayla seçilir. Bu belge indirme yapmaz.
  [Resmi sürüm kaydı](https://unity.com/releases/editor/whats-new/6000.3.17f1)
- Dil: C#. Core, UnityEngine bağımlılığı olmayan saf C# model ve algoritmalardır.
- Grafik: URP 2D Renderer, orthographic Camera, SpriteRenderer/mesh tabanlı
  board ve beam, sıralama katmanları, shader ve kontrollü ParticleSystem.
- UI: Canvas, RectTransform, CanvasScaler ve EventSystem ile mobil HUD/overlay.
- İçerik: El yapımı bölümler ScriptableObject asset; çalışma durumu ayrı C# nesneleri.
- Kayıt: Sürümlü yerel JSON; dosya yolu platform adapter'ından alınır.
- Android önce; olası iOS aynı Core ile daha sonra macOS/Xcode üzerinde doğrulanır.
- Git; debug APK cihaz testi, imzalı AAB mağaza teslimi.

### 3.2. Bileşen ve veri yaklaşımı

MonoBehaviour bileşenleri GameObject yaşam döngüsü, input, ses ve sunumu bağlar.
Core'da MonoBehaviour, Transform, fizik raycast'i, frame zamanı veya Unity RNG
kullanılmaz. Optik ışın çözümü integer grid üzerinde RayTracer tarafından üretilir.
ScriptableObject içeriği oyuncu kaydı değildir; runtime değişiklikleri asset'e yazılmaz.
[Unity ScriptableObject belgesi](https://docs.unity3d.com/6000.3/Documentation/Manual/class-ScriptableObject.html)

### 3.3. Renderer ve cihaz hedefi

URP Asset'in varsayılan renderer'ı 2D Renderer olur ve Graphics ile her etkin
Quality seviyesinde aynı sözleşme korunur. Kamera orthographic'tir; gölge/glow
sunumdur. Post-processing ve parçacıklar Low kalitede kapatılabilir.
[Unity 2D Renderer](https://docs.unity3d.com/6000.3/Documentation/Manual/urp/2DRendererData-overview.html)

Android minimum sürümü ve grafik API listesi seçilen Editor'ün resmi desteği ile
fiziksel cihaz matrisi doğrulanarak ProjectSettings'te sabitlenir. Eski Godot
Android 7 tabanı devralınmaz. Google Play hedef API ve SDK şartları yayın gününde
resmi kaynaktan tekrar kontrol edilir; geçmiş tarihli şartlar kabul kanıtı değildir.

## 4. Mimari

Oyun mantığı, sahne/görsel kodu ve platform kayıtları birbirinden ayrılır.
Hiçbir görsel nesne oyunun sonucunu kendi başına belirlemez.

### 4.1. Önerilen proje yapısı

Aşağıdaki yapı sorumlulukları tarif eder; dosyaların oluşturulmuş olduğunu iddia etmez.
Gerçek sınıf/dizin adlarını ana uygulama belirler.

~~~
Assets/
├── Scripts/
│   ├── Core/          # Saf C#: model, trace, hint, determinism
│   ├── Levels/        # ScriptableObject → immutable Core tanımı adapter'ı
│   ├── Game/          # Session bağlantısı, input, AppFlowController
│   ├── UI/            # Canvas HUD, tutorial, menüler
│   ├── Visual/        # Sprite/mesh, shader, motion
│   └── Platform/      # JSON save, ses, haptic; gelecekte servis adapter'ları
├── Editor/            # Asset üretimi/doğrulama ve build araçları
├── Scenes/            # Boot/menu/game veya eşdeğer bootstrap kompozisyonu
├── Resources/
│   ├── Levels/        # 12 el yapımı ScriptableObject .asset
│   ├── Fonts/         # DynaPuff TTF ve gerekli paketlenmiş fallback
│   └── Audio/
│       ├── runtime/   # menu, gameplay, click, rotate, complete
│       └── stingers/  # starting_sound.mp3
└── Tests/
    ├── EditMode/
    └── PlayMode/
Packages/              # Ana uygulamanın sabitlediği bağımlılıklar
ProjectSettings/       # Editor pin, URP, portre, platform ayarları
LegacyGodot/           # Arşiv; Unity Assets dışında
docs/
~~~

Core için ayrı assembly definition Unity referanslarını dışlar. Runtime
assembly Core'a bağımlıdır; Editor ve test assembly'leri player'a dahil edilmez.
Boot kompozisyonu bağımlılıkları açıkça kurar. C# event abonelikleri simetrik
kapatılır; sahne dönüşü aynı komutu iki kez çalıştırmaz. Tek oturum servisleri
`DontDestroyOnLoad` ile korunabilir; duplicate instance guard zorunludur.

### 4.2. Sorumluluklar

**Core:** `GridPosition`, `Direction`, `LightColor`, nesne durumları,
`LevelState`, `RayTracer`, `WinChecker`, canonical çözümü hesaplayan
`HintService`, deterministik hash ve RNG. Bu katman
UnityEngine'e veya Android API’lerine bağlı olmayacaktır.

**Levels:** Bölüm tanımları, el yapımı ScriptableObject asset'leri, canonical çözüm
adımları, Solver, DifficultyValidator, SeedCatalog ve deterministik jeneratör.

**Game:** `GameSession` mevcut bölümün tek otoritesidir. `InputRouter` dokunmayı
ızgara konumuna çevirip döndürme komutu gönderir. `HintController` ücretsiz
ipucu/kredi durumunu yönetir; `LevelBoard` ve nesne view’ları durumu gösterir.

**Hint sınırı:** `HintService` yalnızca canonical çözüm adımını hesaplar.
İpucu kotası ve `hint_credit` tüketimi Game/UI katmanındaki `HintController`
tarafından yapılır; bu servis reklam sağlayıcısını bilmez.

**Tutorial sınırı:** `TutorialController`, `tutorial_steps[]` verisini okuyup
overlay, açıklama ve el işaretini yönetir. Objeyi doğrudan döndürmez;
oyuncunun normal InputRouter komutunu bekler ve yalnız beklenen state değişimi
gerçekleşince sonraki adıma geçer.

**Visual:** Grid, ışın, glow, gölge, parallax, parçacık ve bölüm tamamlama
efektleri. Bu katman `TraceResult` verisini kullanır; oyun kuralı üretmez.

**Platform:** Yerel kayıt, ayarlar, ses ve titreşim adaptörleri. Android’e
özel çağrılar bu sınırın içinde kalır; iOS eklendiğinde aynı arayüzlerin iOS
uygulaması yazılır.

**Monetization:** `MonetizationController`, `AdPolicy`, `RewardService`,
`EntitlementService`, `PurchaseService`, `ConsentService` ve ürün kataloğu.
Bu katman yalnızca UI/Game tarafından çağrılır; `Core`, `RayTracer` ve
`GameSession` reklam veya mağaza bilgisini bilmez.

### 4.3. Yetkili durum akışı

~~~
LevelDefinition + kayıtlı yönler
              ↓
          LevelState
              ↓
        GameSession komutu
              ↓
       RayTracer / WinChecker
              ↓
         TraceResult
       ↙       ↘          ↘
 Görsel katman  SaveService MonetizationController
~~~

Görsel ayna döndürülmüş gibi görünmeden önce model güncellenir. Model işlem
başarılıysa view animasyonu oynatılır. Böylece görsel ile mantığın birbirinden
kopması engellenir.

## 5. Oyun modeli ve kurallar

### 5.1. Mantıksal nesneler

| Nesne | Durum | Oyuncu etkileşimi |
|---|---|---|
| Source | Konum, yön, ışık rengi | Sabit |
| Mirror | Konum, 4 yön durumu | Dokununca 90° döner |
| Prism | Konum, 4 yön durumu | Dokununca 90° döner |
| Target | Konum, istenen renk maskesi | Sabit |
| Wall | Konum | Işını durdurur |

Mantıksal modelde her hücrede en fazla bir nesne bulunur. Konumlar tam sayı
ızgara koordinatlarıdır; görsel pixel koordinatları yalnızca renderer’da
hesaplanır.

### 5.2. Ayna yönleri

Yön değerleri sabit tutulur:

~~~
0 = |
1 = /
2 = —
3 = \
~~~

Yansıma tablosu:

- `|`: Doğu↔Batı yansır; Kuzey/Güney girişi durur.
- `/`: Kuzey↔Doğu ve Güney↔Batı yansır.
- `—`: Kuzey↔Güney yansır; Doğu/Batı girişi durur.
- `\`: Kuzey↔Batı ve Güney↔Doğu yansır.

Bu tablo hem core testleri hem de görsel yön haritası için tek kaynaktır.
`Direction`, ışının aynaya giriş yaptığı tarafı değil, ışının ilerlediği yönü
temsil eder. Bir ray state’i `position`, `direction` ve `color_mask` üçlüsünden
oluşur. `position`, ışının bulunduğu hücredir; tracer her adımda
`position + direction` hücresini kontrol eder.

RayTracer’ın `visited` anahtarı en az `(x, y, direction, color_mask)` içerir.
Aynı durum ikinci kez görülürse ışın durur ve bu bir oyuncu hatası değil,
normal döngü sonlandırması olarak kabul edilir.

### 5.3. Ray etkileşimi

- Boş hücrelerde kesişen ışınlar birbirleriyle karışmaz ve yön değiştirmez.
- Renk maskeleri yalnızca hedefin aldığı ışınlar birleştirilirken OR işlemiyle
  toplanır.
- Target bir sensördür: aldığı rengi kaydeder ve ışının aynı yönde devam
  etmesine izin verir.
- Source kendi ışınını üretir; başka bir ışın Source hücresine girerse hücre
  ışını durdurmaz.
- Wall ışını durdurur ve arkasındaki hücrelere ışık ulaşmaz.
- Ayna uygun giriş yönünde yeni bir ray state’i üretir; uygun olmayan giriş
  ışını aynada sonlandırır.
- Ray state’leri statik bölüm boyunca bağımsız hesaplanır; varış zamanı
  oynanış sonucunu değiştirmez.

### 5.4. Renkler

RGB additive mixing bitmask ile tutulur:

~~~
Kırmızı + Yeşil          = Sarı
Kırmızı + Mavi           = Mor
Yeşil + Mavi             = Camgöbeği
Kırmızı + Yeşil + Mavi   = Beyaz
~~~

Hedefin birleşik maskesi istediği maskeyle tam eşleşmelidir. İstenen mor hedefe
R+B gelirse tamamlanır; R+G+B gelirse beyaza dönüştüğü için tamamlanmaz.

### 5.5. Prizma

Beyaz ışık prizmaya çarptığında üç renkli ışın oluşur. Prizma yönü, çıkışların
temel yönlerini 90° döndürür.

Temel yön durumu:

~~~
Kırmızı = Kuzey
Yeşil   = Doğu
Mavi    = Batı
~~~

Kural kesin olarak şöyledir:

- `color_mask == white (RGB)`: Işın kırmızı, yeşil ve mavi olarak ayrılır.
- Bunun dışındaki tüm maskeler: Işın rengi değişmeden düz geçer.

Bu nedenle sarı, mor ve camgöbeği ışınlar “renkli ışın” sayılır ve prizma
tarafından tekrar ayrıştırılmaz. Prizma yalnızca tek bir sabit davranışa sahip
olacak; özel prizma türleri ileriki sürümlere bırakılacaktır.

### 5.6. Kazanma, ipucu ve skor

- Tüm hedefler tam istenen maskeye ulaştığında bölüm kazanılır.
- Kaybetme veya can sistemi yoktur.
- Reset mevcut bölümün başlangıç durumunu geri yükler.
- Hint, bölümün `canonical_solution` listesindeki sıradaki uygun olmayan
  objeyi vurgular ve doğru yönünü kısa süre gösterir; otomatik döndürmez.
  Bir bölümde birden fazla çözüm varsa Hint her zaman canonical solution’a
  yönlendirir; alternatif çözüm aramaz.
- Her bölümde bir adet canonical hint bağlantı olmadan ve ücretsiz kullanılabilir.
- Monetized release’te oyuncu isterse rewarded reklam karşılığında bir adet
  ek `hint_credit` kazanabilir. Bu kredi yalnızca yerel HintController
  tarafından tüketilir; `HintService` reklam sağlayıcısını bilmez.
- İlk dikey dilimde hamle ve süre kaydedilir.
- Skor sistemi kullanıldığında eşikler şöyledir:
  - 3 yıldız: `moves <= par_moves`
  - 2 yıldız: `moves <= par_moves + 3`
  - 1 yıldız: Bölüm tamamlandı

## 6. Bölüm verisi ve içerik üretimi

### 6.1. Bölüm tanımı

`LevelDefinition` içeriği Unity ScriptableObject asset olarak saklanır; yükleme adapter'ı bunu saf C# bölüm tanımına dönüştürür. Her bölüm şunları
içerir:

~~~
id
board_size            (ilk sürümde 6×12)
objects[]
canonical_solution[]
par_moves
tutorial_steps[]
visual_theme
~~~

`objects[]` içindeki her kayıt nesne tipini, ızgara konumunu, sabit yönü,
başlangıç yönünü, rengi veya hedef maskesini taşır. `canonical_solution[]`,
doğrulama amacıyla döndürülmesi gereken nesne ve son yön bilgisini taşır.
`tutorial_steps[]` her adım için hedef obje id’si, localization key, pointer
tipi ve tamamlanma koşulunu taşır; tutorial kodu level geometrisine gömülmez.

Bölüm asset'leri `Assets/Resources/Levels/` altında tutulur ve Inspector'da
serializable alanlarla düzenlenir. Editor validator benzersiz id, sınırlar,
maskeler, canonical çözüm ve başlangıcın çözülmemiş olmasını kontrol eder.
Runtime state, paylaşılan ScriptableObject'i değiştirmez; yönler, hamle sayısı ve süre ayrı
`LevelState` içinde tutulur.

### 6.2. İlk içerik planı

İlk oynanabilir dilim 12 el yapımı bölümden oluşur:

~~~
1–3    Kaynak → ayna → hedef
4–6    Birden fazla ayna ve duvar
7–9    Birden fazla hedef ve renk karışımı
10–12  Prizma ve renk ayrıştırma
~~~

Her yeni mekanik önce kısa bir öğretici bölümle gösterilir. Zorluk; rastgele
nesne sayısıyla değil, ışın yolunun uzunluğu, karar sayısı ve renk
bağımlılığıyla artırılır.

İlk public release hedefi 30–50 el yapımı campaign bölümüdür. Endless mod
yalnızca doğrulanmış seed kataloğu ve QA kabul kriterleri tamamlandıktan sonra
etkinleştirilir; dikey dilim bu modun varlığına bağlı değildir.

### 6.3. Prosedürel üretim sözleşmesi

Runtime’da rastgele hücrelere nesne koyup tekrar tekrar “çözülüyor mu?” diye
denenmeyecektir. Generator önce çözülebilir bir düzen kurar, sonra bu düzeni
oyuncu için karıştırır ve bağımsız solver/validator ile kabul eder.

~~~
generator_version + level_index
              ↓
          deterministic seed
              ↓
       difficulty profile
              ↓
          template seçimi
              ↓
       çözülebilir board kur
              ↓
       ışık yolunu oluştur
              ↓
    mirror/prism/target yerleştir
              ↓
       başlangıç yönlerini scramble et
              ↓
          solver ile doğrula
              ↓
       difficulty ölç ve filtrele
              ↓
           kabul / reddet
~~~

Her generated bölüm aynı `LevelDefinition` formatına dönüştürülür. Jeneratör
sürümü, seed’i ve bölüm imzası birlikte saklanır; böylece aynı bölüm daha
sonra yeniden üretilebilir.

### 6.4. Generator aşamaları

**LayoutGenerator:** Yalnızca topoloji, duvarlar, boş koridorlar ve uygun
hücreleri belirler. Rastgele her hücreye nesne yerleştirme yapmaz. Difficulty
profile, kaynak/hedef/ayna/prizma sayısı ve izin verilen yol karmaşıklığını
sınırlar.

**SolvedBoardBuilder:** Önce kaynaklardan hedeflere giden geçerli ışık yolunu
kurar. Gerekli aynaların/prizmaların çözüm yönlerini bu aşamada bilir ve
`canonical_solution` listesini üretir. Hedef renkleri de kurulan yolun
ürettiği maskelere göre belirlenir.

**ScrambleService:** Çözülmüş yönleri deterministik RNG ile başlangıç
yönlerine çevirir. Bölümün başlangıç hali çözülmüş halde bırakılamaz; en az
bir rotatable obje canonical yönünden farklı olmalıdır.

**Solver:** Başlangıç state’inden BFS ile olası yön kombinasyonlarını dener.
Bir hamle, tek bir rotatable objeyi 90° döndürmektir. Her state RayTracer ve
WinChecker ile değerlendirilir. Solver en kısa çözümü, çözüm sayısı sinyalini
ve kalite metrikleri için gerekli yolu döndürür.

6×12 grid küçük olduğu için solver editor/build aşamasında brute-force veya
BFS kullanabilir. 6 rotatable obje için 4^6 = 4.096, 8 obje için 4^8 =
65.536, 10 obje için 4^10 = 1.048.576 orientation kombinasyonu üst sınır
olarak kabul edilir. Runtime oyuncu cihazında bu arama yapılmaz.

**DifficultyValidator:** Çözümü olan her bölüm otomatik olarak iyi bölüm
sayılmaz. Validator aşağıdaki sonuçları üretir:

~~~
solvable: true/false
shortest_solution: int
solution_count: 1 veya 2+ (erken durdurmalı sayım)
active_objects: int
irrelevant_objects: int
beam_length: int
branch_count: int
cycle_found: true/false
difficulty_score: 0..100
~~~

Metrik tanımları:
- `active_objects`: En az bir shortest solution içinde yönü değişen rotatable
  nesne sayısı.
- `irrelevant_objects`: Hiçbir shortest solution içinde yönü değişmeyen
  rotatable nesne sayısı.
- `branch_count`: Shortest çözüm ağacında çözüme götüren farklı karar
  dallarının sayısı.
- `decision_points`: Bir state’ten çözüme giden birden fazla anlamlı sonraki
  hamle bulunan karar noktalarının sayısı.
- `color_dependencies`: Hedef maskesini oluşturmak için birden fazla renk
  kaynağının birlikte gerekli olduğu bağımlılık sayısı.
- `misleading_rotations`: Oyunu hemen kaybettirmeden çözüm uzayını daraltan
  veya oyuncuyu yanlış yola sokan rotasyon sayısı.
- `beam_length`: Tam çözüm trace’inin toplam ışın segmenti uzunluğu.

İlk difficulty score, profile göre normalize edilmiş metriklerle şu ağırlıklı
formülle hesaplanır ve generator version içinde sabit tutulur:

~~~
base = 0.30 shortest_solution
     + 0.20 decision_points
     + 0.20 color_dependencies
     + 0.10 beam_intersections
     + 0.10 prism_dependencies
     + 0.10 misleading_rotations
score = clamp(round(100 * base) - 8 * irrelevant_objects, 0, 100)
~~~

`solution_count` değeri 2’ye ulaştığında sayım durur; böylece çok büyük
arama alanlarında tam çözüm sayımı yapılmaz. Birden fazla çözüm tek başına
reddetme sebebi değildir; ancak kısa çözüm, düşük branch count ve düşük
difficulty_score ile birleşirse bölüm reddedilir.

### 6.5. Difficulty profilleri

Zorluk yalnızca nesne sayısından hesaplanmaz. Başlangıç profilleri şöyledir:

| Profil | İçerik sınırları | Hedef çözüm davranışı |
|---|---|---|
| Tutorial | 1 kaynak, 1 hedef, 1–2 ayna, prizma yok | 1–3 hamle, düşük dallanma |
| Easy | 1 kaynak, 1 hedef, 2–4 ayna, sınırlı duvar | 2–5 hamle, en fazla 1 alakasız obje |
| Medium | 1–2 hedef, 3–7 ayna, duvar ve renk bağımlılığı | 5–9 hamle, en fazla 2 alakasız obje |
| Hard | 1–3 hedef, 5–10 rotatable, prizma ve çoklu renk | 8–14 hamle, cycle yok |

Başlangıç difficulty score şu bileşenlerden türetilir:

~~~
shortest_solution
decision_points
color_dependencies
beam_intersections
prism_dependencies
misleading_rotations
irrelevant_objects cezası
~~~

Her generator version kendi profil eşiklerini sabitler. Eşikler değişirse
generator version da değişir; aynı version içinde profil ağırlıkları
değiştirilmez.

### 6.6. Doğrulanmış seed kataloğu

İlk endless dağıtımında runtime’ın kötü bölümleri onlarca kez denememesi için
generator bir development tool olarak çalıştırılır:

1. Her profil için yüksek sayıda aday seed üretilir.
2. Her aday solved-state → scramble → solver → difficulty pipeline’ından
   geçirilir.
3. Kabul edilen adayların seed’i, bölüm imzası ve metrikleri kaydedilir.
4. Seçilen kayıtlar `Assets/Resources/Catalogs/endless_seed_catalog_v1.asset`
   içine yazılır.
5. Runtime yalnızca katalogdaki doğrulanmış seed’i kullanır; rastgele retry
   yapmaz.

Katalogdaki her kayıt en az `generator_version`, `level_index`, `seed`,
`signature`, `difficulty_profile` ve `difficulty_score` taşır. Runtime’da
signature uyuşmazlığı olursa aynı katalogdan önceden doğrulanmış emergency
entry kullanılır; yeni rastgele bölüm üretilmez.

### 6.7. Generator sürümleme

Yayınlanmış generator algoritması aynı version altında değiştirilemez.
Kod tarafında versioned factory kullanılır:

~~~
GeneratorFactory.cs
GeneratorV1.cs
GeneratorV2.cs (gelecek)
~~~

Catalog-backed bir generator version’ın kodu, o version kullanan bölümler
oyunda kaldığı sürece build içinde tutulur. Eski generator kaldırılacaksa
önce ilgili bölümlerin frozen `LevelDefinition` snapshot’ı alınır; böylece
oyuncunun kayıtlı bölümü değişmez.

## 7. Görsel sistem

### 7.1. Sahne katmanları

~~~
GameScene
├── BackgroundLayer
├── ParallaxLayer
├── BoardRoot
│   ├── GridLayer
│   ├── ShadowLayer
│   ├── ObjectLayer
│   ├── BeamLayer
│   └── EffectsLayer
├── TouchLayer
└── HUDLayer
~~~

HUD, oyun dünyasından ayrı Screen Space Canvas üzerinde çalışır. Board
orthographic Camera ile çizilir; Sorting Layer/order değerleri görsel sırayı
belirler. CanvasScaler ve Screen.safeArea adaptasyonu HUD köküne uygulanır.
UI hit testi EventSystem/GraphicRaycaster ile önce çözülür; ardından
BoardLayout kamera ve ekran koordinatlarını tek dönüşümle grid'e çevirir. Grid’in mantıksal
ölçüsü ile ekran pixel ölçüsü arasında tek bir `BoardLayout` dönüştürücüsü
bulunur; dokunma ve çizim aynı dönüşümü kullanır.

### 7.2. 2.5D hissi

- Nesnelerin altında yönlü yumuşak gölge
- Grid hücrelerinde hafif yükselti ve iç kenar
- Katmanlı kristal/ayna çizimleri
- Işında parlak merkez çizgisi ve kontrollü dış glow
- Prizma içinde hareket eden renkli parçacıklar
- Hedeflerde enerji dolma ve tamamlanma işareti
- Yansıma noktalarında kısa parıltı
- Arka planda yavaş parallax
- Bölüm kazanımında kısa kamera ve ışık tepkisi

Efektler `TraceResult` sonrası görsel tepki olarak çalışır. Hiçbir efekt
ışının gerçek yönünü veya hedef sonucunu değiştiremez.

### 7.3. Kalite seviyeleri

~~~
Low:    Temel çizimler, glow kapalı, minimum parçacık
Medium: Hafif glow, gölge ve sınırlı parçacık
High:   Tam glow, parallax, parçacık ve yansıma efektleri
~~~

Oyuncu efektleri kapattığında bölümün mekanik okunabilirliği korunmalıdır.
Yüksek kontrast ve azaltılmış glow seçenekleri görsel sistemin başından
itibaren desteklenir.

## 8. Offline oynanış ve isteğe bağlı online servisler

Temel oyun ve kayıt sistemi cihazda çalışır. Monetization etkinleştirilmiş bir
Android dağıtımında reklam, satın alma, restore ve consent işlemleri çevrimiçi
olabilir; fakat bu servisler bölüm yükleme, bölüm oynama, kayıt veya temel
ilerleme için zorunlu değildir. Kullanıcı normal şekilde açar ve oynar;
bağlantı yalnızca istediği online servis gerektiğinde kullanılır.

### 8.1. Yerel kayıt

SaveService dosya kökünü Unity adapter'ından `Application.persistentDataPath`
olarak alır; Core ve serializer testleri geçici bir dizin enjekte edebilir.
StreamingAssets ve Resources yazılabilir save dizini olarak kullanılmaz.
[Unity persistentDataPath API](https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Application-persistentDataPath.html)

Kayıt kapsamı:

- Son oynanan bölüm
- Açılmış bölümler
- En iyi hamle ve süre
- Yıldız sonucu
- Yarım kalan bölümün yönleri
- Tutorial tamamlanma durumu ve aktif tutorial adımı
- Ses, titreşim ve grafik ayarları
- Bilinen satın alma entitlement’larının yerel önbelleği

Generated level için board’un tamamı kayıt edilmez. El yapımı bölümde level id;
endless bölümde generator version, level index, catalog key, level signature
ve mevcut orientation listesi saklanır. Bölüm yeniden açılırken aynı katalog
entry’si ve generator tekrar çalıştırılır, ardından kayıtlı yönler uygulanır.
Bu nedenle kayıt dosyası generator değişikliğinden etkilenirse signature
kontrolü bölümü güvenli şekilde reddeder ve emergency entry’ye geçer.

Dosya yapısı:

~~~
Application.persistentDataPath/save_v1.json
Application.persistentDataPath/save_v1.backup.json
Application.persistentDataPath/settings_v1.json
~~~

JSON DTO'ları schema version, doğrulanan level id ve obje id/yön çiftleri taşır;
Unity nesne referansları serialize edilmez. Ayarlar da sürümlü JSON'dur.
Yazma aynı dizindeki geçici dosyaya yapılır, flush/close sonrası son geçerli
ana kayıt backup olarak korunup platformun desteklediği atomik replace/rename
uygulanır. Destek farkları Android/iOS üzerinde test edilir; yarım yazılmış ana
kayıt yayınlanmaz. Yazmalar sıralanır; eski async snapshot yenisini ezemez.
Bilinmeyen schema sürümü sessizce mevcut dosyanın üzerine yazılmaz. Okuma bozulursa backup denenir; ikisi de okunamazsa yalnızca
ilerleme sıfırlanır, uygulama açılmaya devam eder.

### 8.2. Monetization sınırı ve mimarisi

Monetization UI/Game tarafından kullanılan ayrı bir katmandır. `GameSession`,
`RayTracer`, `WinChecker` ve core `HintService` AdMob, Google Play veya
ödeme sağlayıcısı bilmez.

~~~
UI / Game
    ↓
MonetizationController
    ├── AdPolicy
    ├── RewardService
    ├── EntitlementService
    ├── PurchaseService
    ├── ConsentService
    └── ProductCatalog
    ↓
Platform adapters
    ├── AndroidAdAdapter
    ├── GooglePlayBillingAdapter
    └── AppleStoreKitAdapter (gelecek)
~~~

İlk 12 bölümlük dikey dilimde bu katman kapalıdır. Monetized build’de
`MonetizationController` hazır değilse veya herhangi bir servis hata verirse
oyun reklam göstermeden ve satın alma sunmadan çalışmaya devam eder.

### 8.3. Servislerin açılış davranışı

~~~
Boot
 ↓
Yerel kayıtları yükle
 ↓
Core ve Main Menu erişilebilir hale gelir
 ↓
Consent durumunu asenkron kontrol et
 ↓
Billing bağlantısı ve entitlement sorgusu yap
 ↓
Consent izin veriyorsa reklamları yükle
~~~

Bu adımlardan hiçbiri oyuncunun ana menüye veya mevcut bölüme girmesini
bekletmez. Bağlantı yoksa reklam istekleri atlanır; bölüm oynama, kayıt ve
offline ilerleme devam eder.

### 8.4. Reklam politikası

- Gameplay ekranında banner reklam kullanılmaz.
- Interstitial yalnızca bölüm tamamlandıktan sonra, sonuç ekranı ile sonraki
  bölüm arasındaki doğal geçişte değerlendirilebilir.
- İlk 5 bölümde interstitial gösterilmez.
- 5. bölümden sonra varsayılan sıklık en fazla her 3 tamamlamada birdir.
- Reklam hazır değilse, bağlantı yoksa, consent yoksa veya `remove_ads`
  entitlement’ı varsa sonraki bölüme hemen geçilir.
- Puzzle oynanırken, hamle sonrasında veya başarısız bir çözüm sırasında
  interstitial açılmaz.
- App-open reklam kullanılmaz.
- `No Ads` interstitial, banner ve app-open reklamlarını kapatır.
- Rewarded reklam yalnızca oyuncunun açıkça istediği ek ipucu için açılır.

Google, interstitial reklamları oyun bölümleri arasındaki doğal geçişlerde
göstermeyi; rewarded reklamda ödülü kullanıcı ödülü kazandığı callback’te
vermeyi belirtir. [Google interstitial belgeleri](https://developers.google.com/admob/android/interstitial)
 ve [Google rewarded belgeleri](https://developers.google.com/admob/android/rewarded)

Rewarded akışı:

~~~
Oyuncu ek ipucu ister
        ↓
Rewarded reklam hazır ve consent uygun mu?
        ↓
Reklam gösterilir
        ↓
onUserEarnedReward
        ↓
RewardService bir kez hint credit verir
~~~

`ad_closed`, `ad_dismissed` veya `ad_failed_to_show` tek başına ödül verme
sebebi değildir. Aynı reklam oturumunun callback’i ikinci kez gelirse ödül
tekrar yazılmaz.

### 8.5. Consent ve gizlilik

Android reklamları için `ConsentService`, Google UMP akışını Android adapter
üzerinden yönetecektir:

- Consent bilgisi her uygulama açılışında güncellenir.
- Gerekli form varsa gösterilir.
- Reklam isteğinden önce `canRequestAds()` kontrol edilir.
- Gizlilik seçenekleri gerekiyorsa ayarlar ekranında erişilebilir bir giriş
  bulunur.
- Consent süreci hata verirse reklamlar kapalı kalır; oyun açılmaya devam eder.
- UMP ve reklam SDK’sı dikey dilim build’ine eklenmez.

Google UMP, consent bilgisinin her açılışta güncellenmesini ve reklam istemeden
önce `canRequestAds()` kontrolünü önerir. [Google UMP belgeleri](https://developers.google.com/admob/android/next-gen/privacy)

### 8.6. Ürün kataloğu ve entitlement

İlk monetized release için katalog bilinçli olarak küçük tutulur:

| Ürün | Tür | Davranış |
|---|---|---|
| `remove_ads` | Non-consumable | Zorunlu reklamları kaldırır |
| `premium_theme_pack` | Non-consumable | Kalıcı görsel tema açar |
| Starter Pack | Sonraki sürüm | İlk monetized release’e dahil değildir |
| Hint/coin paketleri | İlk sürümde yok | Tüketilebilir ekonomi kurulmaz |

`EntitlementService` şu kayıtları yönetir:

~~~
remove_ads
premium_theme_pack
~~~

Yerel kayıt entitlement bilgisinin cache’ini tutabilir; satın alma gerçeğinin
kaynağı Google Play sorgusudur. Uygulama yeniden kurulup ilk kez offline
offline açılırsa satın alma restore edilemeyebilir, ancak bu durum oyunun oynanmasını
engellemez. Bağlantı geldiğinde owned purchases sorgulanır ve cache yenilenir.

`remove_ads` ürün açıklaması teknik davranışla birebir eşleşecektir:
“Zorunlu geçiş reklamlarını kaldırır; isteğe bağlı rewarded ipuçları devam
edebilir.” Ürün metni tüm reklamların kaldırıldığını söylüyorsa rewarded
reklam da kapatılmalıdır.

Unity Android entegrasyonları C# arayüzlerinin arkasında tutulur; gerektiğinde
AndroidJavaObject/JNI veya uyumlu resmi Unity SDK adapter'ı kullanılır.
SDK callback'leri ana thread'e aktarılır, oturum id'si ile tekilleştirilir ve
kapanmış sahneye erişmez. İlk dikey dilim bu SDK'ları paketlemez.

Google Play Billing satın alma durumu sorgulanır; pending satın alma entitlement
vermez. Başarılı ürün teslimi ve restore idempotent olur, gerekli acknowledge
tamamlanır. Unity SDK/package ve transitif Billing sürümü entegrasyon tarihinde
resmi destek şartlarıyla doğrulanır; eski Godot plugin pin'i kullanılmaz.

### 8.7. Platform adaptörleri

~~~
SaveService
SettingsService
AudioService
HapticService
~~~

Core bu servisleri doğrudan çağırmaz. Android titreşimi, ses çıkışı ve dosya
kayıtları yalnızca platform katmanında uygulanır. Android reklam, billing ve
consent adapter’ları da aynı sınırda kalır. iOS eklendiğinde aynı
sözleşmelerin iOS uygulaması kullanılacaktır.

### 8.8. Android yayın akışı

- Unity Hub üzerinden seçilen Editor'e ait Android Build Support, SDK/NDK ve
  OpenJDK modülleri kurulmalıdır; bu belge hazırlanırken Editor tespit edilmedi.
- Android Build Profile, portre yönü, sahne/bootstrap girişi ve URP referansları
  ana uygulama tarafından doğrulanır.
- Debug APK gerçek cihaz testi içindir; release keystore ile AAB yayın içindir.
- IL2CPP/ARM64, stripping ve serialization player build'inde ayrıca test edilir.
- Dikey dilimin birleşik manifestinde INTERNET izni, ads, billing veya consent
  SDK'sı bulunmadığı denetlenir; Resources içeriği tamamen yerelden gelir.
- Çentik/safe-area, pause/resume, geri tuşu ve uçak modu cihazda doğrulanır.
- Ortak Android Studio SDK/JDK silinmez; Unity'nin desteklediği araç sürümleri
  ayrı kontrol edilir. Mevcut ortam değişkenleri tek başına uyumluluk kanıtı değildir.

iOS daha sonra macOS ve seçilen Unity sürümüyle uyumlu Xcode üzerinde export,
imzalama, IL2CPP, yerel save ve offline cihaz testleri gerektirir. C# Core ve
Unity sahne/bileşen sözleşmeleri platformdan bağımsız tutulur.

### 8.9. Backend sınırı

İlk yayın için Prismaze’in kendi backend’i kurulmaz. Node.js, Firebase
Functions, Supabase veya AWS tabanlı bir servis temel oyun, campaign level’ları,
procedural katalog, save, settings, AdMob veya Google Play purchase akışı
için gerekli değildir. AdMob ve Google Play kendi servislerini kullanır;
Prismaze’in ayrıca sunucu çalıştırması gerekmez.

Backend ancak şu ihtiyaçlardan biri kapsam içine alınırsa değerlendirilir:

- Cihazlar arası cloud save
- Hesap ve cross-device progression
- Sunucu kontrollü günlük puzzle veya saat manipülasyonuna dayanıklı etkinlik
- Global leaderboard veya rekabetçi mod
- Uzaktan level yayınlama ve A/B testleri
- Live event, push notification veya server-controlled reward
- Tüketilebilir ekonomi ve hileye duyarlı satın alma ödülleri

Tarih tabanlı günlük puzzle ileride backend olmadan üretilebilir; ancak cihaz
saatinin değiştirilmesiyle manipüle edilebilir. Bu nedenle ilk sürüm özelliği
değildir.

## 9. Test ve kalite kapıları


### 9.1. Core testleri

Saf C# test runner sonuçları yalnız Core kapsamını kanıtlar. Unity Test Framework
EditMode testleri ayrıca ScriptableObject dönüşümü ve asset validation'ı;
PlayMode testleri MonoBehaviour yaşam döngüsü, Canvas/input, tutorial, ses ve
sahne geçişini kapsar. Test XML ve Editor logları saklanır. Editor yokken bu
kapılar doğrulanmamış kalır; masaüstü C# başarısı APK başarısı sayılmaz.


- Izgara sınırları ve komşuluk
- Yön dönüşümü
- Dört ayna yönünün yansıma tablosu
- Prizma çıkışları ve yalnızca white maskenin split edilmesi
- Renkli maskelerin prizma içinden değişmeden geçmesi
- Ray state’in position + direction + color_mask ile ayrıştırılması
- Boş hücrede kesişen ışınların karışmaması
- Target’ın aldığı rengi kaydedip ışını devam ettirmesi
- RGB maskeleri
- Duvar çarpışması
- Hedefin tam maske kontrolü
- Fazla renk geldiğinde hedefin başarısız olması
- Döngü tespiti
- Kazanma kontrolü

### 9.2. Level testleri

- Aynı seed ve generator version aynı bölümü üretir.
- Her el yapımı bölümün `canonical_solution` çözümü replay ile kazanır.
- Her generated bölümün `canonical_solution` çözümü replay ile kazanır.
- Aynı hücrede iki nesne bulunamaz.
- Bölüm sınırları dışına nesne çıkamaz.
- Işınlar sonsuz döngüye giremez.

### 9.3. Kayıt ve entegrasyon testleri

- Bölüm ortasında kapatıp devam etme
- Reset sonrası başlangıç durumuna dönme
- Bozuk ana kayıt ve backup davranışı
- İnternet bağlantısı olmadan açılış ve oynanış
- Dokunmanın doğru hücreye dönüşmesi
- Farklı ekran oranları ve çentikler
- Uygulamayı arka plana alıp geri dönme
- Yeni uygulama oturumunda startup stinger bir kez çalar.
- Scene reload, hot restart ve Main Menu’ye dönüşte startup stinger tekrar
  tetiklenmez.
- Ses kapalı veya Master/Music seviyesi sıfırken stinger açılış akışını
  bekletmeden atlar.
- Stinger asset’i eksikse açılış devam eder ve güvenli log üretilir.

### 9.4. Monetization testleri

- Dikey dilimde reklam, billing veya consent plugin’i yüklenmez.
- Interstitial gameplay sırasında hiçbir koşulda açılmaz.
- İlk 5 bölümde interstitial isteği yapılmaz.
- Frequency-cap ve `remove_ads` interstitial çağrısını bastırır.
- Reklam hazır değilse sonraki bölüm akışı beklemez.
- Rewarded ödülü yalnızca `onUserEarnedReward` callback’i ile verilir.
- Aynı rewarded oturumu için ikinci callback ikinci ödül oluşturmaz.
- Pending satın alma entitlement olarak işlenmez.
- Non-consumable ürün yeniden sorgulandığında entitlement tekrar doğru kurulur.
- Monetization bağlantı hatası offline bölüm oynanışını bozmaz.

### 9.5. UI/UX ve presentation testleri

Her büyük presentation iterasyonunda en az 5 ilk kez oynayan katılımcıyla
kısa usability testi yapılır. Kabul eşikleri:

- En az 4/5 kullanıcı ana menüde Başla/Devam Et eylemini 10 saniye içinde
  yardım almadan bulur.
- En az 4/5 kullanıcı ilk board’da hangi nesnelerin döndürülebildiğini doğru
  söyler.
- En az 4/5 ilk kez oynayan kullanıcı animasyonlu el ve açıklama sayesinde
  ilk gerekli dokunuşu 15 saniye içinde yardım almadan yapar.
- En az 4/5 kullanıcı İpucu, Sıfırla ve Duraklat kontrollerini 5 saniye içinde
  bulur.
- En az 4/5 kullanıcı level completion durumunu ve sonraki eylemi doğru
  anlar.

Cihaz ve sunum kontrolleri:

- Tutorial yalnız ilk girişte otomatik açılır; tamamlanınca tekrar açılmaz.
- Tutorial ortasında kapanıp açıldığında kayıtlı adım devam eder.
- Atla ve “İlk Bölüm Eğitimini Tekrarla” akışları doğru state’i yazar.
- El/pointer responsive layout sonrası doğru ayna hücresinin merkezine bağlı
  kalır ve oyuncunun gerçek dokunuşunu engellemez.
- Beklenen obje dışındaki dokunuş tutorial sırasında level state’ini değiştirmez.
- Reduced Motion’da hareketli el yerine statik pointer ve metin görünür.

- 360×640, 360×800 ve 412×915 referans viewport’larında HUD board’u kapatmaz.
- Compact, Standard ve Large/Tablet responsive sınıfları ayrı snapshot ve
  fiziksel cihaz testlerinden geçer.
- Çentik/safe-area simülasyonunda ana kontroller görünür ve dokunulabilir kalır.
- Ana dokunma alanları en az 48 dp ölçülür.
- 1.0 ve 1.3 sistem metin ölçeğinde CTA label’ları taşmaz ve dokunma alanı
  küçülmez.
- Döndürülebilir objeler renk kapalı mockup’ta da sabit objelerden ayrılır.
- High Contrast, Reduced Glow, Reduced Motion ve Color Assist kombinasyonları
  ayrı ayrı ve birlikte test edilir.
- Reduced Motion açıkken bütün motion token’larının global override aldığı;
  rotation, slide, scale, shake ve parallax’ın kapanması doğrulanır.
- Her theme için background kapalı/açık karşılaştırmasında beam ve target
  okunabilirliği korunur.
- Hızlı arka arkaya dokunuşlar animasyon state’ini veya model yönünü bozmaz.
- 10 dakikalık ses testinde tekrar eden SFX üst üste binmez, clipping yapmaz
  ve rahatsız edici tekrar oluşturmaz.
- Monetized build’de Store/Restore görünürlüğü; monetization kapalı build’de
  bu girişlerin tamamen gizlenmesi doğrulanır.
- Assets dışındaki düzenlenebilir kaynaklar ve LegacyGodot'un release paketine
  girmediği build raporuyla doğrulanır.

### 9.6. Performans hedefleri

- Düşük cihazlarda oynanış hedefi: stabil 30 FPS
- Orta ve üst cihazlarda oynanış hedefi: 60 FPS
- Tek hamleden sonra ışın sonucu bir sonraki frame döngüsünde güncellenir.
- Tek bölümün ışın hesaplaması, cihaz testlerinde frame bütçesini aşmayacak.
- Parçacık ve glow sayısı kalite seviyesine göre sınırlandırılır.

Unity Profiler ile cihazda CPU trace süresi, GC allocation, GPU ve overdraw
ölçülür; yalnız masaüstü Editor FPS'i kabul kanıtı değildir.

### 9.7. İlk sürüm kabul kriterleri

İlk 12 bölüm için:

1. Her bölümde en az bir geçerli çözüm bulunur.
2. RayTracer ve görsel ışın aynı yönleri gösterir.
3. Reset, Hint, devam etme ve bölüm geçişi çalışır.
4. Uçak modunda oyun tamamen oynanır.
5. Düşük cihaz kalite seviyesinde oynanış akıcıdır.
6. Hiçbir bölüm sonsuz ışın döngüsü oluşturmaz.
7. Glow kapatıldığında nesne, ışın ve hedefler okunabilir kalır.
8. İlk giriş tutorial’ı animasyonlu el, açıklama, Atla, kaldığı yerden devam
   ve Reduced Motion davranışlarıyla çalışır.

## 10. Uygulama sırası

### Aşama 1 — Temiz temel

Unity projesi, Git yapısı, portre Android Build Profile, URP 2D renderer,
C# assembly sınırları ve bootstrap sahnesi oluşturulur.

### Aşama 2 — Saf oyun mantığı

Grid, renk, yön, nesne modelleri, RayTracer, WinChecker ve otomatik testler
tamamlanır. Bu aşamada gelişmiş grafik yapılmaz.

### Aşama 3 — İlk oynanabilir sürüm

GameSession, dokunma ile döndürme, 12 el yapımı bölüm, reset, hint, bölüm
geçişi ve yerel kayıt eklenir. Android cihazda ilk dikey dilim test edilir.
Birinci bölüm için açıklama kartı, spotlight ve animasyonlu el kullanan
TutorialController akışı eklenir.
Dikey dilimde monetization kapalı tutulur; Hint’in ilk ücretsiz kullanımı
internet olmadan çalışır.

### Aşama 4 — UI/UX ve presentation

Ana menü, HUD, sonuç ekranı, buton component sistemi, motion token’ları,
art direction, 2.5D katmanları, gölgeler, shader’lar, ışın glow’u,
parçacıklar, parallax, ses, titreşim ve accessibility modları eklenir.
Startup stinger `AudioService` üzerinden Splash/logo reveal ile bağlanır.
İlk usability testi bu aşamanın kabul kapısıdır.

### Aşama 5 — Monetization entegrasyonu

Android plugin adapter’ları, MonetizationController, AdPolicy, RewardService,
ConsentService, EntitlementService ve ProductCatalog eklenir. Bu aşamada
yalnızca test reklam kimlikleri kullanılır. Banner, starter pack, tüketilebilir
hint paketi ve abonelik eklenmez.

### Aşama 6 — İçerik genişletme

Yeni mekanikler ve 30–50 kaliteli bölüm hazırlanır. Bölüm doğrulama aracı,
seed katalog üretim aracı ve gerekirse Unity EditorWindow tabanlı basit level editor eklenir.

### Aşama 7 — Android yayın hazırlığı

Düşük/orta/üst cihaz matrisi, kayıt bozulması, offline çalışma davranışı, farklı ekran
oranları, release imzalama, AAB ve mağaza görselleri doğrulanır.
UI/UX usability eşikleri, ses tekrarı, safe-area, color assist ve reduced
motion kombinasyonları fiziksel Android cihazlarda tekrar test edilir.
Doğrulanmış seed kataloğu da bu aşamada bütün seçili entry’ler için yeniden
üretilip signature ve difficulty metrikleriyle kontrol edilir. Kontrol
başarısızsa endless mod yayın build’inde kapalı kalır; campaign yayınlanabilir.

### Aşama 8 — Gelecek modu

Çekirdek oyun ve kampanya stabil olduktan sonra doğrulanmış seed kataloğunu
kullanan deterministik endless jeneratör, ileri prizma türleri, hareketli
engeller, iOS export ve Apple StoreKit adapter’ı eklenebilir. Runtime'da rastgele bölüm retry sistemi bu sözleşmenin parçası değildir.

## 11. Tasarımın başarı ölçütü

Yeni proje başarılı sayılırsa:

- Oyuncu ışığın neden o yöne gittiğini anlayabilir.
- İlk kez oynayan kullanıcı ana eylemi ve döndürülebilir nesneleri yardım
  almadan anlayabilir.
- Dokunma, motion ve ses geri bildirimleri hızlı ve tutarlı hissedilir.
- Her bölüm çözülebilir ve çözüm sonucu tekrarlanabilirdir.
- Görsel kalite yükseltilirken oyun mantığı değişmez.
- Background ve tema skin’leri beam/target okunabilirliğini azaltmaz.
- Erişilebilirlik modları sunum efektleri kapalıyken de tüm mekanik bilgiyi
  korur.
- Android’de temel oyun offline çalışır ve farklı ekranlarda güvenilir çalışır.
- Monetization bağlantı, consent veya plugin hatası temel oynanışı bloke etmez.
- Yeni mekanik eklemek mevcut nesneleri ve kayıtları bozmaz.
- Sonsuz içerik eklenmesi kampanya kalitesinin önüne geçmez.

## 12. UI/UX, Art Direction ve Presentation

Bu bölüm teknik render sisteminden farklı olarak oyuncunun gördüğü, duyduğu
ve dokunarak hissettiği sunum dilini tanımlar. Prismaze yalnızca çalışan bir
ızgara değil; canlı, dokunulası, anlaşılır ve ödüllendirici bir mobil oyun
olarak hissedilmelidir.

### 12.1. Deneyim ilkeleri

- Ana odak her zaman board ve ışın akışıdır.
- UI, puzzle’ı kapatmaz; eylemleri açıklayan ikincil katmandır.
- Kabul edilen her dokunuş görsel geri bildirim üretir; ses ve haptic açıksa
  bunlar da aynı state değişimini destekler.
- Oyuncu her anda yapabileceği temel eylemleri görebilir: döndür, ipucu al,
  sıfırla, duraklat ve devam et.
- Başarılı ara durumlar küçük tatmin verir; bölüm bitişi belirgin ama kısa bir
  kutlamadır.
- Eğlenceli görünüm okunabilirlikten, kontrasttan veya hızdan ödün vermez.
- Gameplay sırasında zorunlu modal, mağaza çağrısı veya reklam bulunmaz.
- Bir efekt kapatıldığında mekanik bilgi kaybolmaz.

### 12.2. Navigasyon ve ekran akışı

~~~
Boot / Splash
      ↓
Main Menu
 ├── Devam Et / Başla
 ├── Bölüm Seçimi
 ├── Ayarlar
 └── Temalar / Mağaza (yalnızca monetized build)
      ↓
Oyun
 ├── Duraklat / Ayarlar
 ├── Sıfırla
 └── İpucu
      ↓
Level Result
 ├── Next Level
 ├── Replay
 └── Main Menu
~~~

Boot sırasında save yüklenir ve ana menü mümkün olan en kısa sürede
erişilebilir olur. UMP consent gerekiyorsa yalnızca menü bağlamında gösterilir;
aktif puzzle üzerine çıkarılmaz. Monetization derlenmemiş veya kapalıysa
Themes/Store ve Restore Purchases girişleri tamamen gizlenir.

### 12.3. Ana menü

- Yeni oyuncuda ana CTA “Başla”, kaydı olan oyuncuda “Devam Et” olur.
- Ana CTA ekranın görsel ağırlık merkezidir ve tek bakışta anlaşılır.
- Bölüm Seçimi ve Ayarlar ikincil eylemlerdir.
- Monetized build’de Themes/Store ikincil eylem olarak yer alır; satın alma
  oyuna başlama yolunu kesmez.
- Arka planda ışık ve prizma temasını anlatan yavaş, dekoratif bir sahne
  bulunur.
- Menüde aynı anda birden fazla güçlü animasyon veya parlayan CTA kullanılmaz.
- Başlık, logo ve CTA küçük ekranlarda güvenli alan dışına taşmaz.

### 12.4. İlk bölüm onboarding layout’u

İlk kez giren ve oyunu bilmeyen kullanıcı, birinci bölümün içinde kısa ve
etkileşimli bir tutorial görür. Tutorial ayrı bir uzun açıklama ekranı değildir;
oyuncuya gerçek board üzerinde tek eylem yaptırır.

Tutorial katman sırası:

~~~
HUD ve Atla
Açıklama kartı
TutorialLayer
  ├── yarı saydam dim overlay
  ├── hedef objenin çevresinde spotlight boşluğu
  ├── animasyonlu el / statik pointer
  └── tap ring
Board
~~~

Birinci bölüm yalnızca bir kaynak, bir döndürülebilir ayna ve bir hedef
kullanır. Başlangıç yönü tek dokunuşla çözülecek şekilde hazırlanır.

Adım akışı:

1. Board yüklenir; kaynak ve hedef kısa süre vurgulanır. Açıklama:
   “Işığı hedefe ulaştıralım.”
2. Diğer alan hafif kararır, döndürülecek ayna spotlight içinde kalır.
3. Açıklama kartı “Aynayı döndürmek için dokun” der.
4. El işareti aynanın yaklaşık 20 dp üstünde görünür, aynaya doğru yaklaşır,
   tap ring üretir ve geri döner.
5. Tutorial objeyi otomatik döndürmez; oyuncunun gerçek dokunuşunu bekler.
6. Beklenen ayna InputRouter üzerinden döndürüldüğünde RayTracer normal akışta
   çalışır, el kaybolur ve hedef dolar.
7. “Harika! Işık hedefe ulaştı.” mesajı gösterilir ve sonuç ekranına geçilir.

El animasyonu `duration-normal` temelli üç döngü oynar; her döngüde scale
1.00 → 0.88 → 1.00 ve 8 dp düşey hareket kullanır. Üçüncü döngüden sonra
pointer statik kalır. Oyuncu hâlâ dokunmadıysa 3 saniye sonra tek bir yeni
hatırlatma döngüsü oynatılabilir.

TutorialLayer dokunmayı kendisi tüketmez. Beklenen obje dışındaki board
dokunuşları state değiştirmez ve açıklama kartında kısa bir yönlendirme
pulse’u oluşturur. Geri, Duraklat ve Atla her zaman kullanılabilir.

Reduced Motion açıkken el hareket etmez; statik el/ok, yüksek kontrastlı
focus ring ve aynı açıklama metni kullanılır. Tutorial bilgisi yalnız
animasyonla verilmez.

Yerel kayıt `tutorial_version`, `tutorial_step` ve `tutorial_completed`
değerlerini saklar. Uygulama tutorial ortasında kapanırsa aynı adım açılır.
Atla seçilirse tutorial tamamlanmış olarak işaretlenir; Ayarlar → Yardım →
“İlk Bölüm Eğitimini Tekrarla” ile yeniden başlatılabilir.

Tutorial sistemi ileride prizma veya renk karışımının ilk kullanımı için
yeniden kullanılabilir; ancak yeni mechanic tutorial’ları aynı anda birden
fazla kavram anlatamaz.

### 12.5. Oyun ekranı ve HUD

Portre yerleşimi üç ana bölgeden oluşur:

~~~
Üst güvenli alan
  Geri / Bölüm bilgisi / Duraklat

Orta alan
  6×12 board ve ışınlar

Alt güvenli alan
  Sıfırla / İpucu
~~~

Board kalan alanın ortasına yerleşir. Hücre boyutu tek formülle hesaplanır:

~~~
cell_size = min(available_width / columns, available_height / rows)
~~~

Dokunma koordinatı ve çizim aynı `BoardLayout` dönüşümünü kullanır. HUD
yüksekliği sabit pixel varsayımına bağlanmaz; safe area ve ekran oranına göre
hesaplanır. Ana aksiyonların dokunma alanı en az 48 dp, görsel hedefi en az
40 dp olacaktır.

Responsive davranış portre ve content-first çalışır:

| Sınıf | Koşul | HUD davranışı |
|---|---|---|
| Compact | Yükseklik < 700 dp veya genişlik < 400 dp | İkincil label’lar gizlenir, ikonlar ve board öncelik alır |
| Standard | 400–599 dp genişlik ve yeterli yükseklik | İkon + kısa label, normal spacing |
| Large/Tablet | Genişlik ≥ 600 dp | Board ortalanır, cell size 72 dp ile sınırlandırılır, HUD maksimum genişlik kullanır |

Oyun Android’de portreye kilitlidir; landscape ilk sürümde desteklenmez.
Compact düzende fonksiyon gizlenmez, yalnızca ikincil metin ve dekor azalır.
Metin ölçeği büyüdüğünde butonlar içerik kadar genişler veya label bir satır
kısalır; dokunma alanı küçülmez.

Döndürülebilir objeler sabit objelerden silüet, çerçeve ve hafif idle highlight
ile ayrılır. Dokunulan obje 250 ms boyunca kısa pulse/shine tepkisi verir;
kalıcı seçim modu yoktur.

### 12.6. Sonuç ekranı

Sonuç ekranı board’u tamamen yok etmek yerine arkada karartılmış halde
korur; oyuncu az önce çözdüğü düzeni görmeye devam eder.

Gösterilen bilgiler:

- Bölüm tamamlandı başlığı
- Kazanılan yıldız
- Hamle sayısı ve par
- Süre
- Birincil “Sonraki Bölüm” butonu
- İkincil “Tekrar Oyna” ve “Ana Menü” eylemleri

Interstitial yalnızca sonuç ekranı kapandıktan ve oyuncu sonraki bölüme
geçmeyi seçtikten sonra AdPolicy tarafından değerlendirilebilir. Reklam hazır
değilse geçiş beklemez.

### 12.7. UI bileşen ve buton dili

Butonlar genel uygulama kontrolü gibi değil, aynı kristal/ışık evrenine ait
mobil oyun parçaları gibi görünür.

**Karakter:**

- Yuvarlatılmış köşeler
- Hafif katmanlı veya kristalimsi yüzey
- Üst kenarda inner highlight
- Alt kenarda kontrollü gölge
- Birincil eylemde ölçülü glow
- İkon ve kısa metnin birlikte kullanımı

**Durumlar:**

| Durum | Görsel davranış |
|---|---|
| Normal | Net yüzey, okunabilir label ve hafif gölge |
| Pressed | %94 scale, gölge azalması, kısa ses/haptic |
| Disabled | Düşük kontrast; glow ve haptic yok |
| Highlighted | Tek seferlik pulse veya kenar ışığı |
| Rewarded | Video etiketi ve ödül açıklaması görünür |
| Premium | Altın/mor vurgu; ana gameplay CTA’sına benzemez |

Aynı ekranda birden fazla birincil buton kullanılmaz. Destructive olmayan
Sıfırla eylemi görünür fakat Başla/Sonraki Bölüm kadar baskın değildir.
İkonlar tek başına belirsiz kalıyorsa kısa label ile desteklenir.

### 12.8. Motion language

Motion hızlı, yumuşak ve tepki veren bir karaktere sahiptir. Animasyonlar
oyuncunun sonraki hamlesini bekletmez.

Motion ilkeleri:

- Purposeful: Her hareket state, ilişki veya başarı bilgisini açıklar.
- Quick: UI oyuncunun temposunu yavaşlatmaz.
- Physical: Girişte yavaşlayan, çıkışta hızlanan ve kontrollü spring kullanan
  tutarlı bir fizik hissi vardır.
- Accessible: Hareket azaltılabilir ve hiçbir bilgi yalnız animasyonla verilmez.

| Motion token | Süre | Kullanım | Easing |
|---|---:|---|---|
| `duration-instant` | 60 ms | Basma, focus ve küçük highlight | `ease-standard` |
| `duration-fast` | 120 ms | Ayna/prizma dönüşü, micro-bounce | `ease-spring` |
| `duration-normal` | 220 ms | Hedef dolumu ve standart state değişimi | `ease-standard` |
| `duration-moderate` | 320 ms | Panel ve ekran geçişi | `ease-enter` / `ease-exit` |
| `duration-celebration` | 600 ms | Ana completion pulse’u | `ease-spring` + fade |

Easing sözlüğü; merkezi C# motion sürücüsü/AnimationCurve ile uygulanır,
üçüncü taraf tween paketi zorunlu değildir. UI geçişleri unscaled time kullanır;
model yönü her komutta anında güncellenir, coroutine yalnız görünümü izler:

| Easing token | Unity uygulama eğrisi | Kullanım |
|---|---|---|
| `ease-standard` | Cubic In/Out | Aynı ekrandaki state değişimleri |
| `ease-enter` | Cubic Out | Ekrana veya panele giriş |
| `ease-exit` | Quad In | Ekrandan veya panelden çıkış |
| `ease-spring` | Back Out | Kontrollü tactile bounce |
| `ease-linear` | Linear | Yalnızca sürekli loop ve enerji akışı |

Nesne ve efekt davranışları:

- Ayna/prizma 90° dönüşü `duration-fast` sürer.
- Arka arkaya dokunma önceki tween’i iptal edip en güncel model yönüne
  retarget eder; giriş kaybolmaz.
- RayTracer sonucu hamleyle hemen hesaplanır; ışın görseli 120–240 ms enerji
  akışıyla yeni segmente geçer.
- Yansıma noktasında kısa sparkle oluşur; yanlış/blocked yönünde ışın çarpıp
  hızlıca sönümlenir.
- Target dolumu `duration-normal`, level completion ana pulse’u
  `duration-celebration` sürer.
- Sonuç yıldızları önem sırasıyla 40 ms stagger kullanır; yıldız dizisinin
  toplamı 500 ms’yi, bütün kutlama 1 saniyeyi aşmaz.
- Kamera tepkisi düşük genlikli ve yalnızca bölüm tamamlamada kullanılır.
- Aynı semantic gruptaki öğeler aynı duration ve easing token’ını kullanır.
- HUD’un sabit konumu, level numarası ve okunabilirlik için gerekli işaretler
  idle durumda animasyon oynatmaz.
- Aynı anda birden fazla CTA pulse etmez; sürekli hareket yalnızca arka planın
  düşük yoğunluklu dekorunda veya beam enerji akışında kullanılır.

Reduced Motion global token override olarak uygulanır: rotation, slide, scale,
parallax, kamera shake, bounce ve yoğun parçacıklar 0 ms/anlık state’e iner.
Yalnızca gerekli loading/progress hareketi ve en fazla 80 ms opacity fade
korunur; bu karar her component içinde ayrı ayrı verilmez.

### 12.9. Ses ve müzik yönü

Ses kimliği hafif gizemli, temiz, parlak ve rahatlatıcıdır. Camımsı küçük
vuruşlar, yumuşak synth dokuları ve optik enerji hissi kullanılır; sert arcade
alarm sesleri ve yorucu yüksek frekans tekrarları kullanılmaz.

SFX grupları:

- UI press ve panel geçişi
- Ayna dönüşü
- Prizma dönüşü
- Işın aktive olma ve yeniden yönlenme
- Yansıma sparkle
- Target charge ve doğru renk
- Blocked/wrong state
- Hint reveal
- Level complete ve yıldız
- Pause/resume
- Startup/logo reveal stinger

Tekrarlanan SFX için en az üç yakın varyasyon veya ±%2 pitch değişimi
kullanılır. Aynı sesin üst üste binmesini önlemek için kısa cooldown bulunur.
Başarı sesleri normal etkileşimlerden daha geniş ve parlak duyulur; ancak
oyun müziğini uzun süre bastırmaz.

Müzik yönü:

- Ana menü: merak uyandıran, hafif büyülü ve kusursuz döngülenen kısa parça
- Gameplay: konsantrasyonu bozmayan ambient/puzzle loop
- Sonuç: ayrı uzun şarkı yerine kısa pozitif completion jingle

Ayarlar Master, Music, SFX ve Vibration kontrollerini ayrı sunar. Müzik ve
SFX dosyaları uygulamayla birlikte gelir; streaming gerekmez.

**Startup stinger sözleşmesi:**

- Kaynak dosya: `D:/Prismaze/artifacts/audio/sfx/starting_sound.mp3`.
- Runtime hedefi: `Assets/Resources/Audio/stingers/starting_sound.mp3`.
- Tarihsel kaynak profili: yaklaşık 8,4 saniye, stereo, 48 kHz, 192 kbps;
  Unity AudioClip import ve cihaz sesi ayrıca doğrulanır.
- Boot/Splash sırasında yalnızca bir kez çalar; loop’a girmez.
- Logo reveal veya ilk marka görünümüyle senkronlanır ve kuyruğa ikinci kez
  eklenmez.
- Ses kapalıysa veya Master/Music seviyesi sıfırsa atlanır; açılış akışı
  gecikmez.
- Scene reload, hot restart veya Main Menu’ye dönüş startup stinger’ı yeniden
  tetiklemez; yalnızca yeni uygulama oturumu tetikleyebilir.
- AudioService ayrı AudioSource/AudioMixer gruplarıyla BGM, SFX ve stinger'i
  yönetir. Master/Music ayarları ses tetiklenmeden önce JSON'dan yüklenir.
- Oturum guard'ı denemeden önce işaretlenir; mute/eksik clip nedeniyle atlanan
  stinger sonradan ses açılınca yeniden kuyruğa girmez. Menüye geçiş 8,4 saniyelik
  clip'i beklemez. Persist eden servis duplicate AudioSource oluşturmaz.
- Editor'de yeni Play oturumu yeni uygulama oturumudur; domain reload kapalıysa
  RuntimeInitializeOnLoadMethod ile oturum başlangıcı doğru sıfırlanır. Aynı
  Play oturumunda scene reload guard'ı sıfırlamaz; background/resume tekrar çalmaz.
- Melodi ve sample’lar Prismaze’e özgü olur; başka bir oyunun melodisi veya
  kaydı taklit edilmez.
- Kullanıcının ürettiği/orijinal ses olduğu release asset manifestinde
  kaynak ve kullanım hakkıyla kayıt altına alınır.

### 12.10. Art direction

Prismaze’in sanat dili renkli, parlak, temiz, okunabilir, hafif premium ve
casual puzzle kitlesine uygun olacaktır. Eğlenceli görünür; ancak oyuncak veya
fazla çocukça bir karaktere kaymaz.

**Temel görsel kurallar:**

- Board koyu lacivert/kömür nötrleri üzerinde yüksek mekanik kontrast taşır.
- Kırmızı, yeşil, mavi ve karışım renkleri gameplay anlamına ayrılır; dekor
  bu renkleri aynı yoğunlukta kullanmaz.
- UI ana vurguları mor, camgöbeği ve kontrollü altın tonlarıyla kurulur.
- Her gameplay nesnesi küçük ekranda yalnız silüetinden tanınabilir.
- Kaynak, ayna, prizma, hedef ve duvar tek bir perspektif, ışık yönü ve
  kenar kalınlığı sistemi kullanır.
- Glow yalnızca süs değildir; aktiflik, yön veya başarı bilgisini destekler.
- Aynı anda en fazla bir güçlü odak glow’u bulunur.

İlk tema “Crystal Lab” olacaktır. Sonraki görsel skin örnekleri Crystal Cave,
Neon Lab, Dream Observatory ve Aurora Temple’dır. Temalar yalnızca görsel ve
işitsel skin olarak davranır; level geometrisini veya oyun kurallarını
değiştirmez.

### 12.11. Background sistemi

Her background üç katmandan oluşur:

1. Düşük kontrastlı gradient base
2. Yavaş hareket eden parallax dekor
3. Seyrek ve düşük opaklıklı ortam parçacıkları

Board’un arkasında daha sade ve daha koyu bir contrast plate bulunur.
Yüksek frekanslı doku, yoğun parçacık veya parlak dekor doğrudan beam ve
target arkasına yerleştirilmez. Low kalite veya Reduced Motion modunda
parallax ve ortam parçacıkları kapatılır; gradient ve contrast plate kalır.

### 12.12. Tipografi sistemi

Ana marka/display fontu `DynaPuff` olacaktır. İncelenen yerel dosyalar:

- `DynaPuff-Regular.ttf` — 400
- `DynaPuff-Medium.ttf` — 500
- `DynaPuff-SemiBold.ttf` — 600
- `DynaPuff-Bold.ttf` — 700

Dört dosyanın font metadata’sı DynaPuff ailesiyle eşleşir ve Türkçe
Ç/Ğ/İ/Ö/Ş/Ü ile ç/ğ/ı/ö/ş/ü glyph’lerinin tamamını içerir. Fontlar
runtime’da ağdan indirilmez; uygulamayla birlikte paketlenir.

DynaPuff güçlü ve eğlenceli bir karakter taşıdığı için logo, ana başlık,
bölüm başlığı, kısa CTA ve yıldız/sonuç metinlerinde kullanılır. Uzun tutorial,
ayar, consent, privacy ve legal metinlerinde daha nötr `Noto Sans` kullanılır.
Unity text bileşeninde fallback listesi açıkça paketlenmiş font asset'leriyle
kurulur; platform sans-serif'in kendiliğinden bulunacağı varsayılmaz. TextMeshPro
kullanılıyorsa Türkçe glyph atlası ve fallback asset referansları doğrulanır.
Noto Sans mevcut Assets envanterinde yoktur; eklenene kadar uzun metin tipografi
kabul kapısı açık kalır.

Temel tipografi token’ları:

| Token | Font | Boyut / satır | Ağırlık | Kullanım |
|---|---|---:|---:|---|
| `type-caption` | Noto Sans | 12 / 16 | 500 | Yardımcı bilgi, süre etiketi |
| `type-label` | DynaPuff | 14 / 18 | 500 | Kısa buton ve HUD label |
| `type-body` | Noto Sans | 16 / 24 | 400 | Tutorial, ayar, açıklama |
| `type-title` | DynaPuff | 22 / 28 | 600 | Panel ve bölüm başlığı |
| `type-heading` | DynaPuff | 30 / 36 | 700 | Ana ekran başlığı |
| `type-display` | DynaPuff | 44 / 50 | 700 | Logo ve completion anı |

`type-display` istisnai kullanımdır; normal ekranda caption, label, body,
title ve heading ölçeğinin dışına çıkılmaz. Büyük başlıklarda -0.01 em, body
metninde 0, kısa label’larda en fazla +0.02 em letter spacing kullanılır.
Türkçe casing sorunlarını önlemek için UI label’ları gereksiz ALL CAPS
yazılmaz.

Responsive tipografi:

- Compact: display 38, heading 26, title 20; body 16 olarak korunur.
- Standard: tablodaki değerler kullanılır.
- Large/Tablet: display en fazla 48, heading en fazla 34 olur; metin büyürken
  satır uzunluğu kontrolsüz genişlemez.
- Sistem metin ölçeği 1.0 ve 1.3 için layout testi zorunludur.

Font QA gerçek Türkçe içerikle yapılır: “Işığı doğru hedefe yönlendir”,
“Bölüm tamamlandı”, “Satın alımların geri yüklendi” ve “İpucu kullan”.
DynaPuff uzun paragraf veya legal metinde kullanılmaz.

Yerel `fonts/` klasöründe lisans dosyası bulunmadığı için release öncesi
DynaPuff’ın resmi SIL Open Font License 1.1 dosyası ve copyright bildirimi
fontlarla birlikte lisans manifestine eklenmelidir.
[DynaPuff resmi kaynak ve lisansı](https://github.com/googlefonts/dynapuff)

Noto Sans da resmi kaynaktan alınacak, lisansı manifestte tutulacak ve yalnız
gerekli Latin/Türkçe dosyaları paketlenecektir.
[Noto Sans resmi Google Fonts kaynağı](https://github.com/google/fonts/tree/main/ofl/notosans)

### 12.13. Asset üretim sistemi

Asset grupları:

- Mirror set
- Prism set
- Source set
- Target set
- Wall set
- HUD ikonları ve buton parçaları
- FX texture/sprite’ları
- Background katmanları
- Tema varyasyonları

Düzenlenebilir kaynak dosyalar ile oyunda kullanılan export dosyaları ayrı
tutulur:

~~~
artifacts/art/source/          # Assets dışında düzenlenebilir kaynak
artifacts/audio/source/        # Assets dışında düzenlenebilir kaynak
Assets/Art/                    # Unity referanslarıyla paketlenen export
Assets/Resources/Audio/runtime/
Assets/Resources/Audio/stingers/
Assets/Resources/Fonts/
~~~

Unity Assets altını import eder; `.gdignore` Unity exclusion mekanizması değildir.
Düzenlenebilir kaynaklar ve LegacyGodot, Assets dışında kalır. Resources altındaki
dosyalar build'e dahil olacağından yalnız gereken runtime dosyaları burada tutulur.
.meta dosyaları ve referans GUID'leri korunur; build raporunda içerik denetlenir.

Runtime asset adları küçük harfli ve amaç odaklıdır:

~~~
obj_mirror_base_v01.webp
obj_prism_crystal_v01.webp
ui_btn_primary_9slice.webp
fx_beam_spark_v01.webp
bg_crystal_lab_far_v01.webp
~~~

Gameplay objelerinin pivot’u hücre merkezidir; bütün varyasyonlar aynı bounding
box ve optik merkez standardını korur. UI ikonları kaynakta SVG olabilir; runtime'da doğrulanmış Unity importer veya
PNG sprite kullanılır. Dokulu oyun objeleri kayıpsız PNG olarak export edilir;
WebP desteği varsayılmaz. Sprite pivot, pixels-per-unit, filter ve Android texture
compression ayarları aynı hücre standardını korur.
Kullanılan bütün üçüncü taraf asset ve fontlar kaynak/lisans manifestine
kaydedilir.

### 12.14. Erişilebilirlik ve okunabilirlik

- High Contrast seçeneği board, objeler ve ışınlar arasındaki farkı artırır.
- Reduced Glow, blur ve dış parlamayı azaltır.
- Reduced Motion, parallax, shake, bounce ve yoğun partikülleri kapatır.
- Color Assist, her temel ve karışım renk için sabit sembol/şekil kullanır.
- Target durumu yalnızca renkle değil dolum, kenar ve ikonla gösterilir.
- Döndürülebilir ve sabit objeler yalnızca renk farkıyla ayrılmaz.
- UI metni sistem yazı ölçeğiyle büyüdüğünde board veya CTA üzerine taşmaz.
- HUD ve UI dokunma alanları en az 48 dp ve birbirinden yeterli mesafededir;
  grid objeleri hücreyle hizalı hitbox kullanır ve Compact cihazda ayrıca
  test edilir.
- Sesle verilen her kritik bilgi görsel karşılığa; haptic bilgi de görsel veya
  ses karşılığa sahiptir.
- Titreşim tamamen kapatılabilir.

### 12.15. UI metni ve yerelleştirme

İlk dil Türkçedir; fakat görünen bütün metinler baştan localization key
üzerinden çağrılır. UI metni kısa, eylem odaklı ve olumlu olur:

Marka sesi sakin, merak uyandıran ve cesaretlendiricidir. Ton; öğreticide
açıklayıcı, puzzle sırasında nötr, başarıda sıcak ve monetization durumunda
dürüst olur. Açıklık kelime oyunundan; yardım promosyondan önce gelir.

Terminoloji sözlüğü:

| Kavram | Oyuncuya gösterilen kelime | Kullanılmayacak alternatif |
|---|---|---|
| Level | Bölüm | Level, stage |
| Hint | İpucu | Help token |
| Mirror | Ayna | Reflector |
| Prism | Prizma | Splitter |
| Reset | Sıfırla | Restart puzzle |
| Theme | Tema | Skin pack |

CTA’lar fiille başlar ve sonucu söyler. Öğretici metinleri tek seferde tek
kavram anlatır; oyuncu açıklamayı geçebilir ve Ayarlar/Yardım içinden tekrar
açabilir.

- “Başla”, “Devam Et”, “Sonraki Bölüm”, “Tekrar Oyna”
- “Işık yolu henüz tamamlanmadı”
- “İpucu kullanmak ister misin?”
- “Bu aynayı işaretli yöne çevir”

Durum ve hata metinleri ne olduğunu ve oyuncunun ne yapabileceğini söyler:

- Offline mağaza: “Bağlantı yok. Oynamaya devam edebilirsin; mağaza sonra
  yenilenecek.”
- Rewarded reklam hazır değil: “Reklam şu anda hazır değil. Bölüme devam
  edebilirsin.”
- Restore başarılı: “Satın alımların geri yüklendi.”
- Restore sonucu boş: “Geri yüklenecek satın alma bulunamadı.”
- Kayıt kurtarılamadı: “Kayıt açılamadı. Yeni bir kayıtla devam ediyoruz.”

“Başarısız oldun”, suçlayıcı geri bildirim ve agresif satın alma dili
kullanılmaz. Monetization ürün açıklamaları entitlement davranışını tam ve
yanıltmayacak şekilde anlatır.

### 12.16. Presentation kabul kriterleri

- İlk giriş tutorial’ı açıklama metni ve pointer ile gerekli objeyi gösterir,
  oyuncu adına hamle yapmaz ve gerçek dokunuşla ilerler.
- Startup stinger Splash/logo reveal ile senkronlanır, bir kez çalar ve
  sahne yenilemesinde tekrar etmez.
- İlk kez oynayan kullanıcı ana menüde birincil eylemi yardım almadan bulur.
- Döndürülebilir objeler ilk bakışta sabit objelerden ayrılır.
- Kabul edilen her dokunuş en az bir görsel geri bildirim üretir.
- İpucu, Sıfırla ve Duraklat bütün desteklenen ekranlarda erişilebilir kalır.
- Background, beam veya target kontrastını hiçbir temada bozmaz.
- Reduced Glow/Motion ve High Contrast modlarında oyun tam oynanabilir kalır.
- Bölüm bitişi tatmin edici görünür fakat sonraki bölüme geçişi bir saniyeden
  fazla geciktirmez.
- Ses, haptic veya renk tek başına zorunlu bilgi kanalı değildir.

## 13. Ekran Envanteri, Uygulama Durumları ve Hata Akışları

### 13.1. Ekran envanteri

| Ekran/overlay | Sorumluluk | Ana eylem |
|---|---|---|
| Boot/Splash | Yerel save/settings yükleme, platform servislerini başlatma, startup stinger ve logo reveal | Ana menüye geç |
| Main Menu | Devam etme, yeni oyun, ikincil girişler | Başla / Devam Et |
| Level Select | Açık, kilitli ve tamamlanmış bölümleri gösterme | Bölümü Aç |
| Game | Board, HUD, tutorial ve gameplay | Objeyi Döndür |
| Pause Overlay | Oyunu durdurma, hızlı ses/titreşim ayarı | Devam Et |
| Result Overlay | Yıldız, hamle, süre ve sonraki geçiş | Sonraki Bölüm |
| Settings | Ses, titreşim, kalite ve erişilebilirlik | Ayarları Kaydet |
| Help/Tutorial | Mekanik açıklamaları ve eğitimi tekrarlama | Eğitimi Başlat |
| Themes/Store | Tema seçimi, ürün ve restore; yalnız monetized build | Temayı Seç / Satın Al |
| Privacy & Legal | Gizlilik, kullanım koşulları, consent seçenekleri, lisanslar | Belgeyi Gör / Tercihi Yönet |

Ayrı tam ekran Loading ekranı yalnız uzun işlemlerde kullanılır. Normal level
geçişinde mevcut background ve küçük branded progress göstergesi korunur;
kullanıcı siyah veya boş ekran görmez.

### 13.2. Uygulama state machine’i

`AppFlowController` ekran ve overlay geçişlerinin tek otoritesidir.
`GameSession` yalnız aktif bölümün gameplay state’ini yönetir.

~~~
BOOTING
  ↓
(AudioService startup stinger yalnızca bu oturumda bir kez tetiklenir.)

MENU
   ↓
LEVEL_LOADING
   ↓
TUTORIAL (yalnız gerekli olduğunda)
   ↓
PLAYING ↔ PAUSED
   ↓
COMPLETED
   ↓
RESULT
   ↓
TRANSITION → LEVEL_LOADING
~~~

Global geçişler:

~~~
Her state → BACKGROUNDED → save + audio pause
BACKGROUNDED → PAUSED veya önceki güvenli menü state’i
LEVEL_LOADING failure → RECOVERY
RECOVERY → Retry / Safe Level / Main Menu
~~~

State geçişleri idempotenttir. “Sonraki Bölüm” düğmesine iki kez basılması,
iki level yükleme veya iki interstitial isteği oluşturmaz.

### 13.3. Loading ve recovery davranışı

- Save ve settings yerelden yüklenirken Splash gösterilir; yapay minimum
  bekleme süresi eklenmez.
- Level yüklemesi 150 ms’yi aşarsa branded progress göstergesi açılır.
- Save yazma hatasında oyun memory state ile devam eder ve arka planda bir
  kez tekrar denenir.
- Ana save bozuksa backup denenir; ikisi de açılamazsa kullanıcıya açık
  mesaj gösterilip yeni kayıt oluşturulur.
- Generated level signature uyuşmazsa doğrulanmış emergency catalog entry
  yüklenir; hatalı board oyuncuya gösterilmez.
- Kritik olmayan görsel asset eksikse güvenli placeholder kullanılır ve
  gameplay devam eder.
- Core gameplay asset’i eksikse Main Menu’ye dönülür ve “Bölüm açılamadı.
  Tekrar dene.” eylemi gösterilir.
- Reklam hazır değilse, consent yoksa veya SDK hata verirse geçiş gecikmez.
- Billing/restore hatası mağaza içinde açıklanır; gameplay state değişmez.

### 13.4. Android geri tuşu ve uygulama yaşam döngüsü

- Main Menu’de geri tuşu “Oyundan çıkmak istiyor musun?” onayı açar.
- Level Select, Settings, Help ve Privacy ekranlarında geri tuşu önceki
  ekrana döner.
- Game sırasında geri tuşu Pause Overlay’i açar.
- Pause Overlay açıkken geri tuşu oyuna devam eder.
- Result Overlay açıkken geri tuşu Ana Menü’ye dönme onayı açar.
- Her modal/overlay önce kendisini kapatır; alttaki ekranı yanlışlıkla
  kapatmaz.
- OnApplicationPause(true)/OnApplicationFocus(false) tekilleştirilerek
  uygulama arka plana geçince son kabul edilen hamle atomik kaydedilir, timer
  durur, müzik/SFX askıya alınır.
- Uygulama geri geldiğinde aktif bölüm PAUSED açılır; kullanıcı onayı olmadan
  timer veya input başlamaz.

OnApplicationQuit tek save tetikleyicisi olamaz; mobil işletim sistemi bu
callback gelmeden süreci sonlandırabilir. Kabul edilen her hamle ve ayar değişimi
kaydın kaynağıdır. Back input'u AppFlowController'a yönlendirilir.

### 13.5. Input ve eşzamanlılık kuralları

- UI/overlay hit alanları board input’undan önceliklidir.
- İlk sürümde aynı anda yalnız bir board pointer’ı kabul edilir; ek multi-touch
  pointer’ları yok sayılır.
- LEVEL_LOADING, COMPLETED ve TRANSITION state’lerinde board input’u kapalıdır.
- PLAYING sırasında hızlı ardışık dokunuşlar sırayla modele uygulanır; view
  tween’i son orientation’a retarget eder.
- Tutorial sırasında yalnız beklenen gameplay komutu state değiştirebilir;
  Geri, Duraklat ve Atla her zaman çalışır.
- InputRouter ekran koordinatını yalnız `BoardLayout` üzerinden grid hücresine
  dönüştürür; view objeleri kendi hit hesabını ayrı yapmaz.

### 13.6. Privacy, legal ve lisans ekranları

Public monetized build şu yerel içerikleri uygulama içinde erişilebilir tutar:

- Gizlilik Politikası
- Kullanım Koşulları
- Consent/Gizlilik Tercihleri
- Satın Alımları Geri Yükle
- Açık kaynak ve font lisansları
- Uygulama sürümü ve generator version bilgisi

Bu metinler uygulamayla paketlenir ve internet olmadan açılabilir. Harici web
bağlantısı ek bilgi için kullanılabilir; temel legal içeriğin tek erişim yolu
olamaz. DynaPuff ve Noto Sans lisansları Lisanslar ekranında listelenir.

### 13.7. Ekran ve akış kabul kriterleri

- Her ekranda görünür bir birincil eylem ve geri dönüş yolu vardır.
- Hiçbir loading, modal, consent veya monetization durumu oyuncuyu çıkmazda
  bırakmaz.
- Main Menu’den ilk gameplay dokunuşuna kadar gereksiz ekran bulunmaz.
- Android geri tuşu her state için tanımlı davranışı uygular.
- Arka plan/geri dönüş aktif bölümü PAUSED ve kaydedilmiş halde bırakır.
- Level loading, save, asset, generator ve monetization hatalarının her biri
  güvenli bir fallback veya tekrar deneme eylemi sunar.
- Monetization kapalı build’de Store, Restore ve Consent girişleri görünmez.
- Privacy/legal/lisans içeriği offline açılır ve Noto Sans ile okunur.
