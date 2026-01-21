import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/prismaze_game.dart'; 
import '../game/progress_manager.dart';
import '../game/localization_manager.dart';
import '../theme/app_theme.dart';
import 'components/styled_back_button.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  final ProgressManager progressManager;
  const StatisticsScreen({Key? key, required this.progressManager}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late ProgressManager pm;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    pm = widget.progressManager;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final loc = LocalizationManager();
    final weeklyData = pm.getWeeklyActivity();
    final pieData = pm.getLikelyAchievementProgress();
    
    return Scaffold(
      backgroundColor: PrismazeTheme.backgroundDark,
      appBar: AppBar(
        title: Text(loc.getString('stat_title'), style: PrismazeTheme.headingMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: StyledBackButton(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Personal Stats Grid
            Text(loc.getString('stat_personal'), style: PrismazeTheme.headingSmall),
            const SizedBox(height: 10),
            GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                    _buildStatCard(loc.getString('stat_playtime'), "${(pm.totalPlayTime / 60).toStringAsFixed(1)} dk", Icons.timer),
                    _buildStatCard(loc.getString('stat_completed'), "${pm.levelsCompleted}", Icons.check_circle_outline),
                    _buildStatCard(loc.getString('stat_3stars'), "${pm.totalThreeStars}", Icons.star),
                    _buildStatCard(loc.getString('stat_fastest'), "${pm.fastestLevelTime}s", Icons.flash_on),
                    _buildStatCard(loc.getString('stat_hints'), "${pm.totalHintsUsed}", Icons.lightbulb_outline),
                    _buildStatCard(loc.getString('stat_tokens'), "${pm.totalTokensEarned}", Icons.monetization_on),
                ],
            ),
            
            const SizedBox(height: 30),
            
            // 2. Weekly Activity Chart
            Text(loc.getString('stat_weekly'), style: PrismazeTheme.headingSmall),
            const SizedBox(height: 10),
            Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: PrismazeTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PrismazeTheme.primaryPurpleLight.withOpacity(0.2))
                ),
                child: CustomPaint(
                    size: const Size(double.infinity, 200),
                    painter: BarChartPainter(weeklyData),
                ),
            ),
            
            const SizedBox(height: 30),
            
            // 3. Achievement Progress (Pieish)
            Text(loc.getString('stat_distribution'), style: PrismazeTheme.headingSmall),
            const SizedBox(height: 10),
            _buildDistributionBars(pieData),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
      return Container(
          decoration: BoxDecoration(
              color: PrismazeTheme.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PrismazeTheme.primaryPurpleLight.withOpacity(0.2))
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
              children: [
                  Icon(icon, color: PrismazeTheme.primaryPurpleLight, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(value, style: PrismazeTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                            Text(label, style: PrismazeTheme.bodySmall, overflow: TextOverflow.ellipsis),
                        ],
                    ),
                  )
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
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                      children: [
                          SizedBox(width: 100, child: Text(e.key, style: PrismazeTheme.bodyMedium)),
                          Expanded(
                              child: Stack(
                                  children: [
                                      Container(height: 12, decoration: BoxDecoration(color: PrismazeTheme.backgroundOverlay, borderRadius: BorderRadius.circular(6))),
                                      FractionallySizedBox(
                                          widthFactor: pct.clamp(0.01, 1.0),
                                          child: Container(height: 12, decoration: BoxDecoration(color: PrismazeTheme.primaryPurple, borderRadius: BorderRadius.circular(6))),
                                      ),
                                  ],
                              ),
                          ),
                          const SizedBox(width: 10),
                          Text("${e.value.toInt()}", style: PrismazeTheme.bodyMedium)
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
        final paint = Paint()..color = Colors.cyanAccent;
        final axisPaint = Paint()..color = Colors.white24..strokeWidth = 1;
        final textStyle = const TextStyle(color: Colors.white70, fontSize: 10);
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
            final h = (value / maxVal) * (size.height - 20); // 20px buffer for text
            
            // Bar
            final r = RRect.fromRectAndRadius(
                Rect.fromLTWH(x - barWidth/2, size.height - h - 20, barWidth, h),
                const Radius.circular(4)
            );
            canvas.drawRRect(r, paint);
            
            // Label
            textPainter.text = TextSpan(text: label, style: textStyle);
            textPainter.layout();
            textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 15));
            
            // Value
            if (value > 0) {
                 textPainter.text = TextSpan(text: "$value", style: textStyle.copyWith(color: Colors.white));
                 textPainter.layout();
                 textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - h - 35));
            }
            
            i++;
        });
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
