import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'game/easter_egg_manager.dart';
import 'game/utils/platform_utils.dart';
import 'game/utils/security_utils.dart';
import 'theme/app_theme.dart';
import 'game/settings_manager.dart';
import 'game/privacy_manager.dart';

void main() async {
  print("=== PRISMAZE MAIN STARTED ===");
  WidgetsFlutterBinding.ensureInitialized();
  
  // Disable Google Fonts network fetching - use bundled fonts only
  // This prevents font errors when offline
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Force landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Enable fullscreen immersive mode
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  await EasterEggManager().init();
  
  // Init Settings Manager Globally
  final settingsManager = SettingsManager();
  await settingsManager.init();
  
  // Init Privacy Manager
  await PrivacyManager().init();

  runApp(
    ProviderScope(
      child: PrismazeApp(settingsManager: settingsManager),
    ),
  );
}

class PrismazeApp extends StatefulWidget {
  final SettingsManager settingsManager;
  const PrismazeApp({super.key, required this.settingsManager});

  @override
  State<PrismazeApp> createState() => _PrismazeAppState();
}

class _PrismazeAppState extends State<PrismazeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      PlatformUtils.detectDeviceType(size.shortestSide);
      PlatformUtils.configureForDevice();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to settings changes for dynamic theme
    return AnimatedBuilder(
      animation: widget.settingsManager,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PrismazeTheme.getTheme(
            widget.settingsManager.colorBlindIndex,
            widget.settingsManager.highContrastEnabled,
          ),
          builder: (context, child) {
            // Apply Big Text scaling
            final scale = widget.settingsManager.bigTextEnabled ? 1.5 : 1.0;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
