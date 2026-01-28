import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/audio_manager.dart';
import '../../game/localization_manager.dart';
import '../../widgets/bouncing_button.dart';

/// Styled Back Button matching the game's theme.
/// Used across all screens for consistent navigation.
class StyledBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  
  const StyledBackButton({super.key, this.onTap});
  
  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();
    return BouncingButton(
      onTap: () {
        AudioManager().playSfxId(SfxId.uiClick);
        if (onTap != null) {
          onTap!();
        } else {
          Navigator.pop(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Min 44px height
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              loc.getString('btn_back'),
              style: GoogleFonts.dynaPuff(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

