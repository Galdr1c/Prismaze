import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/prismaze_game.dart';
import 'level_complete_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/settings_manager.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int levelId;
  final Map<String, dynamic>? levelData;
  final int? episode;      // Episode number (1-5)
  final int? levelIndex;   // 0-based index within episode
  
  const GameScreen({
    super.key, 
    required this.levelId, 
    this.levelData,
    this.episode,
    this.levelIndex,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late PrismazeGame _game;

  @override
  void initState() {
    super.initState();
    _game = PrismazeGame(
      ref, 
      levelData: widget.levelData,
      episode: widget.episode,
      levelIndex: widget.levelIndex,
    );
    
    // Explicitly set ID for display if not campaign (fallback)
    if (widget.episode == null) {
      _game.currentLevelId = widget.levelId;
      _game.levelNotifier.value = widget.levelId;
    }
    
    // Start Gameplay Music
    AudioManager().playGameplayMusic(widget.levelId);
  }

  @override
  void dispose() {
    // Restore Menu Music logic handled here for safety (User Request)
    AudioManager().playMenuMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030308),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. GAME LAYER
          Positioned.fill(
            child: GameWidget(game: _game),
          ),
          
          // 2. UI LAYER - Minimal Layout
          SafeArea(
            child: Stack(
              children: [
                // === TOP BAR ===
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BACK BUTTON
                        _buildCircleButton(
                          icon: Icons.arrow_back,
                          onTap: () {
                               Navigator.pop(context);
                          },
                        ),
                        
                        // LEVEL TITLE
                        // Reactive Level Title
                        ValueListenableBuilder<int>(
                           valueListenable: _game.levelNotifier,
                           builder: (ctx, levelId, _) {
                             return Text(
                                "LEVEL $levelId", 
                                style: GoogleFonts.dynaPuff(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.purple, blurRadius: 15)],
                                ),
                             );
                           }
                        ),
                        
                        // SETTINGS BUTTON
                        _buildCircleButton(
                          icon: Icons.settings,
                          onTap: () => _showQuickSettings(context),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // === RIGHT SIDE CONTROLS ===
                Positioned(
                  right: 16,
                  bottom: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RESTART
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: LocalizationManager().getString('btn_restart'),
                        onTap: () => _game.restartLevel(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // UNDO
                      ListenableBuilder(
                        listenable: _game.undoSystem,
                        builder: (ctx, _) {
                            final canUndo = _game.undoSystem.canUndo;
                            final waitingForAd = !_game.undoSystem.canUndo && _game.undoSystem.canWatchAd;
                            final text = _game.undoSystem.getUndoText();
                            
                            return _buildActionButton(
                                icon: waitingForAd ? Icons.ondemand_video : Icons.undo,
                                label: waitingForAd ? LocalizationManager().getString('btn_ad_plus_one') : LocalizationManager().getString('btn_undo'),
                                subLabel: text,
                                color: (canUndo || waitingForAd) ? Colors.white : Colors.white24,
                                onTap: () async {
                                    if(canUndo) {
                                        _game.undo();
                                    } else if (waitingForAd) {
                                        final success = await _game.adManager.showRewardedAd('undo_bonus');
                                        if (success) {
                                            _game.undoSystem.addBonusUndo();
                                        } else {
                                            if (ctx.mounted) {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                    SnackBar(content: Text(LocalizationManager().getString('msg_no_ad')))
                                                );
                                            }
                                        }
                                    }
                                },
                            );
                        }
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // HINT
                      _buildActionButton(
                        icon: Icons.lightbulb_outline,
                        label: LocalizationManager().getString('btn_hint'),
                        color: Colors.amber,
                        onTap: () => _game.hintManager.showLightHint(),
                      ),
                    ],
                  ),
                ),
                
                // === LEFT SIDE ZOOM CONTROLS (Debug Only) ===
                if (SettingsManager().debugModeEnabled)
                  Positioned(
                    left: 16,
                    bottom: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCircleButton(
                          icon: Icons.add,
                          onTap: () => _game.zoomIn(),
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        _buildCircleButton(
                          icon: Icons.remove,
                          onTap: () => _game.zoomOut(),
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // 3. LEVEL COMPLETE OVERLAY
          ValueListenableBuilder<LevelResult?>(
            valueListenable: _game.levelCompleteNotifier,
            builder: (ctx, result, _) {
              if (result == null) return const SizedBox.shrink();
              return LevelCompleteOverlay(
                result: result,
                onNext: () {
                  _game.nextLevel();
                  setState(() {});
                },
                onReplay: () => _game.restartLevel(),
                onMenu: () => Navigator.pop(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // 12 + 20 + 12 = 44px
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subLabel,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12), // 12 + 24 + 12 = 48px
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                 BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
              ]
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (subLabel != null) ...[
             const SizedBox(height: 2),
             Text(
               subLabel, 
               style: GoogleFonts.dynaPuff(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold)
             ),
          ]
        ],
      ),
    );
  }

  void _showQuickSettings(BuildContext context) {
    _game.paused = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final sm = SettingsManager();
          return Dialog( // Changed to Dialog for better control
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.2))
            ),
            insetPadding: const EdgeInsets.all(20),
            child: Container(
               width: 280,
               padding: const EdgeInsets.all(16),
               child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(LocalizationManager().getString('game_paused'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 20)),
                   const SizedBox(height: 16),
                   
                   // Music
                   Row(
                     children: [
                       SizedBox(width: 40, child: Text(LocalizationManager().getString('settings_music'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 11))),
                       Expanded(
                         child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.purpleAccent, thumbColor: Colors.white,
                                trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            ),
                            child: Slider(
                                value: sm.musicVolume,
                                onChanged: (v) {
                                    setDialogState(() {
                                        sm.setMusicVolume(v);
                                        AudioManager().setMusicVolume(v);
                                        AudioManager().updateBgmVolume();
                                    });
                                },
                            ),
                         ),
                       ),
                     ],
                   ),
                   // SFX
                   Row(
                     children: [
                       SizedBox(width: 40, child: Text(LocalizationManager().getString('settings_sfx'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 11))),
                       Expanded(
                         child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.amber, thumbColor: Colors.white,
                                trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                            ),
                            child: Slider(
                                value: sm.sfxVolume,
                                onChanged: (v) {
                                    setDialogState(() {
                                        sm.setSfxVolume(v);
                                        AudioManager().setSfxVolume(v);
                                    });
                                },
                            ),
                         ),
                       ),
                     ],
                   ),
                   
                   // Vibration
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(LocalizationManager().getString('settings_vibration'), style: GoogleFonts.dynaPuff(color: Colors.white70, fontSize: 11)),
                       Transform.scale(
                           scale: 0.8,
                           child: Switch(
                               value: sm.vibrationStrength > 0,
                               activeColor: Colors.purpleAccent,
                               onChanged: (v) {
                                   setDialogState(() {
                                       final val = v ? 1.0 : 0.0;
                                       sm.setVibrationStrength(val);
                                       AudioManager().setVibrationStrength(val);
                                   });
                               }
                           ),
                       ),
                     ],
                   ),

                   const SizedBox(height: 16),
                   
                   // BUTTONS
                   SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.purpleAccent,
                             padding: const EdgeInsets.symmetric(vertical: 10), // Reduced from 12
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                         ),
                         onPressed: () {
                           Navigator.pop(ctx);
                           _game.paused = false;
                         },
                         child: Text(LocalizationManager().getString('game_resume'), style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 16)),
                       ),
                   ),
                   const SizedBox(height: 8),
                   SizedBox(
                       width: double.infinity,
                       child: TextButton(
                         onPressed: () {
                           Navigator.pop(ctx);
                           AudioManager().playMenuBgm();
                           Navigator.of(context).popUntil((route) => route.isFirst);
                         },
                         style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                         child: Text(LocalizationManager().getString('game_exit'), style: GoogleFonts.dynaPuff(color: Colors.redAccent, fontSize: 12)),
                       ),
                   )
                ],
              ),
            ),
          );
        }
      ),
    ).then((_) {
         if (_game.paused) _game.paused = false;
    });
  }
}
