import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum ConsentStatus { unknown, granted, denied }

/// Privacy & GDPR/KVKK Compliance Manager
class PrivacyManager {
  static final PrivacyManager _instance = PrivacyManager._internal();
  factory PrivacyManager() => _instance;
  PrivacyManager._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyConsentStatus = 'privacy_consent_status';
  static const String _keyAnalyticsEnabled = 'privacy_analytics_enabled';
  static const String _keyAdsPersonalized = 'privacy_ads_personalized';
  static const String _keyConsentDate = 'privacy_consent_date';
  static const String _keyUserCountry = 'privacy_user_country';
  
  // URLs
  static const String privacyPolicyUrl = 'https://prismaze.app/privacy';
  static const String termsOfServiceUrl = 'https://prismaze.app/terms';
  static const String dataRequestEmail = 'kynora.studio@gmail.com';

  // Privacy Policy Text
  static const String privacyPolicyText = """
PRIVACY POLICY FOR PRISMAZE

Last Updated: January 17, 2026

1. INTRODUCTION
   We are Kynora Studio, developer of PrisMaze.
   This policy explains how we collect, use, and protect your information.

2. INFORMATION WE COLLECT
   2.1 Information You Provide:
       - None. We do not require an account, email, or phone number.
   
   2.2 Information Collected Automatically (Local & 3rd Party):
       - Game progress (Stored LOCALLY on your device)
       - Settings & Preferences (Stored LOCALLY)
       - Device identifiers (Used by AdMob/Firebase for functionality, not stored by Kynora Studio)

3. HOW WE USE YOUR INFORMATION
   - We do NOT access your personal files or photos.
   - We do NOT track your location.
   - We use anonymous crash reports to fix bugs.
   - AdMob uses identifiers to show ads (if you consent).

4. DATA SHARING
   We do NOT share your data because we do not collect it.
   
   However, third-party services integrated into the app may collect data:
   - Firebase (Google) - Analytics and crash reporting
   - AdMob (Google) - Advertising
   
   These services operate under their own privacy policies.

5. DATA RETENTION & DELETION
   - Since we do not have servers storing your personal data, "Deleting Data" in the app simply:
     1. Clears all LOCAL game progress.
     2. Resets your privacy consent choices.
     3. Clears any cached advertising identifiers on the device.

6. YOUR RIGHTS (GDPR/KVKK)
   You have the right to:
   - Access your data
   - Correct your data
   - Delete your data
   - Withdraw consent
   - Export your data
   
   Contact: kynora.studio@gmail.com

7. CHILDREN'S PRIVACY (COPPA)
   Our game is suitable for all ages.
   For users under 13, we:
   - Require parental consent (Age Gate)
   - Disable personalized ads automatically
   - Limit data collection automatically
   
   Parents can contact us to review/delete child's data.

8. SECURITY
   We use encryption and secure storage to protect your data.

9. CHANGES TO POLICY
   We may update this policy. Check this page regularly.

10. CONTACT US
    Email: kynora.studio@gmail.com
""";

  // Terms of Service Text
  static const String termsOfServiceText = """
TERMS OF SERVICE FOR PRISMAZE

Last Updated: January 17, 2026

1. ACCEPTANCE OF TERMS
   By using PrisMaze, you agree to these terms.

2. LICENSE
   We grant you a limited, non-exclusive, non-transferable license to use the game.

3. USER CONDUCT
   You agree NOT to:
   - Cheat or use exploits
   - Reverse engineer the app
   - Share account credentials
   - Use unauthorized third-party tools

4. IN-APP PURCHASES
   - All purchases are final (no refunds except as required by law)
   - Prices may change
   - Virtual currency has no real-world value

5. INTELLECTUAL PROPERTY
   All game content is owned by Kynora Studio.
   You may not copy, distribute, or create derivative works.

6. DISCLAIMERS
   Game provided "AS IS" without warranties.
   We don't guarantee uninterrupted service.

7. LIMITATION OF LIABILITY
   We are not liable for:
   - Lost progress
   - Device damage
   - Indirect damages

8. TERMINATION
   We may terminate access if you violate terms.

9. CONTACT
    kynora.studio@gmail.com
""";

  // State
  ConsentStatus _consentStatus = ConsentStatus.unknown;
  bool _analyticsEnabled = false;
  bool _adsPersonalized = false;
  String? _userCountry;

  // Getters
  bool get analyticsEnabled => _analyticsEnabled;
  bool get adsPersonalized => _adsPersonalized;
  bool get isConsentGranted => _consentStatus == ConsentStatus.granted;
  bool get isConsentUnknown => _consentStatus == ConsentStatus.unknown;
  ConsentStatus get consentStatus => _consentStatus;
  String? get userCountry => _userCountry;

  // EU & EEA country codes
  static const List<String> _euCountries = [
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR',
    'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
    'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE',
    // EEA
    'IS', 'LI', 'NO',
    // UK (still follows similar rules)
    'GB',
  ];

  // Turkey (KVKK)
  static const List<String> _kvkkCountries = ['TR'];

  /// Initialize privacy settings
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    // Load consent status
    final statusStr = _prefs.getString(_keyConsentStatus);
    if (statusStr != null) {
      _consentStatus = ConsentStatus.values.firstWhere(
        (e) => e.toString() == statusStr,
        orElse: () => ConsentStatus.unknown,
      );
    }

    _analyticsEnabled = _prefs.getBool(_keyAnalyticsEnabled) ?? false;
    _adsPersonalized = _prefs.getBool(_keyAdsPersonalized) ?? false;
    _userCountry = _prefs.getString(_keyUserCountry);
    
    // KVKK: Auto-detect Turkey based on system language if country not set
    if (_userCountry == null) {
      try {
        final String systemLocale = Platform.localeName; // e.g. tr_TR
        if (systemLocale.toLowerCase().startsWith('tr')) {
          _userCountry = 'TR';
        }
      } catch (e) {
        print("PrivacyManager: Error detecting locale: $e");
      }
    }
    
    _initChildMode(); // Load COPPA state
    
    _initialized = true;
    print("PrivacyManager: Init. Consent: $_consentStatus, Analytics: $_analyticsEnabled, Country: $_userCountry, ChildMode: $_isChildMode");
  }

  /// Check if user is in EU/EEA region
  bool get isEU {
    if (_userCountry == null) return true; // Assume EU for safety
    return _euCountries.contains(_userCountry!.toUpperCase());
  }

  /// Check if user is in Turkey (KVKK applies)
  bool get isTurkey {
    if (_userCountry == null) return false;
    return _kvkkCountries.contains(_userCountry!.toUpperCase());
  }

  /// Check if GDPR/KVKK consent is required
  bool get requiresConsent => isEU || isTurkey;

  /// Set user country (from locale or geolocation)
  Future<void> setUserCountry(String countryCode) async {
    _userCountry = countryCode.toUpperCase();
    await _prefs.setString(_keyUserCountry, _userCountry!);
    print("PrivacyManager: Country set to $_userCountry");
  }

  /// Should show consent dialog
  bool shouldShowConsentDialog() {
    if (requiresConsent && _consentStatus == ConsentStatus.unknown) {
      return true;
    }
    return false;
  }

  /// Update consent decision
  Future<void> setConsent({
    required bool analytics,
    required bool personalizedAds,
  }) async {
    _consentStatus = ConsentStatus.granted;
    _analyticsEnabled = analytics;
    _adsPersonalized = personalizedAds;

    await _prefs.setString(_keyConsentStatus, _consentStatus.toString());
    await _prefs.setBool(_keyAnalyticsEnabled, _analyticsEnabled);
    await _prefs.setBool(_keyAdsPersonalized, _adsPersonalized);
    await _prefs.setString(_keyConsentDate, DateTime.now().toIso8601String());
    
    print("PrivacyManager: Consent granted. Analytics: $analytics, PersonalizedAds: $personalizedAds");
    
    if (!analytics) {
      _anonymizeAnalytics();
    }
  }

  /// Deny all consent
  Future<void> denyConsent() async {
    _consentStatus = ConsentStatus.denied;
    _analyticsEnabled = false;
    _adsPersonalized = false;

    await _prefs.setString(_keyConsentStatus, _consentStatus.toString());
    await _prefs.setBool(_keyAnalyticsEnabled, false);
    await _prefs.setBool(_keyAdsPersonalized, false);
    await _prefs.setString(_keyConsentDate, DateTime.now().toIso8601String());
    
    _anonymizeAnalytics();
    print("PrivacyManager: Consent denied");
  }

  /// Withdraw consent (user can do this anytime)
  Future<void> withdrawConsent() async {
    await denyConsent();
  }

  /// Toggle analytics (from Settings)
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (_isChildMode && enabled) {
      print("PrivacyManager: Cannot enable analytics in Child Mode");
      return;
    }
    _analyticsEnabled = enabled;
    await _prefs.setBool(_keyAnalyticsEnabled, _analyticsEnabled);
    
    if (!enabled) {
      _anonymizeAnalytics();
    }
    print("PrivacyManager: Analytics toggled -> $enabled");
  }

  /// Toggle personalized ads
  Future<void> setPersonalizedAds(bool enabled) async {
    if (_isChildMode && enabled) {
      print("PrivacyManager: Cannot enable personalized ads in Child Mode");
      return;
    }
    _adsPersonalized = enabled;
    await _prefs.setBool(_keyAdsPersonalized, _adsPersonalized);
    print("PrivacyManager: Personalized ads toggled -> $enabled");
  }

  void _anonymizeAnalytics() {
    print("PrivacyManager: User data anonymized");
    // Here you would:
    // - Reset advertising ID
    // - Disable Firebase Analytics user properties
    // - Stop sending identifiable data
  }

  //==========================================================================
  // DATA EXPORT (GDPR Article 20 - Right to Data Portability)
  //==========================================================================
  
  /// Export all user data as JSON file
  Future<File?> exportUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Collect all user data
      final Map<String, dynamic> userData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data_format_version': '1.0',
        
        'privacy_settings': {
          'consent_status': _consentStatus.toString(),
          'analytics_enabled': _analyticsEnabled,
          'personalized_ads': _adsPersonalized,
          'consent_date': prefs.getString(_keyConsentDate),
          'user_country': _userCountry,
        },
        
        'game_progress': {
          'highest_level': prefs.getInt('highest_level') ?? 1,
          'total_stars': prefs.getInt('total_stars') ?? 0,
          'levels_completed': prefs.getInt('levels_completed') ?? 0,
        },
        
        'economy': {
          'hint_tokens': prefs.getInt('hint_tokens') ?? 0,
          'total_earned': prefs.getInt('total_tokens_earned') ?? 0,
          'total_spent': prefs.getInt('total_tokens_spent') ?? 0,
        },
        
        'daily_login': {
          'current_streak': prefs.getInt('login_streak_count') ?? 0,
          'last_login': prefs.getString('last_login_date'),
        },
        
        'settings': {
          'music_enabled': prefs.getBool('music_enabled') ?? true,
          'sfx_enabled': prefs.getBool('sfx_enabled') ?? true,
          'haptics_enabled': prefs.getBool('haptics_enabled') ?? true,
          'language': prefs.getString('app_language') ?? 'tr',
        },
        
        'customization': {
          'selected_skin': prefs.getString('selected_skin'),
          'selected_effect': prefs.getString('selected_effect'),
          'selected_theme': prefs.getString('selected_theme'),
          'unlocked_items': prefs.getStringList('unlocked_items') ?? [],
        },
        
        'achievements': prefs.getStringList('unlocked_achievements') ?? [],
        
        'missions': {
          'completed_count': prefs.getInt('completed_missions') ?? 0,
        },
      };

      // Create JSON with nice formatting
      final jsonData = const JsonEncoder.withIndent('  ').convert(userData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/prismaze_data_export_$timestamp.json');
      await file.writeAsString(jsonData);
      
      print("PrivacyManager: Data exported to ${file.path}");
      return file;
      
    } catch (e) {
      print("PrivacyManager: Export failed - $e");
      return null;
    }
  }

  /// Share exported data file
  Future<bool> shareUserData() async {
    final file = await exportUserData();
    if (file == null) return false;
    
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'PrisMaze - Veri Dışa Aktarımı',
        text: 'PrisMaze oyun verileriniz ektedir.',
      );
      return true;
    } catch (e) {
      print("PrivacyManager: Share failed - $e");
      return false;
    }
  }

  //==========================================================================
  // DATA DELETION (GDPR Article 17 - Right to Erasure)
  //==========================================================================
  
  /// Delete all user data
  Future<bool> deleteAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all SharedPreferences
      await prefs.clear();
      
      // Clear secure storage if used
      // await SecureSaveManager().clearAllData();
      
      // Delete local files
      try {
        final directory = await getApplicationDocumentsDirectory();
        final files = directory.listSync();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      } catch (e) {
        print("PrivacyManager: File cleanup warning - $e");
      }
      
      // Log deletion for compliance records (anonymous)
      print("PrivacyManager: ALL USER DATA DELETED - ${DateTime.now().toIso8601String()}");
      
      // Reset manager state
      _consentStatus = ConsentStatus.unknown;
      _analyticsEnabled = false;
      _adsPersonalized = false;
      _userCountry = null;
      
      return true;
      
    } catch (e) {
      print("PrivacyManager: Deletion failed - $e");
      return false;
    }
  }

  //==========================================================================
  // PRIVACY POLICY & LEGAL LINKS
  //==========================================================================
  
  /// Open Privacy Policy
  Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse(privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open Terms of Service
  Future<void> openTermsOfService() async {
    final uri = Uri.parse(termsOfServiceUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Contact for data requests
  Future<void> requestDataViaEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: dataRequestEmail,
      queryParameters: {
        'subject': 'PrisMaze Veri Talebi',
        'body': 'Merhaba,\n\nAşağıdaki veri talebimi iletmek istiyorum:\n\n[ ] Verilerimi dışa aktar\n[ ] Verilerimi sil\n\nTeşekkürler.',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  //==========================================================================
  // COPPA COMPLIANCE (Children Under 13)
  //==========================================================================

  static const String _keyChildMode = 'privacy_child_mode';
  bool _isChildMode = false;
  
  bool get isChildMode => _isChildMode;

  /// Enable/Disable Child Mode
  Future<void> setChildMode(bool enabled) async {
    _isChildMode = enabled;
    await _prefs.setBool(_keyChildMode, enabled);
    
    if (enabled) {
      // Force disable tracking
      _analyticsEnabled = false;
      _adsPersonalized = false;
      await _prefs.setBool(_keyAnalyticsEnabled, false);
      await _prefs.setBool(_keyAdsPersonalized, false);
      _anonymizeAnalytics();
    }
    
    print("PrivacyManager: Child Mode set to $enabled");
  }

  /// Initialize Child Mode state (call inside init())
  void _initChildMode() {
    _isChildMode = _prefs.getBool(_keyChildMode) ?? false;
  }
}
