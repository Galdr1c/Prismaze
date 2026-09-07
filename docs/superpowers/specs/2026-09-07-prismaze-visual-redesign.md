# Prismaze — Görsel Arayüz Yenileme Sözleşmesi

## Amaç

Mevcut teknik dikey dilimin okunabilirliğini ve oynanabilirliğini koruyarak
Prismaze'i koyu kristal laboratuvarı hissi veren, daha dengeli ve premium bir
mobil puzzle arayüzüne taşımak.

## Sabit kararlar

- Board her gameplay ekranının ana görsel odağıdır; ekranın kullanılabilir
  yüksekliğinin yaklaşık yarısından fazlasını alır.
- Ana menüde içerik genişliği 600 dp civarında sınırlanır; büyük ekranlarda
  butonlar kenarlara kadar uzamaz.
- DynaPuff logo, başlık ve kısa CTA metinlerinde kalır. Açıklama, HUD ve uzun
  metinler okunabilir sans-serif fallback kullanır.
- Butonlar 18–24 dp köşe yarıçapı, 56–72 dp yükseklik, belirgin pressed state,
  hafif iç kenar ve düşük yoğunluklu glow kullanır.
- Gameplay HUD üç katmandır: küçük üst bar, merkez board ve kompakt alt action
  tray. Sıfırla/İpucu/Atla dev paneller olarak çizilmez.
- Tutorial metni board'un altında tek bir açıklama kartında görünür; el ve
  spotlight board üzerindeki hedefte kalır.
- Level Select kartları iki sütunlu, ilerleme ve kilit durumu okunur bir yapıya
  sahip olur.
- Renk, glow ve gradient dekor olarak kalır; hedef, ayna ve beam kontrastı
  dekor tarafından bastırılmaz.

## Responsive hedefler

360×640, 360×800, 412×915 ve 1600×2560 fiziksel cihaz görünümünde:

- Ana CTA ilk bakışta görünür.
- Board ekranın ortasında büyütülmüş ve kesilmemiş görünür.
- HUD ve action tray güvenli alan içinde kalır.
- 48 dp minimum dokunma alanı korunur.
- Sistem metin ölçeği büyüdüğünde buton metni taşmaz.

## Doğrulama

Unity PlayMode akışları korunur. Yeni cihaz kontrolünde menü, tutorial, gerçek
ayna dokunuşu, sonuç, pause ve level selector ekranları görüntü olarak alınır.
