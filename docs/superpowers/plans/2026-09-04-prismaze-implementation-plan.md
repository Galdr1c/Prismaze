# Prismaze — Uygulama Planı

**Tarih:** 2026-09-04  
**Tasarım kaynağı:** `docs/superpowers/specs/2026-09-04-prismaze-godot-design.md`  
**Proje kökü:** `D:/Prismaze/prismaze-game/`  
**Durum:** Uygulama başlatılıyor; Godot editörü henüz kurulu değil

## 1. Uygulama hedefi

İlk teslim, Android portre ekranında çalışan 12 bölümlük optik puzzle dikey
dilimidir. Bu teslimde kaynak, ayna, hedef, duvar, renk maskesi, deterministik
RayTracer, reset, canonical hint, yerel kayıt ve ilk bölüm tutorial’ı
çalışır durumda olacaktır.

Monetization, endless seed kataloğu ve ileri efektler için arayüz sınırları
ilk aşamada korunur; gerçek entegrasyonları temel oynanış kabul kriterleri
geçmeden yapılmaz.

## 2. Sabit kararlar

- Godot 4.7.x kararlı sürümü ve tipli GDScript
- Compatibility renderer ve portre Android hedefi
- Mantıkta 6×12 integer grid; görselde bağımsız pixel dönüşümü
- `GameSession` gameplay state’in tek otoritesi
- Görsel view’lar model state’ini doğrudan değiştirmez
- El yapımı level’lar custom Resource; oyuncu save’i JSON/ConfigFile
- Generator solved-state → scramble → solver → difficulty validation akışı
- İlk bölümde bir kaynak, bir ayna ve bir hedef kullanan onboarding
- DynaPuff display fontu; Noto Sans uzun metin ve legal fallback’i
- İlk dikey dilimde network, ads, billing ve consent plugin’i kapalı

## 3. Proje iskeleti

~~~
prismaze-game/
├── project.godot
├── scenes/
│   ├── boot/boot.tscn
│   ├── menu/main_menu.tscn
│   └── game/game.tscn
├── scripts/
│   ├── core/
│   │   ├── models/
│   │   ├── logic/
│   │   └── determinism/
│   ├── levels/
│   │   ├── definitions/
│   │   ├── generator/
│   │   └── validation/
│   ├── game/
│   │   ├── session/
│   │   ├── input/
│   │   └── views/
│   ├── ui/tutorial/
│   ├── visual/
│   ├── platform/
│   └── tools/
├── data/levels/
├── data/catalogs/
├── assets/art/
├── assets/audio/
│   └── stingers/starting_sound.mp3
├── assets/fonts/
└── tests/
~~~

Kaynak dosyalar `D:/Prismaze/fonts/` ve
`D:/Prismaze/artifacts/audio/sfx/starting_sound.mp3` içinden proje asset
konumlarına yalnızca doğrulama sonrası kopyalanır. Kaynak asset klasörleri
release export’tan dışlanır.

## 4. Aşama 0 — Bootstrap

### İşler

1. Godot proje ayarlarını oluştur: isim, paket kimliği, portre yönü,
   Compatibility renderer ve temel viewport.
2. `Boot`, `MainMenu` ve `Game` sahnelerini oluştur.
3. `scripts/`, `data/`, `assets/` ve `tests/` dizinlerini oluştur.
4. DynaPuff dosyalarını ve startup stinger hedeflerini asset manifestine
   kaydet; lisans dosyaları için açık kaynak manifesti oluştur.
5. Debug APK export preset’ini tasarla; gerçek export Godot kurulumundan sonra
   çalıştırılacak.

### Kabul

- Proje editörde açılır.
- Uygulama portre açılır ve Boot → Main Menu geçer.
- DynaPuff Türkçe örnek metinlerle render edilir.
- Startup stinger asset’i bulunamazsa açılış çökmez.

## 5. Aşama 1 — Core modelleri ve renk mantığı

### TDD döngüsü

Önce her davranış için tek bir başarısız test yazılır, testin doğru nedenle
kaldığı gözlenir, sonra minimum GDScript uygulanır ve tüm testler tekrar
çalıştırılır.

### Sıra

1. `GridPosition`: eşitlik, hash, sınır, komşu ve yön adımı.
2. `Direction`: dört yön, dönüş ve karşı yön.
3. `LightColor`: RGB maskesi, additive mix ve exact target match.
4. `GameObjectState`: Source, Mirror, Prism, Target ve Wall verileri.
5. `LevelState`: başlangıç yönleri, aktif yönler, hamle sayısı ve elapsed time.

### Kabul

- Aynı model input’u her çalıştırmada aynı sonucu verir.
- Türkçe dışı platform API’sine veya Node sahnesine bağımlılık yoktur.
- Dört rotation sonrası rotatable obje başlangıç yönüne döner.

## 6. Aşama 2 — RayTracer ve WinChecker

### RayTracer sözleşmesi

- Ray state `(position, direction, color_mask)` taşır.
- `direction` ışının ilerleme yönüdür.
- `visited` anahtarı `(x, y, direction, color_mask)` içerir.
- Boş hücrelerde ışınlar karışmaz.
- Target rengi kaydeder ve ışını aynı yönde geçirir.
- Wall ışını durdurur.
- Yalnızca `white (RGB)` prism split eder; diğer maskeler değişmeden geçer.
- Döngü tespitinde ışın sonlandırılır; uygulama kilitlenmez.

### TDD test sırası

1. Source → Target düz ışın.
2. Dört mirror orientation yansıması.
3. Yanlış ayna girişi ve ışının sonlanması.
4. Wall occlusion.
5. Target pass-through ve exact mask.
6. Boş hücrede kesişen iki ışının birbirini etkilememesi.
7. White prism split; yellow/purple/cyan pass-through.
8. `(position, direction, color_mask)` tabanlı loop detection.
9. Birden çok target için `WinChecker`.

### Kabul

- Tanımlı bütün core testleri geçer.
- Görsel koordinat veya frame zamanı sonucu değiştirmez.
- 6×12 board’da bir trace frame bütçesini aşmaz.

## 7. Aşama 3 — LevelDefinition ve el yapımı içerik

1. Typed custom Resource sınıflarını oluştur.
2. `objects[]`, `canonical_solution[]`, `par_moves`, `tutorial_steps[]` ve
   `visual_theme` alanlarını tanımla.
3. İlk 12 level’ı dört öğretim grubuna göre oluştur:
   1–3 temel yol, 4–6 duvar/ayna, 7–9 renk hedefleri, 10–12 prizma.
4. Her level için canonical çözümü editor-time replay ile doğrula.
5. Level loader ve validation raporu oluştur.

### Kabul

- Her level’da en az bir çözüm vardır.
- Aynı hücrede iki nesne yoktur.
- Başlangıç state’i en az bir hamleyle çözülmemiştir.
- İlk level tek ayna dokunuşuyla çözülebilir.

## 8. Aşama 4 — GameSession, board ve input

1. `GameSession` level state’i yükler ve her hamlede yeni trace üretir.
2. `BoardLayout` mantıksal hücreyi viewport pixel’ına ve geri dönüştürür.
3. `InputRouter` UI önceliği, tutorial gating ve tek pointer kuralını uygular.
4. `MirrorView`, `PrismView`, `SourceView`, `TargetView` ve `WallView` yalnız
   görsel state gösterir.
5. Reset model state’ini level başlangıcına döndürür.
6. Bölüm tamamlanınca input kapanır ve Result Overlay açılır.

### Kabul

- Tap doğru grid hücresini hedefler.
- Hızlı ardışık tap’ler model ve view yönünü bozmaz.
- Back → Pause, Pause → Play, Result → Menu davranışları çalışır.
- Aynı Next tap’i iki level yüklemez.

## 9. Aşama 5 — İlk bölüm onboarding ve UI

1. `TutorialController` `tutorial_steps[]` okuyup overlay state’ini yönetir.
2. İlk adım kaynak/hedefi açıklar.
3. İkinci adım spotlight ve animasyonlu eli aynaya bağlar.
4. Oyuncunun gerçek tap’i gelmeden ayna otomatik döndürülmez.
5. Atla, kaldığı yerden devam ve Yardım’dan tekrar başlatma eklenir.
6. DynaPuff tipografi token’larını ve responsive HUD’u uygula.
7. `starting_sound.mp3` startup stinger’ını Boot/Logo reveal’e bağla.

### Kabul

- İlk kez oynayan 5 kullanıcıdan en az 4’ü ilk tap’i 15 saniyede yapar.
- Tutorial tamamlanınca tekrar otomatik açılmaz.
- Reduced Motion’da statik pointer ve metin görünür.
- Startup stinger yalnızca uygulama oturumunda bir kez çalar.

## 10. Aşama 6 — Görsel polish ve ses

1. Grid depth, shadow, beam core/glow ve reflection spark efektleri.
2. Low/Medium/High kalite seviyeleri.
3. Reduced Glow, Reduced Motion, High Contrast ve Color Assist.
4. Menü, sonuç ve panel geçişleri için motion token’ları.
5. DynaPuff + Noto Sans font fallback ve gerçek Türkçe metin QA.
6. Ses varyasyonları, cooldown ve BGM/SFX/stinger kanal ayrımı.

Bu aşamada efektler `TraceResult`’ı tüketir; gameplay kuralı üretmez.

## 11. Aşama 7 — Save ve offline-first platform

1. `SaveService` ile `user://save_v1.json` ve backup dosyası.
2. Her kabul edilen hamleden sonra atomik save.
3. Tutorial, level orientation, score ve settings kaydı.
4. Generated level için generator version, catalog key ve signature kaydı.
5. Bozuk save, eksik asset ve level signature recovery akışları.
6. Android lifecycle’da pause/resume ve back davranışı.

### Kabul

- Uçak modunda 12 level oynanır.
- Uygulama kapanıp açıldığında son kabul edilen hamle korunur.
- Bozuk save uygulamayı kilitlemez.

## 12. Aşama 8 — Solver, generator ve seed catalog

Bu aşama ilk dikey dilimden sonra yapılır.

1. `LayoutGenerator` template ve difficulty profile’dan topoloji üretir.
2. `SolvedBoardBuilder` geçerli ışık yolunu kurar ve canonical çözümü bilir.
3. `ScrambleService` başlangıç orientation’larını seed ile karıştırır.
4. BFS `Solver` shortest solution ve solution-count sinyalini üretir.
5. `DifficultyValidator` active/irrelevant object, beam, branch, cycle ve
   difficulty score metriklerini hesaplar.
6. Development tool 10.000 aday üretip doğrulanmış seed kataloğu çıkarır.
7. Runtime yalnız katalogdaki doğrulanmış seed’i kullanır; rastgele retry yok.
8. `generator_v1` signature’ı korunur; değişiklik `generator_v2` olur.

## 13. Aşama 9 — Monetization (opsiyonel yayın katmanı)

1. Android Godot v2 Gradle plugin adapter’larını ekle.
2. `AdPolicy`, `RewardService`, `ConsentService`, `PurchaseService`,
   `EntitlementService` ve `ProductCatalog` arayüzlerini bağla.
3. İlk 5 level interstitial kapalı; sonra en fazla 3 tamamlamada bir.
4. Gameplay banner/app-open yok; rewarded yalnız oyuncu isterse.
5. Reward yalnız `onUserEarnedReward` ile bir kez verilir.
6. `remove_ads` ve `premium_theme_pack` non-consumable ürünlerini sorgula.
7. Pending purchase entitlement olarak verilmez; restore idempotent olur.
8. UMP `canRequestAds()` kontrolü olmadan reklam istenmez.

## 14. Aşama 10 — Android QA ve yayın

1. Low/mid/high Android cihaz matrisi.
2. Compact/Standard/Large viewport ve safe-area testleri.
3. Core, level, save, tutorial, visual, audio ve monetization testleri.
4. Release keystore güvenliği ve AAB export.
5. Store listing, privacy/legal/licenses ve font/audio manifesti.
6. Google Play hedef API şartı yayın gününde yeniden kontrol edilir.

## 15. Uygulama kuralı

Her aşama kendi kabul kriterleri geçmeden sonraki aşamaya ilerlemez. Core
testleri geçmeden görsel polish yapılmaz; ilk dikey dilim Android’de çalışmadan
endless veya monetization yayın build’ine dahil edilmez. Her üretim kodu için
önce başarısız test gözlenir, sonra minimum implementasyon yapılır.
