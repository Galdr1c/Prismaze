import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/settings_manager.dart';

/// Prismaze App Theme - Dynamic Accessibility Support
class PrismazeTheme {
  // === COLOR PALETTES ===
  
  // 0: Normal (Purple/Pink/Cyan)
  static const _normalPalette = {
    'primary': Color(0xFF8B5CF6),
    'primaryDark': Color(0xFF6D28D9),
    'primaryLight': Color(0xFFA78BFA),
    'accent': Color(0xFFEC4899),
    'accent2': Color(0xFF22D3EE),
    'success': Color(0xFF10B981),
    'error': Color(0xFFEF4444),
  };

  // 1: Deuteranopia (Blue/Yellow focus)
  static const _deuteranopiaPalette = {
    'primary': Color(0xFF3B82F6), // Blue
    'primaryDark': Color(0xFF1E40AF),
    'primaryLight': Color(0xFF60A5FA),
    'accent': Color(0xFFF59E0B), // Yellow/Orange
    'accent2': Color(0xFF9CA3AF), // Grey for balance
    'success': Color(0xFF3B82F6), // Use Blue for success
    'error': Color(0xFFD97706), // Use Dark Yellow for error
  };

  // 2: Protanopia (Teal/Orange focus)
  static const _protanopiaPalette = {
    'primary': Color(0xFF0D9488), // Teal
    'primaryDark': Color(0xFF0F766E),
    'primaryLight': Color(0xFF2DD4BF),
    'accent': Color(0xFFEA580C), // Orange
    'accent2': Color(0xFF0EA5E9), // Sky Blue
    'success': Color(0xFF0D9488),
    'error': Color(0xFFEA580C),
  };

  // 3: Tritanopia (Red/Cyan focus)
  static const _tritanopiaPalette = {
    'primary': Color(0xFFDC2626), // Red
    'primaryDark': Color(0xFF991B1B),
    'primaryLight': Color(0xFFF87171),
    'accent': Color(0xFF06B6D4), // Cyan
    'accent2': Color(0xFFEC4899), // Pink
    'success': Color(0xFF06B6D4),
    'error': Color(0xFFDC2626),
  };

  // === DYNAMIC STATIC ACCESSORS ===
  static SettingsManager get _sm => SettingsManager();

  static Color get primaryPurple => getPaletteColor(_sm.colorBlindIndex, 'primary');
  static Color get primaryPurpleDark => getPaletteColor(_sm.colorBlindIndex, 'primaryDark');
  static Color get primaryPurpleLight => getPaletteColor(_sm.colorBlindIndex, 'primaryLight');
  static Color get accentPink => getPaletteColor(_sm.colorBlindIndex, 'accent');
  static Color get accentCyan => getPaletteColor(_sm.colorBlindIndex, 'accent2');
  static Color get successGreen => getPaletteColor(_sm.colorBlindIndex, 'success');
  static Color get errorRed => getPaletteColor(_sm.colorBlindIndex, 'error');
  
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color starGold = Color(0xFFFFD700);

  // === BACKGROUNDS (Dynamic) ===
  static Color get backgroundDark => _sm.highContrastEnabled ? Colors.black : const Color(0xFF0F0A1F);
  static Color get backgroundCard => _sm.highContrastEnabled ? const Color(0xFF000000) : const Color(0xFF1A1033);
  static Color get backgroundOverlay => _sm.highContrastEnabled ? const Color(0xFF111111) : const Color(0xFF2D1B4E);
  
  static LinearGradient get backgroundGradient => _sm.highContrastEnabled 
      ? const LinearGradient(colors: [Colors.black, Colors.black])
      : const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A0A2E), Color(0xFF0F0A1F), Color(0xFF16082A)],
      );
  
  static LinearGradient get buttonGradient => _sm.highContrastEnabled
      ? LinearGradient(colors: [primaryPurple, primaryPurple]) // Solid color in high contrast
      : LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [primaryPurple, accentPink],
      );

  static LinearGradient get accentGradient => _sm.highContrastEnabled
      ? LinearGradient(colors: [accentCyan, accentCyan])
      : LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [accentCyan, primaryPurple],
      );

  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXL = 32.0;

  // Text Styles (Dynamic Colors)
  static TextStyle get headingMedium => GoogleFonts.dynaPuff(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get headingSmall => GoogleFonts.dynaPuff(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary);
  static TextStyle get bodyLarge => GoogleFonts.dynaPuff(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary);
  static TextStyle get bodyMedium => GoogleFonts.dynaPuff(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary);
  static TextStyle get bodySmall => GoogleFonts.dynaPuff(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted);

  // === TEXT COLORS (Dynamic) ===
  static Color get textPrimary => _sm.highContrastEnabled ? Colors.white : const Color(0xFFFFFFFF);
  static Color get textSecondary => _sm.highContrastEnabled ? Colors.white : const Color(0xFFB4A5D6);
  static Color get textMuted => _sm.highContrastEnabled ? Colors.white70 : const Color(0xFF6B5B8E);

  // === DYNAMIC THEME DATA ===
  static ThemeData getTheme(int mode, bool highContrast) {
    Map<String, Color> palette;
    switch (mode) {
      case 1: palette = _deuteranopiaPalette; break;
      case 2: palette = _protanopiaPalette; break;
      case 3: palette = _tritanopiaPalette; break;
      default: palette = _normalPalette;
    }

    final primary = palette['primary']!;
    final primaryDark = palette['primaryDark']!;
    final secondary = palette['accent']!;
    final tertiary = palette['accent2']!;
    
    // High Contrast Overrides
    final bgDark = highContrast ? Colors.black : backgroundDark;
    final bgCard = highContrast ? const Color(0xFF121212) : backgroundCard;
    final txtSec = highContrast ? Colors.white : textSecondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryDark,
        secondary: secondary,
        secondaryContainer: tertiary,
        surface: bgCard,
        error: palette['error']!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: bgDark,
      
      // Text Theme (DynaPuff)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.dynaPuff(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white),
        displayMedium: GoogleFonts.dynaPuff(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white),
        displaySmall: GoogleFonts.dynaPuff(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: GoogleFonts.dynaPuff(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.dynaPuff(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: GoogleFonts.dynaPuff(fontSize: 14, fontWeight: FontWeight.w400, color: txtSec),
        bodySmall: GoogleFonts.dynaPuff(fontSize: 12, fontWeight: FontWeight.w400, color: highContrast ? Colors.white70 : textMuted),
        labelLarge: GoogleFonts.dynaPuff(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: highContrast ? 0 : 8,
          side: highContrast ? const BorderSide(color: Colors.white, width: 2) : null,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
           side: highContrast ? BorderSide(color: Colors.white.withOpacity(0.5), width: 1) : BorderSide.none,
        ),
      ),

      iconTheme: IconThemeData(
        color: highContrast ? Colors.white : palette['primaryLight'],
        size: 24,
      ),
    );
  }

  // === HELPERS FOR CUSTOM WIDGETS (Not using context) ===
  static Color getPaletteColor(int mode, String key) {
     Map<String, Color> palette;
    switch (mode) {
      case 1: palette = _deuteranopiaPalette; break;
      case 2: palette = _protanopiaPalette; break;
      case 3: palette = _tritanopiaPalette; break;
      default: palette = _normalPalette;
    }
    return palette[key] ?? _normalPalette[key]!;
  }
  static List<BoxShadow> getShadow(Color color, {double opacity = 0.4, double blur = 20, double spread = 2}) {
     if (_sm.reducedGlowEnabled || _sm.highContrastEnabled) return [];
     return [
       BoxShadow(color: color.withOpacity(opacity), blurRadius: blur, spreadRadius: spread),
     ];
  }

  static List<BoxShadow> getGlow(Color primary, Color accent) {
     if (_sm.reducedGlowEnabled || _sm.highContrastEnabled) return [];
     return [
        BoxShadow(color: primary.withOpacity(0.45), blurRadius: 14, spreadRadius: 2),
        BoxShadow(color: accent.withOpacity(0.25), blurRadius: 18, spreadRadius: 4),
     ];
  }
}

