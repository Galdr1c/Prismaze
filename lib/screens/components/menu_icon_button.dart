import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MenuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  
  const MenuIconButton({
    required this.icon, 
    required this.onTap, 
    super.key
  });
  
  @override
  Widget build(BuildContext context) {
      return GestureDetector(
          behavior: HitTestBehavior.opaque, // Ensure entire area is tappable
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.all(10), // 10 + 24 + 10 = 44px
              child: Icon(icon, color: PrismazeTheme.textSecondary, size: 24),
          ),
      );
  }
}
