# Prismaze

Android öncelikli, offline çalışan, 2D optik bulmaca oyunu.

## Geliştirme sırası

1. Core modelleri ve renk mantığı
2. RayTracer ve WinChecker
3. 12 el yapımı bölüm
4. GameSession, board ve dokunma
5. İlk bölüm onboarding
6. UI, 2.5D görsel sunum ve ses
7. Yerel kayıt ve Android QA
8. Solver, generator ve doğrulanmış seed kataloğu

Ana tasarım belgesi:

`../docs/superpowers/specs/2026-09-04-prismaze-godot-design.md`

Uygulama planı:

`../docs/superpowers/plans/2026-09-04-prismaze-implementation-plan.md`

## Kapsam

İlk dikey dilim tamamen çevrimdışı çalışır. Reklam, Google Play Billing ve
consent entegrasyonları daha sonra Android platform katmanı olarak eklenebilir;
Core ve GameSession bu servisleri bilmez.
