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

/// Daily Login Section widget for DailyQuestsScreen
class DailyLoginSection extends StatefulWidget {
  final EconomyManager economyManager;

  const DailyLoginSection({
    super.key,
    required this.economyManager,
  });

  @override
  State<DailyLoginSection> createState() => _DailyLoginSectionState();
}

class _DailyLoginSectionState extends State<DailyLoginSection> {
  bool _claimed = false;
  bool _isRestoring = false;
  bool _skippedRestore = false; // Track if user skipped streak restore
  DailyReward? _claimedReward;

  int get _currentDay {
    final streak = widget.economyManager.dailyStreak;
    final canClaim = widget.economyManager.canClaimDailyLogin;
    int day = canClaim ? streak + 1 : streak;
    if (day > 7) day = 1;
    if (day < 1) day = 1;
    return day;
  }

  bool get _wasStreakBroken => widget.economyManager.wasStreakBroken;
  bool get _canClaim => widget.economyManager.canClaimDailyLogin && !_claimed;

  Future<void> _handleClaim() async {
    if (!_canClaim) return;
    
    AudioManager().playSfxId(SfxId.achievementUnlocked);
    final reward = await widget.economyManager.claimDailyLoginReward();
    
    if (reward != null) {
      // Note: Special rewards (skins, etc.) are unlocked by EconomyManager automatically
      // No need to recreate managers here
      
      setState(() {
        _claimed = true;
        _claimedReward = reward;
      });
    }
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
      AudioManager().playSfxId(SfxId.starEarned);
    }
    setState(() => _isRestoring = false);
  }

  Future<void> _restoreStreakWithAd() async {
    setState(() => _isRestoring = true);
    
    final adManager = AdManager();
    final success = await adManager.showRewardedAd('streak_restore');
    
    if (success) {
      await widget.economyManager.restoreStreakWithAd();
      AudioManager().playSfxId(SfxId.starEarned);
    }
    
    setState(() => _isRestoring = false);
  }

  void _skipStreakRestore() {
    // Mark as skipped so warning doesn't show again this session
    setState(() {
      _skippedRestore = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationManager();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _canClaim ? Colors.amber.withOpacity(0.5) : Colors.white10,
          width: _canClaim ? 2 : 1,
        ),
        boxShadow: _canClaim ? [
          BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 8),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.calendar_today, color: PrismazeTheme.warningYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                loc.getString('daily_login_title'),
                style: GoogleFonts.dynaPuff(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_canClaim)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    loc.getString('daily_reward'),
                    style: GoogleFonts.dynaPuff(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Streak Lost Warning (only show if not skipped)
          if (_wasStreakBroken && _canClaim && !_skippedRestore) ...[
            _buildStreakLostSection(loc),
            const SizedBox(height: 12),
          ],
          
          // 7-Day Grid
          _build7DayGrid(),
          const SizedBox(height: 16),
          
          // Claim Button or Status
          _buildClaimSection(loc),
        ],
      ),
    );
  }
  
  Widget _buildStreakLostSection(LocalizationManager loc) {
    final previousStreak = widget.economyManager.previousStreak;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${loc.getString('streak_lost')} ($previousStreak ${loc.getString('days')})',
                  style: GoogleFonts.dynaPuff(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Watch Ad
              Expanded(
                child: GestureDetector(
                  onTap: _isRestoring ? null : _restoreStreakWithAd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: PrismazeTheme.accentCyan.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isRestoring 
                      ? Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: PrismazeTheme.accentCyan)))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle, color: PrismazeTheme.accentCyan, size: 16),
                            const SizedBox(width: 4),
                            Text(loc.getString('watch_ad'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Pay Tokens
              Expanded(
                child: GestureDetector(
                  onTap: _isRestoring ? null : _restoreStreakWithTokens,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: PrismazeTheme.warningYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 16),
                        const SizedBox(width: 4),
                        Text('${StreakRestoreOption.tokenCost}', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Skip
              GestureDetector(
                onTap: _skipStreakRestore,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Text('Atla', style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _build7DayGrid() {
    return SizedBox(
      height: 70,
      child: Row(
        children: List.generate(7, (index) {
          final day = index + 1;
          final reward = DailyReward.getForDay(day);
          final isCurrentDay = day == _currentDay;
          final isPast = day < _currentDay;
          final isClaimed = isPast || (_claimed && isCurrentDay);
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
              decoration: BoxDecoration(
                color: isCurrentDay 
                    ? Colors.amber.withOpacity(0.2) 
                    : isClaimed 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentDay ? Colors.amber : isClaimed ? Colors.green.withOpacity(0.5) : Colors.transparent,
                  width: isCurrentDay ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: GoogleFonts.dynaPuff(
                      color: isCurrentDay ? Colors.amber : Colors.white54,
                      fontSize: 10,
                      fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isClaimed)
                    Icon(Icons.check_circle, color: Colors.green, size: 18)
                  else ...[
                    if (reward.hasSpecialReward)
                      Icon(Icons.star, color: _getRarityColor(reward.rarity), size: 14)
                    else
                      Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 14),
                    Text(
                      '${reward.hintTokens}',
                      style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'epic': return PrismazeTheme.accentPink;
      case 'rare': return PrismazeTheme.accentCyan;
      default: return Colors.grey;
    }
  }
  
  Widget _buildClaimSection(LocalizationManager loc) {
    if (_claimed) {
      // Show claimed success
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              '+${_claimedReward?.hintTokens ?? 0} ${loc.getString('tokens')}',
              style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (_claimedReward?.hasSpecialReward == true) ...[
              const SizedBox(width: 8),
              Icon(Icons.star, color: PrismazeTheme.accentPink, size: 16),
            ],
          ],
        ),
      );
    }
    
    if (!_canClaim) {
      // Already claimed today - show simple checkmark
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Text(
              loc.getString('claimed_today'),
              style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    // Can claim - show button
    final currentReward = DailyReward.getForDay(_currentDay);
    return GestureDetector(
      onTap: _handleClaim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: PrismazeTheme.buttonGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.getString('btn_claim'),
              style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.lightbulb, color: Colors.white, size: 16),
            Text(
              ' +${currentReward.hintTokens}',
              style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (currentReward.hasSpecialReward) ...[
              const SizedBox(width: 4),
              Icon(Icons.star, color: Colors.amber, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

