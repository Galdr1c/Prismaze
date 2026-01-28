import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/prismaze_game.dart'; 
import '../game/progress_manager.dart';
import '../game/mission_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  final ProgressManager progressManager;
  final MissionManager missionManager;
  
  const StatisticsScreen({
      Key? key, 
      required this.progressManager,
      required this.missionManager
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late ProgressManager pm;
  late MissionManager mm;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    pm = widget.progressManager;
    mm = widget.missionManager;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final loc = LocalizationManager();
    final weeklyData = pm.getWeeklyActivity();
    final pieData = pm.getLikelyAchievementProgress();
    
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: PrismazeTheme.backgroundDark,
      appBar: AppBar(
        title: Text(loc.getString('stat_title'), style: PrismazeTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 100, // Increased width for "Back" text
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StyledBackButton(),
        ),
      ),
      body: Stack(
        children: [
            // Background Gradient
            Container(
                decoration: BoxDecoration(
                    gradient: PrismazeTheme.backgroundGradient
                ),
            ),
            
            // Content
            SafeArea(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Personal Stats Grid
                        _buildSectionHeader(loc.getString('stat_personal'), Icons.person),
                        const SizedBox(height: 12),
                        GridView.count(
                            crossAxisCount: 6, // 3 cols is better than 6
                            shrinkWrap: true,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                                _buildStatCard(loc.getString('stat_playtime'), "${(pm.totalPlayTime / 60).toStringAsFixed(1)} dk", Icons.timer, Colors.cyan),
                                _buildStatCard(loc.getString('stat_completed'), "${pm.levelsCompleted}", Icons.check_circle_outline, Colors.green),
                                _buildStatCard(loc.getString('stat_3stars'), "${pm.totalThreeStars}", Icons.star, Colors.amber),
                                _buildStatCard(loc.getString('stat_fastest'), "${pm.fastestLevelTime}s", Icons.flash_on, Colors.orange),
                                _buildStatCard(loc.getString('stat_hints'), "${pm.totalHintsUsed}", Icons.lightbulb_outline, Colors.purpleAccent),
                                _buildStatCard(loc.getString('stat_tokens'), "${pm.totalHintsEarned}", Icons.lightbulb, Colors.yellowAccent),
                            ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 3. Weekly Activity Chart
                        _buildSectionHeader(loc.getString('stat_weekly'), Icons.bar_chart),
                        const SizedBox(height: 12),
                        Container(
                            height: 180,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3), // Lightweight transparency
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: PrismazeTheme.primaryPurpleLight.withOpacity(0.3))
                            ),
                            child: CustomPaint(
                                size: const Size(double.infinity, 200),
                                painter: BarChartPainter(weeklyData),
                            ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // 4. Achievement Progress
                        _buildSectionHeader(loc.getString('stat_distribution'), Icons.pie_chart),
                        const SizedBox(height: 12),
                        Container(
                             padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: PrismazeTheme.accentCyan.withOpacity(0.3))
                             ),
                             child: _buildDistributionBars(pieData),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
      return Row(
          children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(title, style: PrismazeTheme.headingSmall.copyWith(fontSize: 18, color: Colors.white)),
          ],
      );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color accentColor) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
              ]
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
              children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(value, style: GoogleFonts.dynaPuff(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                                label, 
                                style: GoogleFonts.dynaPuff(color: Colors.white60, fontSize: 10), 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis
                            ),
                        ],
                    ),
                  ),
              ],
          ),
      );
  }
  
  Widget _buildDistributionBars(Map<String, double> data) {
      // Find max to normalize
      double maxVal = 1;
      data.forEach((k,v) => maxVal = max(maxVal, v));
      
      return Column(
          children: data.entries.map((e) {
              final pct = e.value / maxVal;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                      children: [
                          SizedBox(width: 90, child: Text(e.key, style: PrismazeTheme.bodyMedium.copyWith(fontSize: 12))),
                          Expanded(
                              child: Stack(
                                  children: [
                                      Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                                      FractionallySizedBox(
                                          widthFactor: pct.clamp(0.01, 1.0),
                                          child: Container(
                                              height: 8, 
                                              decoration: BoxDecoration(
                                                  color: PrismazeTheme.accentCyan, 
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [BoxShadow(color: PrismazeTheme.accentCyan.withOpacity(0.5), blurRadius: 4)]
                                              )
                                          ),
                                      ),
                                  ],
                              ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(width: 30, child: Text("${e.value.toInt()}", style: PrismazeTheme.bodyMedium.copyWith(fontSize: 12), textAlign: TextAlign.end))
                      ],
                  ),
              );
          }).toList(),
      );
  }
}

class BarChartPainter extends CustomPainter {
    final Map<String, int> data;
    BarChartPainter(this.data);
    
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()..color = PrismazeTheme.accentPink;
        final axisPaint = Paint()..color = Colors.white24..strokeWidth = 1;
        final textStyle = GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 10);
        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        
        // Draw Axis
        canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
        
        final barWidth = size.width / (data.length * 2);
        final spacing = size.width / data.length;
        int maxVal = 1;
        data.forEach((k,v) => maxVal = max(maxVal, v));
        if(maxVal < 5) maxVal = 5; // min height scale
        
        int i = 0;
        data.forEach((label, value) {
            final x = i * spacing + spacing/2;
            final h = (value / maxVal) * (size.height - 30); 
            
            // Bar
            if (value > 0) {
                 final r = RRect.fromRectAndRadius(
                    Rect.fromLTWH(x - barWidth/2, size.height - h - 20, barWidth, h),
                    const Radius.circular(4)
                );
                canvas.drawRRect(r, paint);
             }
            
            // Label (X)
            textPainter.text = TextSpan(text: label, style: textStyle);
            textPainter.layout();
            textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 15));
            
            // Value (Y)
            if (value > 0) {
                 textPainter.text = TextSpan(text: "$value", style: textStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold));
                 textPainter.layout();
                 textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - h - 35));
            }
            
            i++;
        });
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

