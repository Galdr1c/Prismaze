import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/prismaze_game.dart';
import '../game/audio_manager.dart';
import '../game/localization_manager.dart';

class LevelCompleteOverlay extends StatefulWidget {
  final LevelResult result;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onMenu;

  const LevelCompleteOverlay({
    super.key,
    required this.result,
    required this.onNext,
    required this.onReplay,
    required this.onMenu,
  });

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _mainController;
  late Animation<double> _panelScale;
  
  // Star Animations
  final List<AnimationController> _starControllers = [];
  final List<Animation<double>> _starScales = [];
  
  bool _statsVisible = false;
  bool _buttonVisible = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Panel Pop In
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _panelScale = CurvedAnimation(parent: _mainController, curve: Curves.elasticOut);
    _mainController.forward();
    
    // Setup Star Controllers
    for(int i=0; i<3; i++) {
        final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
        _starControllers.add(ctrl);
        _starScales.add(CurvedAnimation(parent: ctrl, curve: Curves.bounceOut));
    }
    
    _playSequence();
  }

  Future<void> _playSequence() async {
      // 0. Panel opens (handled by initState)
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _cancelled) return;
      
      // 1-3. Stars Fall
      for (int i = 0; i < 3; i++) {
          if (i < widget.result.stars) {
             _starControllers[i].forward();
             if (mounted && !_cancelled) {
                 AudioManager().playSfxId(SfxId.starEarned); 
                 AudioManager().vibrateStar(i);
             }
          }
          await Future.delayed(const Duration(milliseconds: 400));
          if (!mounted || _cancelled) return;
      }
      
      // Confetti & Win Sound
      if (widget.result.stars == 3) {
           if (mounted && !_cancelled) {
               _confettiController.play();
               AudioManager().playSfxId(SfxId.levelComplete);
           }
      }
      
      // 4. Stats Fade In
      if (mounted && !_cancelled) setState(() => _statsVisible = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _cancelled) return;
      
      // 5. Button Bounce In
      if (mounted && !_cancelled) setState(() => _buttonVisible = true);
  }

  @override
  void dispose() {
    _cancelled = true;
    _confettiController.dispose();
    _mainController.dispose();
    for(final c in _starControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Darken Background
        Container(
          color: Colors.black.withOpacity(0.8),
        ),
        
        // Confetti (Top Center)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple], 
          ),
        ),
        
        // Content Dialog
        Center(
          child: ScaleTransition(
            scale: _panelScale,
            child: OrientationBuilder(
                builder: (context, orientation) {
                    final isLandscape = orientation == Orientation.landscape;
                    
                    return Container(
                      width: isLandscape ? 550 : 300,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.85, 
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                            const BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: -5),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: isLandscape 
                            ? _buildLandscapeLayout()
                            : _buildPortraitLayout(),
                      ),
                    );
                }
            ),
          ),
        ),
      ],
    );
  }

  // PORTRAIT: Original Column Layout
  Widget _buildPortraitLayout() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 30),
          _buildStars(),
          const SizedBox(height: 30),
          _buildStats(),
          const SizedBox(height: 30),
          _buildButtons(),
        ],
      );
  }

  // LANDSCAPE: Row Layout
  Widget _buildLandscapeLayout() {
      return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              // LEFT: Title + Stars
              Expanded(
                  flex: 5,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          _buildTitle(),
                          const SizedBox(height: 20),
                          _buildStars(),
                      ],
                  ),
              ),
              
              const SizedBox(width: 20),
              Container(width: 2, height: 150, color: Colors.white10), // Divider
              const SizedBox(width: 20),
              
              // RIGHT: Stats + Buttons
              Expanded(
                  flex: 6,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          _buildStats(),
                          const SizedBox(height: 20),
                          _buildButtons(),
                      ],
                  ),
              ),
          ],
      );
  }
  
  // --- Component Widgets ---
  
  // --- Component Widgets ---
  
  Widget _buildTitle() {
      final loc = LocalizationManager();
      String defaultTitle = widget.result.stars > 0 
          ? loc.getString('level_complete_success') 
          : loc.getString('level_complete_fail');
          
      return Column(
        children: [
           Text(
            widget.result.customTitle ?? defaultTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dynaPuff(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.cyanAccent, blurRadius: 10)],
            ),
          ),
          if (widget.result.stars > widget.result.oldStars && widget.result.stars > 0 && widget.result.oldStars > 0)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                          return Transform.scale(
                              scale: scale,
                              child: Text(
                                  "YENİ REKOR!", // "NEW SCORE!"
                                  style: GoogleFonts.dynaPuff(
                                      fontSize: 18,
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                          BoxShadow(color: Colors.orangeAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 5)
                                      ]
                                  )
                              ),
                          );
                      },
                      onEnd: () {}, // Loop? For now single pulse or handled by builder loop if stateful
                  )
              ),
        ],
      );
  }
  
  Widget _buildStars() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
            // Logic:
            // Index 0, 1, 2.
            // Star 1 is Index 0.
            // If oldStars = 1, then Index 0 is "Old".
            // If newStars = 3. Index 1, 2 are "New".
            
            bool achieved = index < widget.result.stars;
            bool isNew = achieved && (index >= widget.result.oldStars);
            
            return Container(
                width: 60, height: 60,
                alignment: Alignment.center,
                child: achieved 
                    ? ScaleTransition(
                        scale: _starScales[index],
                        child: Stack(
                            alignment: Alignment.center,
                            children: [
                                Icon(Icons.star, 
                                    color: isNew ? Colors.yellowAccent : const Color(0xFFFFD700), // Brighter if new
                                    size: 45
                                ),
                                if (isNew) 
                                    const Icon(Icons.star, color: Colors.white54, size: 45) // Shine overlay
                                    // Or add Glow
                            ],
                        ),
                      )
                    : const Icon(Icons.star_border, color: Colors.white24, size: 45),
            );
        }),
      );
  }
  
  Widget _buildStats() {
      final loc = LocalizationManager();
      return AnimatedOpacity(
          opacity: _statsVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Column(
              children: [
                  _buildStatRow(loc.getString('lbl_moves'), "${widget.result.moves} ", "/ ${widget.result.par}"),
                  const Divider(color: Colors.white10),
                  if (widget.result.earnedTokens > 0)
                      _buildStatRow(loc.getString('lbl_earnings'), "+${widget.result.earnedTokens} ", loc.getString('lbl_tokens')),
              ],
          ),
      );
  }
  
  Widget _buildButtons() {
    final loc = LocalizationManager();
    return Column(
        children: [
          // Next Level Button (Bounce In)
          if (widget.result.stars > 0)
              AnimatedScale(
                  scale: _buttonVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      elevation: 10,
                      shadowColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(loc.getString('btn_next_level'), style: GoogleFonts.dynaPuff(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
              )
          else
              ElevatedButton(
                    onPressed: widget.onReplay,
                    child: Text(loc.getString('btn_try_again'), style: GoogleFonts.dynaPuff(fontWeight: FontWeight.bold)),
              ),
          
          const SizedBox(height: 10),
          
          // Secondary Buttons
          AnimatedOpacity(
              opacity: _statsVisible ? 1.0 : 0.0, 
              duration: const Duration(milliseconds: 500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                    label: Text(loc.getString('btn_replay'), style: GoogleFonts.dynaPuff(color: Colors.white70)),
                    onPressed: widget.onReplay,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.menu, color: Colors.white70, size: 20),
                    label: Text(loc.getString('btn_menu'), style: GoogleFonts.dynaPuff(color: Colors.white70)),
                    onPressed: widget.onMenu,
                  ),
                ],
              ),
          ),
        ],
    );
  }
  
  Widget _buildStatRow(String label, String value, String suffix) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 13)),
            Row(
                children: [
                    Text(value, style: GoogleFonts.dynaPuff(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(suffix, style: GoogleFonts.dynaPuff(color: Colors.white54, fontSize: 13)),
                ],
            ),
          ],
        ),
      );
  }
}

