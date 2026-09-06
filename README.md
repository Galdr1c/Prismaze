# Prismaze

Android öncelikli, offline, portre 2D optik bulmaca oyunu.
Aktif teknoloji: Unity 6.3 LTS, C#, URP 2D, ScriptableObject el yapımı
bölümler ve JSON yerel kayıt. iOS daha sonraki olası hedeftir.

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

Unity geçişi geliştirme aşamasındadır. Unity Editor henüz tespit edilmedi;
Unity import/derleme, EditMode/PlayMode ve Android APK/cihaz kabulü doğrulanmış
değildir. Saf C# test sonucu ayrıca raporlanır; Unity/Android doğrulaması yerine geçmez.
Kesin Editor pin'ini ana uygulama ProjectSettings/ProjectVersion.txt içinde seçer;
resmi doğrulanmış başlangıç adayı 6000.3.17f1'dir.

Dikey dilimden sonra solved-state → scramble → solver → difficulty validation
ile deterministik generator ve doğrulanmış seed kataloğu gelir. Runtime'da
solver araması veya rastgele retry yapılmaz. Reklam, billing, consent, backend
ve online hesap ilk dilime dahil değildir.

Godot kaynakları LegacyGodot/ altındadır; eski test/APK sonuçları yalnız
tarihsel kayıttır. PLAYER_PSYCHOLOGY_GUIDE.md eski fikir referansıdır; içindeki
tamamlanma ve ekonomi ifadeleri aktif Unity kapsamı sayılmaz.
