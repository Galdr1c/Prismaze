<!-- 
PrisMaze iOS Platform Features Setup Guide

## Haptic Engine (iPhone 7+)
Already implemented via Flutter's HapticFeedback API.
Uses Taptic Engine on supported devices automatically.

## 3D Touch (Deprecated)
iOS 13+ removed 3D Touch in favor of Haptic Touch.
No action needed - context menus work via long-press.

## Apple Pencil Support (iPad)
Flutter gestures work with Apple Pencil by default.
For pressure sensitivity, use the GestureDetector's PointerDownEvent.

## Siri Shortcuts Setup
Add to ios/Runner/Info.plist:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>com.prismaze.open</string>
    <string>com.prismaze.resume</string>
</array>
```

Then create ios/Runner/Shortcuts.swift:

```swift
import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}
```

And add SiriKit capability in Xcode:
1. Open ios/Runner.xcworkspace
2. Select Runner target > Signing & Capabilities
3. Add "Siri" capability
4. Create custom intents in IntentDefinition file

## Widget Setup (iOS 14+)
Requires creating a WidgetKit extension in Xcode.
See: https://developer.apple.com/documentation/widgetkit
-->
