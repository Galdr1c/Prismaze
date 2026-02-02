# Prismaze — Template/Blueprint Sistemi v3 (JSON)
**Amaç:** “200 bölüm aynı çıkıyor” ve “duvar yok” problemlerini kökten çözmek; template’leri **Blueprint** gibi kullanıp her level’da **deterministik ama farklı** seçim + **seed bazlı varyasyon** + **duvar/pattern üretimi** + **ucuz validasyon** ile 200/200 unique kampanya üretmek.

Bu doküman, senin paylaştığın yaklaşımı (family rotate + seed-based variables + wall patterns) **prod’da kırılmayacak şekilde** tamamlar ve birkaç kritik implementasyon tuzağını düzeltir.

---

## 1) Kök problemler (Semptom → Sebep → Fix)

### 1.1 “200 level aynı” → Template seçimi her seferinde aynı / candidates=1
**Sebep A:** `episodeTemplates.first` gibi sabit seçim  
**Sebep B:** Filtre sonrası `eligible.length == 1` (min/maxDifficulty, tag, vb.)  
**Fix:**  
- Template’leri **family** bazında grupla  
- Family/Template seçiminde **hash + cooldown** kullan  
- `eligible` boş veya 1’e düşerse **fallback chain** devreye girsin (aşağıda var)

### 1.2 “Duvar yok” → Template JSON’da walls/wallSegments hiç yok veya instantiate map etmiyor
**Fix:**
- Template JSON’a `wallSegments` ekle (segment DSL ile yazması kolay)
- Instantiate aşamasında `wallSegments -> walls(cell list)` map et
- Bake raporunda `wallsCount` metrikle (Episode 1: %30+, Episode 2+: %60+)

### 1.3 “Seed var ama yine aynı” → Seed mixing yok
**Fix:** `seed = mixSeed(baseSeed, episode, levelIndex, salt)` (deterministik ve farklı)

---

## 2) Zorunlu yapı: Template = Blueprint, Episode = Library, Level = Instance

### 2.1 Library modeli
- **TemplateFamily**: bir “puzzle fikri” ailesi (corridor, L-turn, zigzag…)
- **TemplateVariant**: aynı fikrin farklı base yerleşimi (2–4 adet yeter)
- **Variables**: her variant içinde seed ile üretilen parametreler (rotasyon, jitter, wallVariant, anchorSwap)

> Önemli: “200 level için 200 template” yazmak zorunda değilsin.  
> 8 family × 3 variant × (seed varyasyonu) ile 200+ unique çıkar.

---

## 3) Deterministik seçim algoritması (Family → Variant → Variables)

Senin verdiğin yaklaşım doğru yön: “her 20 level’da family değiştir, içinde varyasyon var”.  
Ama prod’da şu 3 tuzağı düzeltmek gerekiyor:

1) `eligible.length` 0 olursa crash  
2) `eligible.length` 1 olursa 200 kopya hissi artar  
3) Variant seçiminde `levelIndex % variants.length` yine döngü pattern’i verir

### 3.1 Seed mixing (şart)
```dart
int mixSeed(int baseSeed, int episode, int levelIndex, [int salt = 0]) {
  int x = baseSeed ^ (episode * 0x9E3779B9) ^ (levelIndex * 0x85EBCA6B) ^ (salt * 0xC2B2AE35);
  x ^= (x >> 16);
  x *= 0x7feb352d;
  x ^= (x >> 15);
  x *= 0x846ca68b;
  x ^= (x >> 16);
  return x & 0x7fffffff;
}
```

### 3.2 Selector v3 (cooldown + deterministic hashing)
```dart
class TemplateSelector {
  final int cooldown = 6;
  final List<String> recentTemplateIds = [];

  LevelTemplate select({
    required int baseSeed,
    required int episode,
    required int levelIndex,
    required List<TemplateFamily> families,
    required int difficulty,
    List<String> requiredTags = const [],
  }) {
    // 1) Zorluk + tag filtre
    var eligible = families.where((f) =>
      f.minDifficulty <= difficulty &&
      f.maxDifficulty >= difficulty &&
      requiredTags.every(f.tags.contains)
    ).toList();

    // 2) Fallback: tag/difficulty aşırı daralttıysa
    if (eligible.isEmpty) {
      eligible = families.where((f) =>
        f.minDifficulty <= difficulty && f.maxDifficulty >= difficulty
      ).toList();
    }
    if (eligible.isEmpty) eligible = families; // son çare

    // 3) Family seçimi: deterministik hash
    final seed = mixSeed(baseSeed, episode, levelIndex, 100);
    final family = eligible[seed % eligible.length];

    // 4) Variant seçimi: yine hash ama salt farklı
    final vSeed = mixSeed(baseSeed, episode, levelIndex, 200);
    final variants = family.variants;
    var variant = variants[vSeed % variants.length];

    // 5) Template cooldown (tekrar hissini azaltır)
    int salt = 0;
    while (recentTemplateIds.contains(variant.id) && salt < 8) {
      salt++;
      final altSeed = mixSeed(baseSeed, episode, levelIndex, 201 + salt);
      variant = variants[altSeed % variants.length];
    }

    recentTemplateIds.add(variant.id);
    if (recentTemplateIds.length > cooldown) recentTemplateIds.removeAt(0);
    return variant;
  }
}
```

> Not: Eğer “her 20 level’da family değişsin” kuralını **özellikle** istiyorsan:
- `bucket = (levelIndex ~/ 20)`
- `familyIdx = hash(baseSeed, episode, bucket)`
- `family = eligible[familyIdx]`
- bucket içinde variant/variables seed ile akar

---

## 4) Duvar üretimi: WallPattern + Segment DSL (JSON)

Duvarı “tek tek cell” yazmak zor ve hataya açık.  
Çözüm: JSON’da **segment/preset** tanımla, runtime’da cell listesine expand et.

### 4.1 WallPattern enum (kapsayıcı)
- `corridor` (kenarlarda duvar, ortada yol)
- `maze` (L/zigzag bloklar)
- `blocker` (kritik noktada tek blok)
- `channel` (ışını tek yöne zorlar)
- `frame` (çerçeve)
- `scattered` (decoy/dağınık)

### 4.2 JSON WallSegment
```json
"wallSegments": [
  {"type":"vertical", "x":5, "y1":1, "y2":5},
  {"type":"horizontal", "y":3, "x1":6, "x2":11},
  {"type":"rect", "x":2, "y":1, "w":3, "h":2},
  {"type":"boxFrame", "x1":8, "y1":1, "x2":12, "y2":5}
]
```

### 4.3 “WallVariants” (seed ile seçilen preset)
```json
"variables": [
  {"name":"wv","type":"choice","choices":[0,1,2]}
],
"wallVariants": [
  [{"type":"vertical","x":4,"y1":1,"y2":5}],
  [{"type":"horizontal","y":3,"x1":2,"x2":5}],
  [{"type":"boxFrame","x1":7,"y1":1,"x2":12,"y2":5}]
]
```

Instantiate:
- `wv` seç → `wallVariants[wv]` ekle

---

## 5) Variable generator (seed bazlı, çakışmasız, retry limitli)

Senin “seed + 999 recursion” fikri pratik; ama prod’da:
- Sonsuz recursion riskini kesmek gerekir
- Çakışmayı en başta occupancy ile çözmek daha hızlıdır

### 5.1 Güvenli generator
```dart
class VariableGenerator {
  Map<String, dynamic> generate(LevelTemplate template, int seed, {int maxAttempts = 12}) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final s = mixSeed(seed, 0, 0, attempt); // attempt salt
      final rng = Random(s);
      final vars = <String, dynamic>{};

      for (final def in template.variables) {
        switch (def.type) {
          case VariableType.scramble:
          case VariableType.integer:
            vars[def.name] = def.minValue + rng.nextInt(def.maxValue - def.minValue + 1);
            break;
          case VariableType.boolean:
            vars[def.name] = rng.nextBool();
            break;
          case VariableType.choice:
            vars[def.name] = def.choices[rng.nextInt(def.choices.length)];
            break;
        }
      }

      if (_validateNoOverlap(template, vars) && _validateCustom(template, vars)) {
        return vars;
      }
    }
    return template.safeDefaults ?? <String, dynamic>{};
  }

  bool _validateNoOverlap(LevelTemplate template, Map<String, dynamic> vars) {
    final used = <GridPosition>{};

    // fixed objects
    for (final o in template.fixedObjects) {
      if (!used.add(o.position)) return false;
    }

    // variable objects
    for (final o in template.variableObjects) {
      final pos = o.evalPosition(vars);
      if (!used.add(pos)) return false;
    }

    // wallVariants expand
    final extraWalls = template.evalWallVariants(vars);
    for (final w in extraWalls) {
      if (!used.add(w)) return false;
    }

    return true;
  }

  bool _validateCustom(LevelTemplate template, Map<String, dynamic> vars) {
    if (template.customValidator == null) return true;
    return template.customValidator!(template, vars);
  }
}
```

---

## 6) “Çözümsüz level” riskini bitiren ucuz garanti: Solution Replay Validator

**Ağır solver yok.**  
Ama template çözümlü kalmalı: “scrambled başlangıç → çözüm adımları uygulanınca solved” doğrulanmalı.

**V2 validator:**
1) Template instantiate → initial state
2) `solutionSteps` uygula
3) Ray-trace / win condition ile `solved == true` kontrol et

> Bu, BFS/solver gibi state-space büyütmez; 10–40 step replay çok ucuzdur.

---

## 7) Episode 1 içerik planı (duvarlı + okunabilir + 200 unique)

### 7.1 Family seti (E1)
- `corridor` (okunabilir, duvarın faydasını hissettirir)
- `L_turn` (köşe döndürme)
- `zigzag` (engeller arası)
- `bounce_back` (geri yansıtma fikri)
- `decoy_wall` (yanıltıcı ama çözümü bozmayan)

### 7.2 Üretilebilir hedef (E1 = 200)
- 8 family × 3 variant × seed varyasyon = 200+ unique
- Duvarlı level oranı: **%30–50**
- İlk 20 level: tek fikir, düşük clutter

---

## 8) JSON örnekleri (E1) — “Duvarlı ama basit”

### 8.1 Corridor Template (variant 1)
```json
{
  "id": "E1_CORRIDOR_A",
  "family": "corridor",
  "minDifficulty": 1,
  "maxDifficulty": 3,
  "tags": ["clean","tutorial"],
  "layout": {
    "playArea": {"width": 14, "height": 7},
    "source": {"x": 1, "y": 3, "dir": "east"},
    "targets": [{"id":"T0","x": 13, "y": 3, "color":"white"}],
    "mirrors": [
      {"id":"M0","x": 6, "y": 3, "ori": 1, "rotatable": true}
    ],
    "wallSegments": [
      {"type":"horizontal","y":1,"x1":2,"x2":12},
      {"type":"horizontal","y":5,"x1":2,"x2":12}
    ]
  },
  "variables": [
    {"name":"m0x","type":"integer","min":4,"max":10},
    {"name":"s0","type":"scramble","min":1,"max":3},
    {"name":"wv","type":"choice","choices":[0,1]}
  ],
  "variableObjects": [
    {"id":"M0","type":"mirror","x":"$m0x","y":"3","ori":"scramble(1,$s0)"}
  ],
  "wallVariants": [
    [{"type":"rect","x":8,"y":3,"w":1,"h":1}],
    [{"type":"rect","x":9,"y":3,"w":1,"h":1}]
  ],
  "solution": [
    {"type":"rotate","id":"M0","taps":1}
  ]
}
```

---

## 9) Bake (offline) — Kampanya üretim pipeline

### 9.1 Bake pseudo
- Episode templates.json yükle
- `for index in 1..200`:
  1) `difficulty = calcDifficulty(episode, index)`
  2) selector → template
  3) seed = mixSeed(baseSeed, episode, index)
  4) variables = generate(template, seed)
  5) instantiate
  6) validate V0–V2
  7) serialize level JSON

### 9.2 Metrics (mutlaka raporla)
- unique signature ratio
- walls ratio
- family distribution
- avg parMoves
- fail reasons

---

## 10) Readability (oyuncu gözü) — “Geçilebilir ama imkansız sanılan” levelleri engelle

Generator’a şu basit metrikleri ekle:
- beam crossing limit
- source çevresi “temiz alan” (ilk 3 cell)
- target çevresi buffer (1 cell)

Fail olursa:
- clutter azaltan wallVariant seç
- decoy sayısını düşür
- fallback clean family

---

## 11) En sık düşülen 6 hata (checklist)

- [ ] `eligible.isEmpty` check yok (crash)
- [ ] `eligible.length == 1` → 200 tekrar (fallback/cooldown yok)
- [ ] seed mixing yok (`Random(seed)` hep aynı)
- [ ] wallSegments JSON’da yok veya instantiate map etmiyor
- [ ] overlap validation yok (mirror ile wall aynı cell)
- [ ] solution replay validator yok (çözümsüz sızar)

---

## 12) Sonuç: Senin önerin doğru — ama prod için şu 3 ek şart zorunlu
1) **Selector v3:** hash + cooldown + fallback  
2) **WallSegments DSL:** duvar üretimini hızlandırır ve çeşitliliği arttırır  
3) **Solution Replay Validator:** solver olmadan %100 solvable garantisi
