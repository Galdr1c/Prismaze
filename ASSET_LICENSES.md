# Prismaze Asset License Register

Unity runtime paths below were observed on 2026-09-06. Presence in the
repository does not establish redistribution rights or release clearance.

## Fonts

### DynaPuff

- Files: Assets/Resources/Fonts/DynaPuff-Regular.ttf,
  DynaPuff-Medium.ttf, DynaPuff-SemiBold.ttf, DynaPuff-Bold.ttf.
- Declared license: SIL Open Font License 1.1.
- Official source: [DynaPuff repository](https://github.com/googlefonts/dynapuff).
- Local source copies: fonts/; runtime copies are under Assets/Resources/Fonts/.
- Release gate: obtain and include the official OFL.txt and copyright notice
  matching the distributed font files, and expose notices offline in the app.
  A license file was not present in the inspected runtime font directory.
- Verify Turkish glyphs and any generated Unity/TextMeshPro font assets;
  generated atlases retain the source font's licensing requirements.

### Noto Sans (planned, not present)

- Intended use: long tutorial, settings, privacy and legal text.
- Official source: [Google Fonts Noto Sans](https://github.com/google/fonts/tree/main/ofl/notosans).
- Do not mark installed or cleared: acquire the needed Latin/Turkish files
  and their license/copyright notices before distribution.
- Configure explicit packaged fallback font assets; platform font fallback
  is not assumed to work automatically in Unity.

## Audio

| Runtime file | Intended use | Provenance / clearance status |
|---|---|---|
| Assets/Resources/Audio/stingers/starting_sound.mp3 | Startup/logo reveal, once per application session | Supplied project asset; source recorded as artifacts/audio/sfx/starting_sound.mp3; authorship and redistribution rights require confirmation |
| Assets/Resources/Audio/runtime/menu.mp3 | Offline menu music loop | Existing project asset migrated to Unity; original source/creator and redistribution rights not established here |
| Assets/Resources/Audio/runtime/gameplay.mp3 | Offline gameplay music loop | Existing project asset migrated to Unity; original source/creator and redistribution rights not established here |
| Assets/Resources/Audio/runtime/click.mp3 | UI press SFX | Existing project asset migrated to Unity; original source/creator and redistribution rights not established here |
| Assets/Resources/Audio/runtime/rotate.mp3 | Mirror/prism rotation SFX | Existing project asset migrated to Unity; original source/creator and redistribution rights not established here |
| Assets/Resources/Audio/runtime/complete.mp3 | Completion jingle | Existing project asset migrated to Unity; original source/creator and redistribution rights not established here |

Before release, record the creator/provider, original source, applicable license
or permission evidence, modification history and attribution obligations for
each audio file. Supplied assets must not be labeled original or royalty-free
without evidence. No audio rights were newly verified in this documentation pass.

## Packaging and future assets

Only required runtime exports belong in Unity Assets/Resources. Editable
sources remain outside Assets; .gdignore does not exclude files from Unity.
Review the player build report for unexpected resources and retained notices.
All new third-party art, icons, fonts, audio and package notices must be
registered before release. Privacy/legal/license content must remain accessible
offline; external links supplement the bundled notices.

See the [active Unity design](docs/superpowers/specs/2026-09-06-prismaze-unity-design.md)
for presentation requirements. Godot paths in archived documents are historical.
