<!--
PrisMaze Android Platform Features Setup Guide

## Adaptive Icons (API 26+)
Already configured in:
- res/mipmap-anydpi-v26/ic_launcher.xml
- res/values/colors.xml (background color)

Create foreground drawable at res/mipmap-xxxhdpi/ic_launcher_foreground.png

## Home Screen Widget
Requires native Kotlin/Java implementation.

1. Create widget layout: res/layout/prismaze_widget.xml
2. Create AppWidgetProvider class:

```kotlin
class PrismazeWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prismaze_widget)
            // Update widget content
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

3. Register in AndroidManifest.xml:
```xml
<receiver android:name=".PrismazeWidget" android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/prismaze_widget_info"/>
</receiver>
```

## Quick Settings Tile
Requires TileService implementation (API 24+).

## Samsung Edge Lighting
Requires Samsung Edge SDK integration.
See: https://developer.samsung.com/edge

## Bixby Routines
Register as supported action in AndroidManifest:
```xml
<intent-filter>
    <action android:name="com.samsung.android.bixby.service.Action.LAUNCH"/>
</intent-filter>
```
-->
