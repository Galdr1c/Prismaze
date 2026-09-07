# Prismaze Optics V2 — Prism Rules Tarzı Oynanış Uygulama Rehberi

**Tarih:** 2026-09-07  
**Motor:** Unity 6000.3.17f1, C#, URP 2D  
**Hedef:** Mevcut grid tabanlı prototipi sürekli optik sahneye taşıyarak
aynalar, prizmalar, mercekler ve splitter'larla ışık yönlendirme bulmacası
oluşturmak.

## 1. Referans deneyim ve sınır

Prism Rules kendi sitesinde aynalar, prizmalar, mercekler ve splitter'larla
ışınları yönlendirdiğini; yansıma, kırılma ve optik dağılım kullanan gerçek
zamanlı bir ışık tracer çalıştırdığını; beyaz ışığı tam renk spektrumuna
ayırdığını belirtiyor. [Prism Rules](https://www.prismrules.com/)

Prismaze bu deneyimden optik bulmaca fikrini ve okunabilir karanlık laboratuvar
sunumunu ilham olarak alır. Başka oyunun kodu, görselleri, sesleri, level
tasarımları veya marka dili kopyalanmaz. Optik motor ve içerik Prismaze için
özgün tasarlanır.

Mevcut Prismaze sistemi 6×12 integer grid, dört yön ve RGB maskeleri kullanır.
Bu sistem tutorial ve basit kampanya için korunabilir. Prism Rules tarzı ana
oynanış için yeni ve ayrı bir `OpticsV2` çekirdeği gerekir; eski `RayTracer`
doğrudan sürekli ışık sistemine dönüştürülmez.

## 2. Hedef oynanış modeli

Oyuncu karanlık bir optik sahnede ışık kaynağını, hedefleri ve optik parçaları
görür. Parçalar başlangıçta geçerli bir sahne içinde sabit noktalardadır.
Oyuncu önce seçili parçayı döndürür; sonraki sürümde parçalar sürüklenebilir.
Işık her değişiklikte yeniden izlenir ve hedeflerin doluluk durumu güncellenir.

İlk Optics V2 sürümü için kapsam:

- sürekli `Vector2` koordinatları;
- ışık kaynağı;
- düz ayna;
- üçgen prizma;
- basit yakınsak/ıraksak mercek;
- renk splitter;
- duvar ve optik hedef;
- 12 veya 16 sabit spektrum bandı;
- deterministic trace sonucu;
- dokunarak seçim ve 15°/30° yön ayarı;
- sabit konumlu, el yapımı level'lar.

Sürükle-bırak yerleştirme, serbest kamera yakınlaştırma ve runtime procedural
level üretimi ilk Optics V2 teslimine alınmaz. Bunlar tracer ve level formatı
stabil olduktan sonra eklenir.

## 3. Mimari sınır

Optik motor UnityEngine kullanmayan saf C# assembly içinde tutulur.

~~~text
Prismaze.Core
  └── OpticsV2
      ├── OpticalModels.cs
      ├── Geometry.cs
      ├── ContinuousRayTracer.cs
      ├── OpticalInteractions.cs
      └── OpticsSolver.cs             # daha sonraki aşama

Prismaze.Runtime
  ├── OpticalLevelDefinition.cs       # ScriptableObject adapter
  ├── OpticalBoardView.cs             # URP/UI mesh sunumu
  ├── OpticalInputRouter.cs
  ├── SpectrumRenderer.cs
  └── PrismazeApp.cs

Prismaze.Editor
  ├── OpticalLevelValidator.cs
  └── OpticalLevelPreviewWindow.cs
~~~

`ContinuousRayTracer` yalnız optik state alır ve `OpticsTraceResult` döndürür.
Board view ışınları çizer; kazanma kararı üretmez. `GameSession` mevcut grid
oyununun otoritesi olarak kalır, `OpticsSession` ise V2 sahneleri için ayrı
state yönetir. Böylece eski 12 bölüm ile yeni optik bölümler birbirine veri
sızdırmaz.

## 4. Optik veri modeli

### 4.1. RayPacket

Her ışın tek renk integer yerine bir enerji paketi taşır:

~~~csharp
[Serializable]
public struct RayPacket
{
    public Vector2 Origin;
    public Vector2 Direction;       // normalize edilmiş
    public Spectrum Spectrum;
    public float Energy;
    public int Depth;
    public string ParentId;
}
~~~

`Spectrum` başlangıçta 12 veya 16 örnek bandı içeren sabit boyutlu bir yapı
olur. Her bandın yaklaşık dalga boyu, renk karşılığı ve enerjisi bulunur.
Liste ve boxing kullanılmaz; mobil cihazda her trace için geçici allocation
oluşturulmaz.

### 4.2. OpticalElement

~~~csharp
public enum OpticalElementKind
{
    Emitter, Mirror, Prism, Lens, Splitter, Wall, Receiver
}

[Serializable]
public sealed class OpticalElement
{
    public string Id;
    public OpticalElementKind Kind;
    public Vector2 Position;
    public float Rotation;
    public Vector2 Size;
    public OpticalMaterial Material;
    public int RequiredBandMask;
}
~~~

Level asset'i `OpticalLevelDefinition : ScriptableObject` olarak saklanır.
Runtime session asset'i değiştirmez; mutable yönler ayrı kopyalanır.

### 4.3. Trace sonucu

~~~csharp
public sealed class OpticsTraceResult
{
    public readonly List<OpticalSegment> Segments;
    public readonly Dictionary<string, ReceiverState> Receivers;
    public bool Valid;
    public bool Solved;
    public bool LoopDetected;
    public int InteractionCount;
}
~~~

Segment yalnızca görsel çizim verisi taşır: başlangıç, bitiş, spektrum özeti,
enerji ve hangi elementte sonlandığı. Receiver state hedefin hangi bandı ne
kadar enerjiyle aldığı bilgisini tutar.

## 5. Sürekli ışın tracer algoritması

Her emitter için bir veya daha fazla `RayPacket` kuyruğa eklenir.
Tracer her adımda ray'ın önündeki en yakın optik yüzeyi bulur:

~~~text
ray kuyruğu
   ↓
en yakın yüzey kesişimini bul
   ↓
segment'i trace sonucuna ekle
   ↓
receiver / wall / mirror / prism / lens / splitter davranışını uygula
   ↓
yeni ray paketlerini kuyruğa ekle
   ↓
enerji, derinlik ve loop limitlerini kontrol et
~~~

Her ray için sabit limitler bulunur:

- maksimum etkileşim derinliği: başlangıçta 64;
- minimum enerji: başlangıçta `0.002`;
- minimum segment uzunluğu: başlangıçta `0.001`;
- aynı quantize edilmiş state'in tekrarında sonlandırma;
- toplam segment sayısı için güvenlik limiti.

Bu limitler sonsuz yansıma ve hatalı level durumunda oyunun donmasını önler.

### 5.1. Ayna

Düz ayna için gelen yön `d`, yüzey normali `n` ile yansır:

~~~text
r = d - 2 * dot(d, n) * n
~~~

Yansıyan enerji yüzey kaybıyla çarpılır. İlk sürümde ayna kusursuz ve tek
çıkışlıdır; daha sonra renk bantlarına göre materyal kaybı eklenebilir.

### 5.2. Prizma

Her spektrum bandı için farklı kırılma indisi kullanılır. İlk yaklaşık model
Cauchy eşitliğidir:

~~~text
n(λ) = A + B / λ²
~~~

Gelen ışın yüzeye çarptığında Snell yaklaşımı uygulanır:

~~~text
n₁ sin(θ₁) = n₂ sin(θ₂)
~~~

Tam fiziksel optik yerine mobil puzzle için kontrollü bir yaklaşım kullanılır:

- 12 band: oyun okunabilirliği ve performans için;
- 16 band: High kalite seçeneği;
- Low kalite: 3 RGB temsil bandı;
- enerji dağılımı korunur ve çok küçük renk farkları birleştirilir;
- total internal reflection durumunda ray prizma içinde yansıtılır.

Bu sayede oyuncu gökkuşağı etkisini görür; fakat her piksel için fiziksel
rendering yapılmaz.

### 5.3. Mercek

İlk mercek sürümü iki davranıştan birini seçer:

- yakınsak: ışınları odak noktasına yaklaştırır;
- ıraksak: ışınları merkezden uzaklaştırır.

Mercek geometrisi başlangıçta dairesel kesişim ve yüzey normaliyle yaklaşık
hesaplanır. Gerçek kamera merceği simülasyonu yapılmaz; puzzle kararlarını
okunabilir tutan deterministic açı sapması kullanılır.

### 5.4. Splitter

Splitter gelen paketi iki veya üç çıkışa böler. Enerji çıkışlar arasında
paylaştırılır. Splitter ile prizma aynı değildir:

- prizma: kırılma ve spektrum sapması;
- splitter: açıkça tanımlanmış çıkış kolları;
- ayna: tek yansıyan çıkış.

## 6. Geometri ve kesişim

İlk geometri seti Unity Physics2D raycast'i kullanmaz; core içinde deterministic
hesaplanır:

- emitter: nokta;
- mirror: sonlu line segment;
- wall: line segment veya rectangle;
- prism: convex triangle;
- lens: circle/arc;
- receiver: circle veya rectangle.

Her geometri türü şu arayüzü uygular:

~~~csharp
public interface IOpticalSurface
{
    bool Intersect(in RayPacket ray, out SurfaceHit hit);
    void Interact(in RayPacket ray, in SurfaceHit hit, TraceQueue output);
}
~~~

En yakın pozitif `t` seçilir. Eşit mesafelerde `OpticalElement.Id` ordinal
sıralaması kullanılır; aynı level farklı cihazlarda aynı sonucu üretir.

## 7. Loop ve deterministic davranış

Sürekli koordinatlar doğrudan hash'lenmez. Ray state şu şekilde quantize edilir:

~~~text
position = round(position * 1000)
direction = round(angleDegrees * 10)
band = spectrum band index
element = current surface id
~~~

`position + direction + band + element + depthBucket` anahtarı daha önce aynı
ray ancestry içinde görüldüyse ray kesilir. Farklı ray'ların aynı receiver'da
buluşması loop sayılmaz.

Level signature; element sırası, geometri parametreleri, materyal, başlangıç
yönleri ve çözüm hedeflerinden canonical binary serialization ile üretilir.
`System.Random` veya Unity global random kullanılmaz.

## 8. Unity sunumu

OpticalBoardView tam ekran koyu bir laboratuvar sahnesi oluşturur:

1. koyu gradient ve düşük opaklıklı ortam dekoru;
2. board contrast plate;
3. mesh tabanlı optik parçalar;
4. beam segment'leri;
5. düşük yoğunluklu bloom/glow;
6. hedef ve completion katmanı.

Beam için her segment tek bir kalın çizgi olarak çizilmez. En az üç katman
kullanılır:

- geniş düşük opaklık glow;
- orta genişlikte renk gövdesi;
- ince beyaz çekirdek.

Spectrum band'leri yakın renklerle gruplanır. Low kalite tek çizgi + küçük glow,
Medium 3 band grubu, High 12/16 band kullanır.

Oyun alanı serbest kamera pan/zoom yerine ilk sürümde ekran merkezli tutulur.
Mobilde puzzle objeleri minimum 48 dp hedef alanına sahip olur. Dokunma seçimi
şu sıradadır:

1. UI overlay;
2. seçilebilir optical element;
3. boş board.

İlk input sürümü:

- tek dokunma: elementi seç;
- sol/sağ rotate: 15° veya 30°;
- tekrar seçme: seçim halkasını göster;
- drag placement: Optics V2 beta sonrasına bırakılır.

## 9. Level tasarım süreci

Her yeni level şu aşamalardan geçer:

~~~text
OpticalLevelDefinition oluştur
       ↓
Emitter / receiver yerleştir
       ↓
Çözülebilir optik yol kur
       ↓
Parçaları başlangıç açılarına scramble et
       ↓
ContinuousRayTracer ile canonical çözümü doğrula
       ↓
En kısa çözüm ve etkileşim sayısını ölç
       ↓
Editor preview ile görsel kontrol
~~~

İlk 20 Optics V2 level için el yapımı içerik önerilir:

- 1–4: emitter + mirror + receiver;
- 5–8: iki ayna ve duvar;
- 9–12: prizma ile RGB/spektrum ayrılması;
- 13–16: splitter ve iki hedef;
- 17–20: mercek, odak ve renk kombinasyonu.

Bir level kabul edilmeden önce:

- en az bir geçerli çözüm;
- başlangıç durumunda çözülmemiş board;
- aynı açıların anlamsız tekrar etmemesi;
- kritik olmayan optik parçaların sınırlı tutulması;
- beam'in ekranda okunabilir olması;
- loop veya segment patlaması olmaması gerekir.

## 10. Mevcut Prismaze'den geçiş

Mevcut sistem silinmez. Geçiş sırası şöyledir:

1. `Prismaze.Core.OpticsV2` altında ray modelleri ve geometry testleri;
2. mirror reflection golden testleri;
3. prism refraction/dispersion testleri;
4. tek bir `OpticalLevelDefinition` ve `OpticsSession`;
5. `OpticalBoardView` ile bir prototip sahne;
6. mevcut UI shell içinde ayrı `OpticsV2` game mode;
7. 20 el yapımı level ve cihaz QA;
8. eski grid campaign'i tutorial/Classic içerik olarak konumlandırma;
9. Optics V2 için solver ve catalog üretimi.

Save schema yeni mode için `mode = optics_v2`, `levelId`, `signature` ve
element orientation/parameter değerleri ekler. Eski save dosyaları migration
olmadan bozulmaz; eski grid save'i eski session'a gider.

## 11. Performans ve mobil kalite

Optics V2 için hedefler:

- Low: 3 band, maksimum 24 interaction, 30 FPS düşük cihaz;
- Medium: 6 band, maksimum 48 interaction, 60 FPS orta cihaz;
- High: 12/16 band, maksimum 96 interaction, 60 FPS üst cihaz;
- tek hamlede yeniden trace 1 frame budget içinde;
- object pooling veya preallocated arrays;
- her frame yeni `List`, LINQ veya closure allocation'ı yok;
- beam mesh yalnız trace değişince güncellenir;
- glow ve particle kalite seviyesine göre azaltılır.

Profiler kabulü fiziksel cihazda yapılır. Masaüstü Unity Editor FPS'i mobil
performans kanıtı sayılmaz.

## 12. Test planı

### Core EditMode

- düz aynada yansıma;
- iki aynada yön zinciri;
- kırılma açısı ve total internal reflection;
- bandlara göre farklı prizma çıkışı;
- splitter enerji bölüşümü;
- receiver threshold;
- loop termination;
- determinism ve signature;
- invalid geometry.

### Unity PlayMode

- element seçim ve rotate;
- UI ile board input çakışmaması;
- tutorial gerçek dokunuşu beklemesi;
- completion/result/next;
- pause/resume ve save;
- 360×640, 412×915 ve tablet layout;
- Low/Medium/High kalite.

### Android cihaz

- uçak modunda campaign oynanışı;
- bağlantı geldiğinde consent ve test reklam fallback'i;
- Billing unavailable/pending davranışı;
- 10 dakika beam/SFX testi;
- process pause/resume;
- Android Back;
- 30/60 FPS ve GC allocation ölçümü.

## 13. Uygulama sırası ve kabul kapısı

İlk uygulanacak parça, mevcut oyunun tamamını değiştirmeyen küçük bir core
prototipidir:

1. `OpticalModels.cs`;
2. `Geometry.cs`;
3. `ContinuousRayTracer.cs`;
4. mirror + receiver golden testleri;
5. tek Unity preview level'i.

Bu beş parça geçmeden prism, lens, splitter ve yeni UI ana moda bağlanmaz.
Çünkü ışın temelinin yanlış olması üzerine içerik ve efekt inşa edilirse
sonradan bütün level'lar yeniden yazılır.

Optics V2 kabulü için:

- en az 20 el yapımı level;
- deterministic signature;
- bütün canonical çözümler geçer;
- cihazda 30/60 FPS hedefleri ölçülür;
- bağlantı yokken campaign oynanır;
- online servis hataları gameplay'i durdurmaz;
- eski grid save ve yeni Optics V2 save birbirine karışmaz.

Bu belge uygulama hedefidir; mevcut 6×12 grid sisteminin tamamlandığı anlamına
gelmez. Bir sonraki teknik adım ContinuousRayTracer için mirror/receiver
golden testlerini yazmaktır.
