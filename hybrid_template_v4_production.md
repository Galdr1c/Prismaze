# Prismaze — Hybrid Template/Blueprint Sistemi v4 (Production-Ready, JSON + Build Pipeline)

Bu doküman, önceki iki taslağın (v2 playbook + v3 unique walls) üzerine; senin eklediğin **cross-platform determinism**, **component/ECS mimarisi**, **çok katmanlı validasyon**, **async generation + memory**, **telemetry/DDA**, **content pipeline**, **edge-case recovery** ve **render performans** ihtiyaçlarını tek bir production dokümanında birleştirir.

> Hedef: Episode 1–5 kampanya seviyeleri **0 çözümsüz**, **yüksek çeşitlilik**, **okunabilirlik** ve **düşük cihazlarda stabil performans**.

---

## 0) Hedefler ve “Done Definition”

### Kampanya (E1–E5)
- Üretim: **build-time bake** (CI/CD veya local build adımı)
- Runtime: sadece `load + render` (generator yok veya minimal)
- Episode başına 200 level:
  - **0 unsolved** (Solution Replay / Solvability validator)
  - **Unique signature ≥ %90**
  - Duvarlı level oranı:
    - E1: ≥ %30 (görsel çeşitlilik + öğretici koridor)
    - E2+: ≥ %60 (labirent/kanal kurgusu)
  - Ortalama “first-try solve time” (hedef):
    - İlk 20 level: 15–30 sn
    - E2+ orta: 30–75 sn

### Endless / E6+
- Runtime üretim mümkün
- Kabul kuralı: **strict acceptance**
  - Solvability fail → reject + fallback
  - Performance fail → simplify + retry

### Done Definition
- Bake çıktısı: `unsolvedCount == 0`
- CI smoke test: her episode’da 50 rastgele level replay çözümüyle solve olur
- Determinism test: aynı seed ile **iOS/Android/Web** aynı signature üretir
- Metrics raporu: unique ratio, walls ratio, family distribution, perf stats

---

## 1) Deterministik Seed ve Cross-Platform Consistency (Byte-for-Byte)

Cross-platform tutarlılık için “Random()” ve platform RNG’lerine güvenme. Aşağıdaki iki katman zorunlu:

1) **DeterministicRNG**: platformdan bağımsız PRNG
2) **Canonical serialization**: aynı veriyi aynı sırayla encode

### 1.1 DeterministicRNG (minstd_rand LCG)
Aşağıdaki LCG, 2^31−1 modülü ve 48271 çarpanı ile deterministiktir.  
Bu parametrelerde `_a * seed` ~ 1e14 bandında kaldığı için JS 53-bit güvenli integer aralığında **tam hassasiyetle** çalışır.

```dart
class DeterministicRNG {
  static const int _a = 48271;
  static const int _m = 2147483647; // 2^31 - 1

  int _seed;

  DeterministicRNG(this._seed) {
    if (_seed == 0) _seed = 1;
  }

  int nextInt(int max) {
    _seed = (_a * _seed) % _m;
    return _seed % max;
  }

  double nextDouble() {
    return nextInt(1000000) / 1000000.0;
  }

  List<T> shuffle<T>(List<T> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}
```

### 1.2 Global seed üretimi (FNV-1a benzeri)
Kampanya seed’i deterministik olmalı. “UserId” dahil edersen, **kişiye özel kampanya** olur; dahil etmezsen herkes aynı level’ı görür.

```dart
int generateGlobalSeed(int episode, int level, int userId) {
  final data = '$episode:$level:$userId';
  int hash = 0x811c9dc5;
  for (final byte in data.codeUnits) {
    hash ^= byte;
    hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24);
  }
  return hash.abs();
}
```

> Not: “byte-for-byte” hedefi için `codeUnits` (UTF-16) yeterince stabil; ama farklı normalizasyon/kültür farkı istemiyorsan input’u sadece ASCII yap (episode, level, userId sayısal zaten).

### 1.3 Canonical JSON ve determinism tuzakları
Aşağıdakiler determinism’i bozar:
- `Set`/`Map` iteration order’ına güvenmek
- JSON encode ederken Map key sırası değişmesi
- Floating point format farkları
- `DateTime.now()` veya platform state kullanımı

**Kurallar:**
- JSON yazarken **anahtarları sort et** (canonical JSON) veya binary encoding’e geç
- Listeleri her zaman deterministik sırada üret (ID’ye göre sort)
- `double` yerine mümkünse fixed-point int kullan (ör. opacity 0–1000)

---

## 2) Production-Ready Mimari (Data-Driven + Component/ECS)

### 2.1 Katmanlar
1) **Content** (YAML/Sheets/JSON)  
2) **Compiler** (build-time): doğrular, optimize eder, binary’ye çevirir  
3) **Runtime Loader**: templates.bin/json yükler  
4) **Generator**: selector → instantiate → validate → output  
5) **Bake Tool**: Episode 1–5’i offline üretir, assets’e yazar  
6) **Telemetry/DDA**: template ağırlıklarını günceller (opsiyonel)

### 2.2 Component-based Template (ECS benzeri)
Monolithic “layout” yerine composable component’ler: daha hızlı içerik üretimi, daha az kopya.

```dart
abstract class TemplateComponent {
  void instantiate(Map<String, dynamic> vars, LevelBuilder builder);
  List<TemplateConstraint> get constraints;
}
```

Örnek komponentler:
- `SourceComponent`
- `TargetComponent`
- `MirrorLayoutComponent`
- `PrismLayoutComponent`
- `WallObstacleComponent` (pattern tabanlı)
- `DecoyComponent`
- `VisualThemeComponent`

**Kural:** Component’ler sadece `LevelBuilder` üzerinden yazsın; builder occupancy ile çakışmayı erken yakalasın.

---

## 3) Template Library ve Selector (200 level’ı unique yapmanın çekirdeği)

### 3.1 Library yapısı
- Episode → Families → Variants (template)
- Her family:
  - `minDifficulty/maxDifficulty`
  - `tags`
  - `weight` (telemetry ile güncellenebilir)
  - `variants[]`

### 3.2 Selector v4 (deterministik, tekrar azaltan, fallback’li)
Önceki v2/v3 yaklaşımı + user’ın “20 level bucket” fikrini birlikte destekleyen selector:

**Seçim stratejisi:**
1) `targetDifficulty` hesapla
2) Family pool’u difficulty+tag ile filtrele
3) `bucket = levelIndex ~/ 20` (opsiyonel pacing)
4) Family seç: `hash(seed, episode, bucket)` → weighted pick
5) Variant seç: `hash(seed, episode, levelIndex, salt)`
6) Cooldown: son N template tekrarını engelle
7) `eligible==0/1` edge-case’lerinde safe fallback

> Weighted pick’i DDA ile besleyebilirsin (bölüm 9).

---

## 4) Duvar Sistemi (WallPattern + Segment DSL + CA opsiyonu)

### 4.1 Baseline: WallSegments DSL (JSON)
Duvarları hızlı yazmak için segment/preset tanımı:
- `vertical`
- `horizontal`
- `rect`
- `boxFrame`
- `corridor(left,right,y1..y2)` (opsiyonel)
- `polyline` (opsiyonel)

Runtime’da cell listesine expand:
- `expandSegments(segments) -> List<GridPosition>`

### 4.2 Pattern tabanlı komponent (corridor/maze/channel/frame/scattered)
```dart
enum WallPattern { corridor, maze, blocker, channel, frame, scattered, dynamic }
```

### 4.3 Dynamic (CA / cave generation) — dikkatli kullan
Cellular automata ile duvar üretimi **endless mode** veya özel episode’larda işe yarar; ama campaign’de okunabilirliği bozabilir.

Kritik güvenlik kuralları:
- Source/Target etrafında “safe zone carve” (en az 2–3 cell radius)
- Wall density üst limiti (örn. %35)
- Beam count / bounce count üst limiti

---

## 5) Variables & Instantiation (Zero-allocation ve çakışmasız üretim)

### 5.1 Variable generator (attempt + occupancy + retry limit)
- `maxAttempts` ile sonsuz döngüyü kes
- `attempt salt` ile farklı üretim dene
- Overlap kontrolü:
  - fixed objects
  - variable objects
  - wallVariants / dynamic walls

### 5.2 Instantiation: Stable ordering
Byte-for-byte için:
- Objeleri `id`’ye göre sort et
- Walls cell listesi `x,y` sıralı (lexicographic) yazılsın
- JSON serialization canonical olsun (key sort) veya binary encoding

---

## 6) Validation Pipeline (4 aşamalı, production-ready)

Template-based sistemde “solver” yerine **solution-path replay** kullan.

```dart
class ValidationPipeline {
  final List<Validator> validators = [
    GeometryValidator(),      // Çakışma, grid dışı, wall overlap
    SolvabilityValidator(),   // Solution path + partial sim (kritik)
    BalanceValidator(),       // Dead object, trivial, exploit
    PerformanceValidator(),   // Beam/ray sınırları, frame budget
  ];

  ValidationResult validate(GeneratedLevel level) {
    final errors = <ValidationError>[];
    for (final v in validators) {
      final r = v.validate(level);
      if (!r.isValid) {
        errors.addAll(r.errors);
        if (v.isCritical) break;
      }
    }
    return ValidationResult(errors);
  }
}
```

### 6.1 GeometryValidator (kritik)
- Bounds check
- Occupancy (collision)
- Wall-object overlap
- Safe zones (source/target çevresi)
- Segment expand sonrası tekrar kontrol

### 6.2 SolvabilityValidator (kritik, <1ms hedef)
- Template’te `solutionPath/solutionSteps` olmak zorunda
- Steps uygulanınca win condition true olmalı
- Light sim:
  - “partial simulate”: sadece solution path üzerinde (optimizasyon)
  - veya “full simulate” (küçük haritalarda)

### 6.3 BalanceValidator (warning/critical)
- Dead object oranı (örn. mirror’ların >%30’u kullanılmıyorsa uyarı)
- Trivial solution (par=1 ama kompleks layout)
- Symmetry exploit (kritik): aynı layout + simetrik çözüm → “şansla çözülüyor” hissi

### 6.4 PerformanceValidator (kritik)
- Ray count < limit (örn. 100)
- Max bounce < limit
- Frame-time tahmini (özellikle web)
- Shader/geometry budget

---

## 7) Par Moves Hesabı (Optimal / Player Feedback)

### 7.1 ParCalculator (scramble toplamı + synergy)
- Her scramble variable toplam hamle
- Synergy: bazı rotasyonlar aynı anda “etki” yaratıyorsa düzeltme

### 7.2 Player rating
- `efficiency = playerBest / parMoves`
- UI text: Perfect / Great / Good / Completed

---

## 8) Bake Pipeline (E1–E5) + QA

### 8.1 Bake adımları
1) templates (json/yaml) yükle
2) compile/validate templates (schema, limits)
3) `for levelIndex 1..200`:
   - seed = generateGlobalSeed(episode, levelIndex, userIdOr0)
   - selector → template
   - vars generate
   - instantiate
   - validate pipeline
   - serialize (canonical)
4) metrics raporu (json + human readable)

### 8.2 Signature / uniqueness
- signature = hash(source+targets+mirrors+prisms+walls+orientations)
- unique ratio < threshold → raporla ve fail et

---

## 9) Async Generation, Cache ve Memory (Runtime için)

Kampanya bake edilecekse runtime generator minimal kalır; ama endless veya “preview” için async şart.

### 9.1 LevelGenerationService
- LRU cache (son 50 level)
- Isolate worker pool
- Warm-up: sonraki 10 level prefetch

### 9.2 CompactLevel (RAM için)
- Bit packing ile binary encode
- hydrate/dehydrate ile oyun objesine dönüştür

> Not: Web’de isolate/compute davranışı farklı olabilir; worker destekli bir abstraction önerilir.

---

## 10) Telemetry ve DDA (Data-driven template weighting)

### 10.1 Neleri ölç?
- movesTaken
- timeMs
- usedHint
- resetCount
- churn signal (level bırakma, tekrar deneme sayısı)

### 10.2 Template “exhausted” (ezberlendi) tespiti
- Son 20 deneme: hepsi first-attempt ise weight düşür

### 10.3 SmartTemplateSelector (weighted)
- difficulty delta ile weight
- exhausted ise weight * 0.1
- churn rate ile weight azalt

> Bu sistem, **kampanya bake sonrası** “Next Season / Episode refresh” için çok değerli.

---

## 11) Localization & Content Pipeline (Sheets/YAML → JSON/Binary)

### 11.1 Öneri
- İçerik edit: Google Sheets veya YAML
- Build-time compile:
  - schema validate
  - limits validate
  - canonicalize
  - `templates.bin` üret

### 11.2 Neden binary?
- load hızlı
- canonical determinism kolay
- runtime allocation düşük

---

## 12) Edge Cases & Failure Recovery (Prod’da şart)

### 12.1 RobustGenerator
- ValidationException: seed+salt retry
- GeometryException: simpler template fallback
- Timeout: emergency level
- Unknown error: last resort

### 12.2 Sonsuz loop koruması
- recursion depth limit
- attempt limit
- fail reason telemetry

### 12.3 “Eligible=0” / “Eligible=1”
- `eligible=0`: tag/difficulty filtresi gevşet
- `eligible=1`: cooldown devreye giremez → wallVariant/anchorSwap çeşitliliğini yükselt

---

## 13) Rendering & Technical Art (Performans notları)

### 13.1 Walls: static batching / instancing
- Tek draw call için vertices birleştir
- Aynı texture/material

### 13.2 Light path: shader
- Gradient + alpha falloff
- Overdraw limit: beam thickness ve glow kontrollü

### 13.3 Okunabilirlik
- Beam crossing limit
- source çevresi temiz
- target buffer

---

## 14) Uygulama Checklist (Senin mevcut zip durumuna göre)

- [ ] Template havuzu episode başına **> 1 family** içeriyor mu?
- [ ] Difficulty filter candidates’i 1’e düşürüyor mu?
- [ ] Duvarlar JSON’a yazılıyor mu (`wallSegments` / `wallVariants`)?
- [ ] Instantiate duvarları output’a map ediyor mu?
- [ ] Seed mixing/DeterministicRNG kullanılıyor mu?
- [ ] Canonical serialization var mı?
- [ ] Validation pipeline V0–V3 çalışıyor mu?
- [ ] Bake metrics: unique ratio, walls ratio, fail reasons raporu var mı?

---

## Ek: Önceki Dokümanlardan Taşınan Parçalar
- v2: Validation katmanlarının ayrımı + offline bake yaklaşımı + readability
- v3: Selector/cooldown + wallSegments DSL + overlap/attempt limit + replay validator

## Kullanıcı Notları (Eklenecek İçerik Özeti)
- Deterministik RNG (minstd_rand LCG) ile iOS/Android/Web byte-for-byte tutarlılık
- Global seed üretimi (FNV-1a benzeri)
- Component-based template architecture (ECS benzeri)
- Validation pipeline: Geometry → Solvability (solution path + partial sim) → Balance → Performance
- Async generation + cache + isolate worker pool + CompactLevel binary encoding
- Par move hesabı (scramble toplamı + synergy düzeltmesi)
- Telemetry + DDA + Smart template selection (ağırlıklı seçim, exhaustion, churn)
- Localization + content pipeline (Sheets/YAML → build-time compile → assets/templates.bin)
- Edge-case ve failure recovery (retry, fallback, emergency levels)
- Rendering/performance notları (batching, shader)
