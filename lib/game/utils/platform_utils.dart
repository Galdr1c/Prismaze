import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Platform detection and feature utilities
class PlatformUtils {
  
  // --- Platform Detection ---
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isMobile => isIOS || isAndroid;
  
  // --- Device Type Detection ---
  static bool _isTablet = false;
  static bool get isTablet => _isTablet;
  static bool get isPhone => !_isTablet;
  
  /// Call this early in app startup with screen size
  static void detectDeviceType(double shortestSide) {
    // Tablets typically have shortest side >= 600dp
    _isTablet = shortestSide >= 600;
  }
  
  // --- iOS Specific ---
  static bool get hasHapticEngine => isIOS; // iPhone 7+ (Taptic Engine)
  static bool get supportsApplePencil => isIOS && _isTablet; // iPad only
  static bool get supports3DTouch => false; // Deprecated on iOS 13+
  
  // --- Android Specific ---
  static bool get supportsAdaptiveIcons => isAndroid; // API 26+
  static bool get isSamsungDevice => isAndroid && _checkSamsungManufacturer();
  
  static bool _checkSamsungManufacturer() {
    // Would need platform channel to get Build.MANUFACTURER
    // Stub: assume false
    return false;
  }
  
  // --- Orientation Support ---
  /// Force landscape orientation only (no exceptions)
  static Future<void> setLandscapeOnly() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  /// For all devices, force landscape mode
  static Future<void> configureForDevice() async {
    // Always force landscape - no tablet/phone exceptions
    await setLandscapeOnly();
  }
  
  // --- Keyboard Shortcuts (for external keyboards) ---
  static final Map<ShortcutActivator, VoidCallback> defaultShortcuts = {};
  
  static void registerShortcuts({
    VoidCallback? onRestart,
    VoidCallback? onHint,
    VoidCallback? onUndo,
    VoidCallback? onPause,
  }) {
    defaultShortcuts.clear();
    
    if (onRestart != null) {
      defaultShortcuts[const SingleActivator(LogicalKeyboardKey.keyR, control: true)] = onRestart;
    }
    if (onHint != null) {
      defaultShortcuts[const SingleActivator(LogicalKeyboardKey.keyH)] = onHint;
    }
    if (onUndo != null) {
      defaultShortcuts[const SingleActivator(LogicalKeyboardKey.keyZ, control: true)] = onUndo;
    }
    if (onPause != null) {
      defaultShortcuts[const SingleActivator(LogicalKeyboardKey.escape)] = onPause;
    }
  }
}

/// Responsive sizing helper
class ResponsiveLayout {
  final double screenWidth;
  final double screenHeight;
  
  ResponsiveLayout(this.screenWidth, this.screenHeight);
  
  bool get isLandscape => screenWidth > screenHeight;
  bool get isWideScreen => screenWidth >= 900;
  
  // Game area sizing
  double get gameAreaWidth {
    if (PlatformUtils.isTablet && isLandscape) {
      return screenHeight * 0.9; // Use height as reference for square-ish area
    }
    return screenWidth;
  }
  
  double get gameAreaHeight {
    if (PlatformUtils.isTablet && isLandscape) {
      return screenHeight * 0.9;
    }
    return screenHeight * 0.7; // Leave room for UI
  }
  
  // UI scaling
  double get uiScale {
    if (PlatformUtils.isTablet) return 1.25;
    return 1.0;
  }
  
  double scaledFontSize(double base) => base * uiScale;
  double scaledIconSize(double base) => base * uiScale;
  double scaledPadding(double base) => base * uiScale;
}
