import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/mission_manager.dart';
import '../game/economy_manager.dart';
import '../game/event_manager.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'components/daily_login_section.dart';

class DailyQuestsScreen extends StatefulWidget {
  final MissionManager missionManager;
  final EconomyManager economyManager;
  
  const DailyQuestsScreen({
    super.key,
    required this.missionManager,
    required this.economyManager,
  });
  
  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen> {
  late EventManager _eventManager;
  
  @override
  void initState() {
    super.initState();
    widget.missionManager.addListener(_onUpdate);
    _eventManager = EventManager();
    _eventManager.init().then((_) {
      _eventManager.addListener(_onUpdate);
      if (mounted) setState(() {});
    });
  }
  
  @override
  void dispose() {
    widget.missionManager.removeListener(_onUpdate);
    _eventManager.removeListener(_onUpdate);
    super.dispose();
  }
  
  void _onUpdate() {
    if (mounted) setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final missions = widget.missionManager.missions;
    
    // Calculate time until midnight
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final remaining = tomorrow.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(gradient: PrismazeTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StyledBackButton(),
                    Text(
                      'Günlük Görevler',
                      style: GoogleFonts.dynaPuff(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // Token display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: PrismazeTheme.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.economyManager.tokens}',
                            style: GoogleFonts.dynaPuff(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Countdown Timer
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: PrismazeTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: PrismazeTheme.accentCyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Yenilenme: ${hours}s ${minutes.toString().padLeft(2, '0')}dk',
                      style: GoogleFonts.dynaPuff(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Main Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Daily Login Streak Section (now scrolls with content)
                      DailyLoginSection(
                        economyManager: widget.economyManager,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Two Columns - Daily Missions & Events
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Daily Missions
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('GÜNLÜK GÖREVLER', Icons.assignment, Colors.orange),
                                const SizedBox(height: 8),
                                ...missions.map((m) => _buildMissionCard(m)),
                                
                                // Bonus Section
                                if (widget.missionManager.allCompleted) ...[
                                  const SizedBox(height: 8),
                                  _buildBonusCard(),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Right Column - Limited Time Event
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('SINIRLI SÜRE ETKİNLİK', Icons.celebration, PrismazeTheme.accentPink),
                                const SizedBox(height: 8),
                                _buildEventSection(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.dynaPuff(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEventSection() {
    final activeEvent = _eventManager.activeEvent;
    
    if (activeEvent == null) {
      return _buildNoEventCard();
    }
    
    final eventMissions = _eventManager.getEventMissions();
    
    return Column(
      children: [
        // Active Event Card
        _buildActiveEventCard(activeEvent),
        const SizedBox(height: 8),
        
        // Event Missions
        ...eventMissions.map((m) => _buildEventMissionCard(m)),
      ],
    );
  }
  
  Widget _buildNoEventCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, color: Colors.white30, size: 32),
          const SizedBox(height: 8, width: 1000),
          Text(
            'Şu anda aktif etkinlik yok',
            textAlign: TextAlign.center,
            style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakında yeni etkinlikler!',
            textAlign: TextAlign.center,
            style: GoogleFonts.dynaPuff(color: PrismazeTheme.accentCyan, fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveEventCard(SeasonalEvent event) {
    final daysLeft = _eventManager.daysRemaining;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getEventColor(event.id).withOpacity(0.3),
            _getEventColor(event.id).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getEventColor(event.id).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Event Header
          Row(
            children: [
              Text(event.iconEmoji, style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: GoogleFonts.dynaPuff(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$daysLeft gün kaldı',
                      style: GoogleFonts.dynaPuff(
                        color: _getEventColor(event.id),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Multiplier Info
          Row(
            children: [
              Expanded(
                child: _buildMultiplierBadge('🎁 x${event.tokenMultiplier.toStringAsFixed(1)}', 'Jeton'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMultiplierBadge('⭐ x${event.questRewardMultiplier.toStringAsFixed(1)}', 'Görev'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMultiplierBadge(String multiplier, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(multiplier, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 8)),
        ],
      ),
    );
  }
  
  Color _getEventColor(String eventId) {
    switch (eventId) {
      case 'halloween': return Colors.orange;
      case 'winter': return Colors.cyan;
      case 'summer': return Colors.amber;
      case 'valentines': return Colors.pink;
      default: return PrismazeTheme.accentPink;
    }
  }
  
  Widget _buildEventMissionCard(EventMission mission) {
    final progress = _eventManager.getMissionProgress(mission.id);
    final isCompleted = progress >= mission.target;
    final progressPercent = (progress / mission.target).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: GoogleFonts.dynaPuff(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PrismazeTheme.warningYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb, color: PrismazeTheme.warningYellow, size: 10),
                    const SizedBox(width: 2),
                    Text('${mission.reward}', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mission.description,
            style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 9),
          ),
          const SizedBox(height: 6),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressPercent,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : PrismazeTheme.accentCyan,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$progress/${mission.target}',
            style: GoogleFonts.dynaPuff(color: Colors.white38, fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBonusCard() {
    final bonusClaimed = widget.missionManager.bonusClaimed;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bonusClaimed 
              ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
              : [Colors.amber.withOpacity(0.3), Colors.orange.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bonusClaimed ? Colors.green.withOpacity(0.5) : Colors.amber.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bonusClaimed ? Icons.check_circle : Icons.stars, 
            color: bonusClaimed ? Colors.green : Colors.amber, 
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tümü Tamamlandı!',
                  style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  bonusClaimed ? 'Bonus alındı!' : '+${MissionManager.bonusReward} Bonus',
                  style: GoogleFonts.dynaPuff(
                    color: bonusClaimed ? Colors.green : Colors.amber,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (widget.missionManager.bonusAvailable)
            GestureDetector(
              onTap: () async {
                AudioManager().playSfx('coin_collect.mp3');
                await widget.missionManager.claimBonusReward();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: PrismazeTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('AL', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMissionCard(Mission mission) {
    final isCompleted = mission.isCompleted;
    final isClaimed = mission.claimed;
    final progress = (mission.current / mission.target).clamp(0.0, 1.0);
    
    Color difficultyColor;
    switch (mission.difficulty) {
      case 'Easy':
        difficultyColor = Colors.green;
        break;
      case 'Medium':
        difficultyColor = Colors.orange;
        break;
      case 'Hard':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = Colors.grey;
    }
    
    IconData missionIcon = _getMissionIcon(mission.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PrismazeTheme.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isClaimed ? Colors.green.withOpacity(0.5) : 
                 isCompleted ? Colors.amber.withOpacity(0.5) : 
                 Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(missionIcon, color: difficultyColor, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        mission.difficulty,
                        style: GoogleFonts.dynaPuff(color: difficultyColor, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.description,
                      style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Reward or Claim
              if (isClaimed) 
                Icon(Icons.check_circle, color: Colors.green, size: 18)
              else if (isCompleted)
                GestureDetector(
                  onTap: () async {
                    AudioManager().playSfx('coin_collect.mp3');
                    await widget.missionManager.claimReward(mission);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: PrismazeTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lightbulb, color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text('+${mission.reward}', style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.white30, size: 10),
                      const SizedBox(width: 2),
                      Text('${mission.reward}', style: GoogleFonts.dynaPuff(color: Colors.white30, fontSize: 9)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [difficultyColor, difficultyColor.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${mission.current}/${mission.target}',
            style: GoogleFonts.dynaPuff(color: Colors.white38, fontSize: 8),
          ),
        ],
      ),
    );
  }
  
  IconData _getMissionIcon(MissionType type) {
    switch (type) {
      case MissionType.playLevels: return Icons.games;
      case MissionType.stars3: return Icons.star;
      case MissionType.perfectFinish: return Icons.diamond;
      case MissionType.noHint: return Icons.lightbulb_outline;
      case MissionType.watchAd: return Icons.ondemand_video;
      case MissionType.playTime: return Icons.timer;
      case MissionType.undoFree: return Icons.undo;
      case MissionType.fastComplete: return Icons.speed;
      case MissionType.exactMoves: return Icons.control_camera;
    }
  }
}
