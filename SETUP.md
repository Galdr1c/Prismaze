# Prismaze — Yerel Geliştirme Kurulumu

## Mevcut durum

Hazır:

- Git
- Android Studio
- Android SDK Platform 36
- Android Build Tools 36.0.0
- Android Platform Tools 37.0.1
- Android Emulator ve Android 36 sistem imajları
- Microsoft OpenJDK 17
- Godot Engine 4.7.2 standard edition
- `ANDROID_HOME`, `ANDROID_SDK_ROOT` ve `JAVA_HOME`

Eksik:

- Android SDK NDK r28b (`28.1.13356709`)
- Android SDK CMake (`3.10.2.4988404`)

## Kurulum komutları

Godot:

~~~powershell
winget install --id GodotEngine.GodotEngine --exact
~~~

Android SDK:

~~~powershell
& "$env:ANDROID_SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" `
  --sdk_root="$env:ANDROID_SDK_ROOT" `
  "ndk;28.1.13356709" `
  "cmake;3.10.2.4988404"
~~~

Godot Android export ayarlarında Java SDK olarak JDK 17, Android SDK olarak
`ANDROID_SDK_ROOT` yolu seçilecek. İlk Android doğrulaması debug APK ile,
mağaza hazırlığı release AAB ile yapılacak.

## Asset kurulumu

Yeni Godot projesinde:

~~~text
D:/Prismaze/fonts/DynaPuff-*.ttf
  → res://assets/fonts/

D:/Prismaze/artifacts/audio/sfx/starting_sound.mp3
  → res://assets/audio/stingers/starting_sound.mp3
~~~

`source/` klasörleri runtime export’a dahil edilmez. Font ve ses lisans/kaynak
bilgileri release manifestinde tutulur.

## Doğrulama

Kurulumdan sonra:

~~~powershell
godot --version
& "$env:ANDROID_SDK_ROOT\cmdline-tools\latest\bin\sdkmanager.bat" --list_installed
git check-ignore -v .godot build artifacts
~~~

Godot kurulduğunda önce proje import edilir, ardından Core için RED testi
çalıştırılır. İlk RED/GREEN döngüsü Godot runtime’ında doğrulanmıştır; proje
köküne taşındıktan sonraki yeniden doğrulama kullanım limiti nedeniyle bekliyor.
iOS export daha sonra macOS ve Xcode bulunan bir makinede yapılır.
