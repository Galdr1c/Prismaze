import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/localization_manager.dart';
import '../../game/audio_manager.dart';
import '../../theme/app_theme.dart';

class AgeGateDialog extends StatefulWidget {
  const AgeGateDialog({super.key});

  @override
  State<AgeGateDialog> createState() => _AgeGateDialogState();
}

class _AgeGateDialogState extends State<AgeGateDialog> {
  int _selectedYear = DateTime.now().year - 10;
  final int _currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();
    final years = List.generate(100, (index) => _currentYear - index);

    return AlertDialog(
      backgroundColor: PrismazeTheme.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: PrismazeTheme.primaryPurple, width: 2),
      ),
      title: Column(
        children: [
          Icon(Icons.cake, color: PrismazeTheme.accentCyan, size: 40),
          const SizedBox(height: 12),
          Text(
            loc.getString('age_gate_title'),
            textAlign: TextAlign.center,
            style: GoogleFonts.dynaPuff(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            loc.getString('age_gate_body'),
            textAlign: TextAlign.center,
            style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PrismazeTheme.primaryPurple.withOpacity(0.5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedYear,
                dropdownColor: PrismazeTheme.backgroundCard,
                icon: Icon(Icons.arrow_drop_down, color: PrismazeTheme.accentCyan),
                style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 18),
                items: years.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYear = val);
                    AudioManager().playSfxId(SfxId.uiClick);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            AudioManager().playSfxId(SfxId.uiClick);
            final age = _currentYear - _selectedYear;
            final isAdult = age >= 13;
            Navigator.pop(context, isAdult);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: PrismazeTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            loc.getString('age_gate_continue'),
            style: GoogleFonts.dynaPuff(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

