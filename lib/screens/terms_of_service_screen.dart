import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../game/privacy_manager.dart';
import '../game/audio_manager.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: PrismazeTheme.accentCyan),
                    onPressed: () {
                        AudioManager().playSfx('soft_button_click.mp3');
                        Navigator.pop(context);
                    },
                   ),
                   const SizedBox(width: 8),
                   Text(
                     "Terms of Service", 
                     style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                   ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    PrivacyManager.termsOfServiceText,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "© 2026 Kynora Studio",
                style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
