import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/economy_manager.dart';
import '../../game/customization_manager.dart';
import '../../game/progress_manager.dart';
import '../../game/audio_manager.dart';
import '../../game/ad_manager.dart';
import '../../game/localization_manager.dart';
import '../../game/models/daily_reward.dart';
import '../../theme/app_theme.dart';

/// Daily Login Overlay with streak restore functionality
class DailyLoginOverlay extends StatefulWidget {
  final EconomyManager economyManager;
  final VoidCallback onClose;

  const DailyLoginOverlay({
    super.key,
    required this.economyManager,
    required this.onClose,
  });

  @override
  State<DailyLoginOverlay> createState() => _DailyLoginOverlayState();
}

class _DailyLoginOverlayState extends State<DailyLoginOverlay> {
  bool _claimed = false;
  bool _isRestoring = false;
  late int _currentDay;
  DailyReward? _claimedReward;
  
  // Track if streak was broken
  bool get _wasStreakBroken => widget.economyManager.wasStreakBroken;

  @override
  void initState() {
    super.initState();
    // Target day is the next day to claim
    _currentDay = widget.economyManager.dailyStreak + 1;
    if (_currentDay > 7) _currentDay = 1;
    
    // If streak is broken, user will see streak restore option first
  }

  Future<void> _handleClaim() async {
    AudioManager().playSfx('success.mp3');
    final reward = await widget.economyManager.claimDailyLoginReward();
    
    if (reward != null) {
      // Unlock special rewards if any
      if (reward.skinId != null || reward.particleEffectId != null || reward.backgroundId != null) {
        final pm = ProgressManager();
        await pm.init();
        final cm = CustomizationManager(pm);
        await cm.init();
        
        if (reward.skinId != null) await cm.unlockSkin(reward.skinId!);
        if (reward.particleEffectId != null) await cm.unlockSkin(reward.particleEffectId!);
        if (reward.backgroundId != null) await cm.unlockSkin(reward.backgroundId!);
      }
      
      setState(() {
        _claimed = true;
        _claimedReward = reward;
        _currentDay = reward.day;
      });
    }
    
    // Auto close after delay
    Future.delayed(const Duration(seconds: 2), widget.onClose);
  }

  Future<void> _restoreStreakWithTokens() async {
    if (widget.economyManager.tokens < StreakRestoreOption.tokenCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LocalizationManager().getString('not_enough_tokens'))),
      );
      return;
    }
    
    setState(() => _isRestoring = true);
    final success = await widget.economyManager.restoreStreakWithTokens();
    
    if (success) {
      AudioManager().playSfx('ding.mp3');
      setState(() {
        _currentDay = widget.economyManager.dailyStreak + 1;
        if (_currentDay > 7) _currentDay = 1;
        _isRestoring = false;
      });
    } else {
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _restoreStreakWithAd() async {
    setState(() => _isRestoring = true);
    
    final adManager = AdManager();
    final success = await adManager.showRewardedAd('streak_restore');
    
    if (success) {
      await widget.economyManager.restoreStreakWithAd();
      AudioManager().playSfx('ding.mp3');
      setState(() {
        _currentDay = widget.economyManager.dailyStreak + 1;
        if (_currentDay > 7) _currentDay = 1;
      });
    }
    
    setState(() => _isRestoring = false);
  }

  void _skipStreakRestore() {
    setState(() {
      _currentDay = 1; // Reset to day 1
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();
    
    // Show streak lost screen first if streak was broken
    if (_wasStreakBroken && !_claimed) {
      return _buildStreakLostOverlay(loc);
    }
    
    return _buildRewardOverlay(loc);
  }
  
  Widget _buildStreakLostOverlay(LocalizationManager loc) {
    final previousStreak = widget.economyManager.previousStreak;
    
    return Material(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Broken streak icon
              Icon(Icons.heart_broken, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              
              Text(
                loc.getString('streak_lost'),
                style: GoogleFonts.dynaPuff(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                '${loc.getString('previous_streak')}: $previousStreak ${loc.getString('days')}',
                style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              Text(
                loc.getString('restore_streak_question'),
                textAlign: TextAlign.center,
                style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              
              // Watch Ad button
              _buildRestoreButton(
                onTap: _restoreStreakWithAd,
                icon: Icons.play_circle_filled,
                label: loc.getString('watch_ad'),
                color: PrismazeTheme.accentCyan,
              ),
              const SizedBox(height: 12),
              
              // Spend tokens button
              _buildRestoreButton(
                onTap: _restoreStreakWithTokens,
                icon: Icons.lightbulb,
                label: '${StreakRestoreOption.tokenCost} ${loc.getString('tokens')}',
                color: PrismazeTheme.warningYellow,
              ),
              const SizedBox(height: 16),
              
              // Skip option
              TextButton(
                onPressed: _skipStreakRestore,
                child: Text(
                  loc.getString('start_new_streak'),
                  style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRestoreButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isRestoring ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: _isRestoring 
          ? Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: color, strokeWidth: 2)))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
      ),
    );
  }
  
  Widget _buildRewardOverlay(LocalizationManager loc) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.getString('daily_login_title'),
                style: GoogleFonts.dynaPuff(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                 loc.getString('daily_login_subtitle'),
                 textAlign: TextAlign.center,
                 style: GoogleFonts.dynaPuff(
                   color: Colors.white54,
                   fontSize: 14,
                 ),
              ),
              const SizedBox(height: 24),
              
              // Grid of 7 Days with new token values
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: 7,
                itemBuilder: (context, index) {
                   final day = index + 1;
                   final isTarget = day == _currentDay;
                   final isPast = day < _currentDay;
                   return _buildDayCard(day, isTarget, isPast);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Claim Button / Claimed State
              if (!_claimed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                    ),
                    child: Text(
                      loc.getString('btn_claim'),
                      style: GoogleFonts.dynaPuff(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                 Column(
                   children: [
                     const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
                     const SizedBox(height: 8),
                     Text(
                       loc.getString('msg_claimed'),
                       style: GoogleFonts.dynaPuff(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                     ),
                     if (_claimedReward?.hasSpecialReward == true) ...[
                       const SizedBox(height: 8),
                       Text(
                         '+ ${_claimedReward!.skinId != null ? loc.getString('skin_reward') : ''}'
                         '${_claimedReward!.particleEffectId != null ? ' ${loc.getString('effect_reward')}' : ''}'
                         '${_claimedReward!.backgroundId != null ? ' ${loc.getString('background_reward')}' : ''}',
                         style: GoogleFonts.dynaPuff(color: PrismazeTheme.accentPink, fontSize: 12),
                       ),
                     ],
                   ],
                 )
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDayCard(int day, bool isTarget, bool isPast) {
    // Use DailyReward model for token values
    final reward = DailyReward.getForDay(day);
    final tokens = reward.hintTokens;
    final isSpecial = reward.hasSpecialReward;
    
    Color bgColor = Colors.white10;
    Color borderColor = Colors.transparent;
    
    if (isPast) {
      bgColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
    } else if (isTarget) {
      bgColor = Colors.amber.withOpacity(0.2);
      borderColor = Colors.amber;
    } else if (isSpecial) {
      bgColor = Colors.purple.withOpacity(0.2);
      borderColor = Colors.purpleAccent.withOpacity(0.5);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: isTarget ? 2 : 1),
        boxShadow: isTarget ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Day $day",
            style: GoogleFonts.dynaPuff(
               color: Colors.white70,
               fontSize: 10,
               fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (isPast || _claimed && isTarget)
             const Icon(Icons.check, color: Colors.green, size: 24)
          else ...[
              // Icon
              if (day == 7)
                 const Icon(Icons.card_giftcard, color: Colors.purpleAccent, size: 20)
              else if (isSpecial)
                 Icon(Icons.star, color: PrismazeTheme.accentPink, size: 20)
              else
                 Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 20),
              
              const SizedBox(height: 2),
              Text(
                "$tokens",
                style: GoogleFonts.dynaPuff(
                   color: Colors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.bold,
                ),
              ),
          ]
        ],
      ),
    );
  }
}
