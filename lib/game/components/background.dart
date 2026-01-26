import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../prismaze_game.dart';
import 'wall.dart';
import 'dart:developer' as dev;

class BackgroundComponent extends PositionComponent with HasGameRef<PrismazeGame> {
  // Theme Data
  late String _currentTheme;
  
  // Space Assets
  final List<Vector2> _stars = [];
  final List<double> _starSpeeds = [];
  final List<double> _starTwinkle = [];
  
  // Nebula Assets
  final List<_NebulaCloud> _nebulaClouds = [];
  
  // City Assets
  Path? _skylinePath;
  Paint? _skylinePaint;
  final List<Rect> _windows = [];
  
  // Ocean Assets
  double _wavePhase = 0.0;
  final List<_Bioluminescence> _bioParticles = [];
  final List<_FishSilhouette> _fish = [];
  final List<_LightRay> _lightRays = [];
  
  // Halloween Assets
  final List<_Pumpkin> _pumpkins = [];
  final List<_Bat> _bats = [];
  double _batPhase = 0.0;
  
  // Aurora Assets (Northern Lights)
  final List<_AuroraWave> _auroraWaves = [];
  double _auroraPhase = 0.0;
  
  // Galaxy Assets
  final List<_GalaxyStar> _galaxyStars = [];
  final List<_SpiralArm> _spiralArms = [];
  double _galaxyRotation = 0.0;
  
  // Global Ambient Effects
  final List<_DustParticle> _dustParticles = [];
  _ShootingStar? _shootingStar;
  double _shootingStarTimer = 0.0;
  double _globalTime = 0.0;
  
  BackgroundComponent() : super(anchor: Anchor.topLeft, priority: -200);

  @override
  Future<void> onLoad() async {
    // FIX: Set size to match resolution, but larger to ensure coverage
    size = Vector2(1344, 756); 
    position = Vector2(-32, -18); // Center the 5% zoom out (1344-1280=64, 756-720=36 -> Half is 32, 18)
    
    _currentTheme = gameRef.customizationManager.selectedTheme;
    gameRef.customizationManager.addListener(_onThemeChanged);
    
    _generateSpace();
    _generateCity();
    _generateOcean();
    _generateHalloween();
    _generateAurora();
    _generateGalaxy();
    _generateDustParticles();
  }
  
  // Removed onGameResize - Background should stay at logical size (-32, -18, 1344, 756)
  // to perfectly cover the camera's fixed resolution view.
  
  @override
  void onRemove() {
      gameRef.customizationManager.removeListener(_onThemeChanged);
      super.onRemove();
  }

  void _onThemeChanged() {
    _currentTheme = gameRef.customizationManager.selectedTheme;
  }
  
  void _generateSpace() {
      _stars.clear();
      _starSpeeds.clear();
      _starTwinkle.clear();
      _nebulaClouds.clear();
      
      final rng = Random();
      
      // Stars with twinkle
      for (int i = 0; i < 120; i++) {
          _stars.add(Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y));
          _starSpeeds.add(0.3 + rng.nextDouble() * 1.2);
          _starTwinkle.add(rng.nextDouble() * 2 * pi);
      }
      
      // Nebula clouds
      _nebulaClouds.add(_NebulaCloud(
        position: Vector2(size.x * 0.2, size.y * 0.3),
        radius: 150,
        color: const Color(0xFF4B0082).withOpacity(0.15),
      ));
      _nebulaClouds.add(_NebulaCloud(
        position: Vector2(size.x * 0.7, size.y * 0.6),
        radius: 200,
        color: const Color(0xFF1E3A5F).withOpacity(0.12),
      ));
      _nebulaClouds.add(_NebulaCloud(
        position: Vector2(size.x * 0.5, size.y * 0.8),
        radius: 120,
        color: const Color(0xFF8B008B).withOpacity(0.1),
      ));
  }
  
  void _generateCity() {
      final rng = Random(12345);
      final path = Path();
      path.moveTo(0, size.y);
      
      _windows.clear();
      double x = 0;
      while (x < size.x) {
          double w = 30 + rng.nextDouble() * 50;
          double h = 100 + rng.nextDouble() * 200;
          
          path.lineTo(x, size.y - h);
          path.lineTo(x + w, size.y - h);
          
          if (rng.nextDouble() > 0.3) {
              int floors = (h / 20).floor();
              for (int f = 0; f < floors; f++) {
                  if (rng.nextBool()) continue;
                  _windows.add(Rect.fromLTWH(x + 5, size.y - h + f * 20 + 5, w - 10, 10));
              }
          }
          x += w;
      }
      path.lineTo(size.x, size.y);
      path.close();
      
      _skylinePath = path;
      _skylinePaint = Paint()..color = const Color(0xFF050510);
  }
  
  void _generateOcean() {
      _bioParticles.clear();
      _fish.clear();
      _lightRays.clear();
      
      final rng = Random();
      
      // Bioluminescent particles
      for (int i = 0; i < 50; i++) {
          _bioParticles.add(_Bioluminescence(
            position: Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
            speed: 10 + rng.nextDouble() * 20,
            size: 2 + rng.nextDouble() * 4,
            color: rng.nextBool() ? Colors.cyan : Colors.lightBlueAccent,
            phase: rng.nextDouble() * 2 * pi,
          ));
      }
      
      // Fish silhouettes
      for (int i = 0; i < 5; i++) {
          _fish.add(_FishSilhouette(
            position: Vector2(rng.nextDouble() * size.x, size.y * 0.5 + rng.nextDouble() * size.y * 0.4),
            speed: 20 + rng.nextDouble() * 30,
            scale: 0.5 + rng.nextDouble() * 0.8,
            direction: rng.nextBool() ? 1 : -1,
          ));
      }
      
      // Light rays from surface
      for (int i = 0; i < 4; i++) {
          _lightRays.add(_LightRay(
            x: size.x * 0.15 + i * (size.x * 0.2),
            width: 30 + rng.nextDouble() * 50,
            opacity: 0.03 + rng.nextDouble() * 0.05,
          ));
      }
  }

  @override
  void update(double dt) {
    // Space Parallax & Twinkle
    if (_currentTheme == 'theme_space') {
        for (int i = 0; i < _stars.length; i++) {
            _stars[i].y += _starSpeeds[i] * dt * 8;
            _starTwinkle[i] += dt * 2;
            if (_stars[i].y > size.y) {
                _stars[i].y = 0;
                _stars[i].x = Random().nextDouble() * size.x;
            }
        }
    }
    
    // Ocean Motion
    if (_currentTheme == 'theme_ocean') {
        _wavePhase += dt * 0.8;
        
        // Update bioluminescence
        for (final bio in _bioParticles) {
            bio.position.y -= bio.speed * dt;
            bio.phase += dt * 1.5;
            if (bio.position.y < -10) {
                bio.position.y = size.y + 10;
                bio.position.x = Random().nextDouble() * size.x;
            }
        }
        
        // Update fish
        for (final fish in _fish) {
            fish.position.x += fish.speed * fish.direction * dt;
            if (fish.position.x > size.x + 50 || fish.position.x < -50) {
                fish.direction *= -1;
            }
        }
    }
    
    // Halloween Motion
    if (_currentTheme == 'theme_halloween') {
        _batPhase += dt;
        
        for (final bat in _bats) {
            bat.position.x += bat.speed * bat.direction * dt;
            bat.wingPhase += dt * 8;
            bat.position.y += sin(_batPhase * 2 + bat.offset) * 0.5;
            
            if (bat.position.x > size.x + 30 || bat.position.x < -30) {
                bat.direction *= -1;
            }
        }
    }
    
    // Aurora Motion
    if (_currentTheme == 'theme_aurora') {
        _auroraPhase += dt * 0.5;
    }
    
    // Galaxy Motion
    if (_currentTheme == 'theme_galaxy') {
        _galaxyRotation += dt * 0.02;
    }
    
    // Global Time
    _globalTime += dt;
    
    // Dust Particles (always active)
    for (final dust in _dustParticles) {
      dust.position.x += dust.velocityX * dt;
      dust.position.y += dust.velocityY * dt;
      dust.phase += dt * dust.twinkleSpeed;
      
      if (dust.position.x < -10) dust.position.x = size.x + 10;
      if (dust.position.x > size.x + 10) dust.position.x = -10;
      if (dust.position.y < -10) dust.position.y = size.y + 10;
      if (dust.position.y > size.y + 10) dust.position.y = -10;
    }
    
    // Shooting Star Timer
    _shootingStarTimer -= dt;
    if (_shootingStarTimer <= 0 && _shootingStar == null) {
      final rng = Random();
      if (rng.nextDouble() < 0.3) { // 30% chance
        _shootingStar = _ShootingStar(
          start: Vector2(rng.nextDouble() * size.x * 0.5, rng.nextDouble() * size.y * 0.3),
          angle: 0.5 + rng.nextDouble() * 0.5,
          speed: 400 + rng.nextDouble() * 300,
          life: 1.0,
        );
      }
      _shootingStarTimer = 5.0 + rng.nextDouble() * 10.0; // 5-15s interval
    }
    
    // Update shooting star
    if (_shootingStar != null) {
      _shootingStar!.life -= dt * 2;
      _shootingStar!.position += Vector2(
        cos(_shootingStar!.angle) * _shootingStar!.speed * dt,
        sin(_shootingStar!.angle) * _shootingStar!.speed * dt,
      );
      if (_shootingStar!.life <= 0) {
        _shootingStar = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    assert(() { dev.Timeline.startSync('Background.render'); return true; }());
    try {
    // High Contrast Check
    if (gameRef.settingsManager.highContrastEnabled) {
        canvas.drawRect(size.toRect(), Paint()..color = Colors.black);
        return;
    }

    // Base Background
    Color alignColor1, alignColor2;
    
    switch (_currentTheme) {
        case 'theme_neon':
           alignColor1 = const Color(0xFF100020);
           alignColor2 = const Color(0xFF200040);
           break;
        case 'theme_ocean':
           alignColor1 = const Color(0xFF000818);
           alignColor2 = const Color(0xFF001830);
           break;
        case 'theme_halloween':
           alignColor1 = const Color(0xFF0a0512);
           alignColor2 = const Color(0xFF1a0825);
           break;
        case 'theme_aurora':
           alignColor1 = const Color(0xFF051020);
           alignColor2 = const Color(0xFF0a1530);
           break;
        case 'theme_galaxy':
           alignColor1 = const Color(0xFF020208);
           alignColor2 = const Color(0xFF0a0510);
           break;
        case 'theme_space':
        default:
           alignColor1 = const Color(0xFF030308);
           alignColor2 = const Color(0xFF0a0a15);
           break;
    }
    
    final rect = size.toRect();
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [alignColor1, alignColor2],
      ).createShader(rect);
      
    canvas.drawRect(rect, gradient);
    
    // FIX: Restore theme specific rendering
    switch (_currentTheme) {
        case 'theme_space':
            _renderSpace(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
        case 'theme_city':
        case 'theme_neon':
            _renderCity(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
        case 'theme_ocean':
            _renderOcean(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
        case 'theme_halloween':
            _renderHalloween(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
        case 'theme_aurora':
            _renderAurora(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
        case 'theme_galaxy':
            _renderGalaxy(canvas, gameRef.settingsManager.reducedGlowEnabled);
            break;
    }

    // Shooting Star
    if (_shootingStar != null && !gameRef.settingsManager.reducedGlowEnabled) {
      final star = _shootingStar!;
      final tailLength = 80.0 * star.life;
      final tailEnd = star.position - Vector2(
        cos(star.angle) * tailLength,
        sin(star.angle) * tailLength,
      );
      
      // Tail glow
      canvas.drawLine(
        star.position.toOffset(),
        tailEnd.toOffset(),
        Paint()
          ..color = Colors.white.withOpacity(0.4 * star.life)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      
      // Head
      canvas.drawCircle(
        star.position.toOffset(),
        3,
        Paint()..color = Colors.white.withOpacity(star.life),
      );
    }
    
    // God rays removed for performance - was using expensive canvas rotation + gradient shaders
    // The vignette provides sufficient ambient lighting effect
    _drawVignette(canvas); 
    } finally {
      assert(() { dev.Timeline.finishSync(); return true; }());
    }
  }
  
  void _generateDustParticles() {
    _dustParticles.clear();
    final rng = Random();
    for (int i = 0; i < 20; i++) { // Reduced from 40
      _dustParticles.add(_DustParticle(
        position: Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
        velocityX: -3 + rng.nextDouble() * 6, // Slower
        velocityY: -2 + rng.nextDouble() * 4,
        size: 1 + rng.nextDouble() * 1.5, // Smaller
        phase: rng.nextDouble() * 2 * pi,
        twinkleSpeed: 0.5 + rng.nextDouble() * 1, // Slower twinkle
      ));
    }
  }
  
  void _drawCornerDecorations(Canvas canvas, Rect borderRect, Color borderColor, Color accentColor) {
    final cornerSize = 20.0;
    final paint = Paint()
      ..color = borderColor.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Top-left corner
    canvas.drawLine(
      Offset(borderRect.left, borderRect.top + cornerSize),
      Offset(borderRect.left, borderRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(borderRect.left, borderRect.top),
      Offset(borderRect.left + cornerSize, borderRect.top),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(borderRect.right - cornerSize, borderRect.top),
      Offset(borderRect.right, borderRect.top),
      paint,
    );
    canvas.drawLine(
      Offset(borderRect.right, borderRect.top),
      Offset(borderRect.right, borderRect.top + cornerSize),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(borderRect.left, borderRect.bottom - cornerSize),
      Offset(borderRect.left, borderRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(borderRect.left, borderRect.bottom),
      Offset(borderRect.left + cornerSize, borderRect.bottom),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(borderRect.right - cornerSize, borderRect.bottom),
      Offset(borderRect.right, borderRect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(borderRect.right, borderRect.bottom),
      Offset(borderRect.right, borderRect.bottom - cornerSize),
      paint,
    );
    
    // Corner dots (use accent color)
    final dotPaint = Paint()..color = accentColor;
    canvas.drawCircle(Offset(borderRect.left + 5, borderRect.top + 5), 3, dotPaint);
    canvas.drawCircle(Offset(borderRect.right - 5, borderRect.top + 5), 3, dotPaint);
    canvas.drawCircle(Offset(borderRect.left + 5, borderRect.bottom - 5), 3, dotPaint);
    canvas.drawCircle(Offset(borderRect.right - 5, borderRect.bottom - 5), 3, dotPaint);
  }
  
  void _drawGodRays(Canvas canvas) {
    // Subtle god rays from top-left and top-right corners
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, 400, 400));
    
    canvas.save();
    canvas.rotate(-0.2);
    canvas.drawRect(Rect.fromLTWH(-50, -50, 300, 600), rayPaint);
    canvas.restore();
    
    canvas.save();
    canvas.translate(size.x, 0);
    canvas.rotate(0.2);
    canvas.drawRect(Rect.fromLTWH(-250, -50, 300, 600), rayPaint);
    canvas.restore();
  }
  
  void _drawVignette(Canvas canvas) {
    // Simplified vignette - corners darkened
    final cornerPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final vSize = 400.0;
    canvas.drawOval(Rect.fromLTWH(-vSize/2, -vSize/2, vSize, vSize), cornerPaint);
    canvas.drawOval(Rect.fromLTWH(size.x - vSize/2, -vSize/2, vSize, vSize), cornerPaint);
    canvas.drawOval(Rect.fromLTWH(-vSize/2, size.y - vSize/2, vSize, vSize), cornerPaint);
    canvas.drawOval(Rect.fromLTWH(size.x - vSize/2, size.y - vSize/2, vSize, vSize), cornerPaint);
  }
  
  void _renderSpace(Canvas canvas, bool reducedGlow) {
      // User requested NO grid here as it exists in debug mode
  
      // Nebula clouds (Optimized)
      if (!reducedGlow) {
         for (final nebula in _nebulaClouds) {
             // Use solid blur style which is slightly cheaper, or reduce sigma
             canvas.drawCircle(
               nebula.position.toOffset(),
               nebula.radius,
               Paint()
                 ..color = nebula.color
                 ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14), // 40 -> 14 for GPU Optimization
             );
         }
      }
      
      // Twinkling stars (Optimized)
      // Reduced count: 120 -> 80
      // Removed MaskFilter.blur (Expensive!) -> Replaced with simple alpha transparency
      for (int i = 0; i < 80; i++) { // Reduced count
          if (i >= _stars.length) break;
          
          final twinkle = 0.4 + 0.6 * (0.5 + 0.5 * sin(_starTwinkle[i]));
          final starSize = 1.0 + (_starSpeeds[i] - 0.3) * 0.8;
          
          // Core Star (Solid)
          canvas.drawCircle(
            _stars[i].toOffset(),
            starSize,
            Paint()..color = Colors.white.withOpacity(twinkle * 0.9),
          );
          
          // Glow for brighter stars (Simple alpha circle, NO BLUR)
          if (starSize > 1.5) {
              canvas.drawCircle(
                _stars[i].toOffset(),
                starSize * 2.5,
                Paint()
                  ..color = Colors.white.withOpacity(twinkle * 0.1), // Faint halo
              );
          }
      }
  }
  
  void _renderCity(Canvas canvas, bool reducedGlow) {
      if (_skylinePath != null) {
          canvas.drawPath(_skylinePath!, _skylinePaint!);
          
          final now = DateTime.now().millisecondsSinceEpoch;
          
          for (int i = 0; i < _windows.length; i++) {
              bool on = ((now ~/ 800) + i) % 4 != 0;
              if (!on) continue;
              
              Color c = (i % 5 == 0) ? Colors.pinkAccent : (i % 7 == 0 ? Colors.cyanAccent : Colors.amber);
              canvas.drawRect(_windows[i], Paint()
                ..color = c.withOpacity(0.6)
                ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2));
          }
      }
  }
  
  void _renderOcean(Canvas canvas, bool reducedGlow) {
      if (!reducedGlow) {
          // Light rays from surface
          for (final ray in _lightRays) {
              final path = Path();
              path.moveTo(ray.x, 0);
              path.lineTo(ray.x + ray.width, 0);
              path.lineTo(ray.x + ray.width * 1.5, size.y);
              path.lineTo(ray.x - ray.width * 0.5, size.y);
              path.close();
              
              canvas.drawPath(path, Paint()
                ..color = Colors.cyan.withOpacity(ray.opacity)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
          }
      }
      
      // Bioluminescent particles
      for (final bio in _bioParticles) {
          final pulse = 0.5 + 0.5 * sin(bio.phase);
          canvas.drawCircle(
            bio.position.toOffset(),
            bio.size * pulse,
            Paint()
              ..color = bio.color.withOpacity(0.4 * pulse)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, bio.size),
          );
          canvas.drawCircle(
            bio.position.toOffset(),
            bio.size * 0.4,
            Paint()..color = bio.color.withOpacity(0.8 * pulse),
          );
      }
      
      // Fish silhouettes
      for (final fish in _fish) {
          canvas.save();
          canvas.translate(fish.position.x, fish.position.y);
          canvas.scale(fish.scale * fish.direction, fish.scale);
          
          final fishPath = Path();
          fishPath.moveTo(0, 0);
          fishPath.quadraticBezierTo(15, -8, 30, 0);
          fishPath.quadraticBezierTo(15, 8, 0, 0);
          fishPath.moveTo(30, 0);
          fishPath.lineTo(40, -6);
          fishPath.lineTo(40, 6);
          fishPath.close();
          
          canvas.drawPath(fishPath, Paint()
            ..color = Colors.black.withOpacity(0.3)
            ..style = PaintingStyle.fill);
          
          canvas.restore();
      }
      
      // Waves (Simplified to 2 layers)
      final wavePaint = Paint()..style = PaintingStyle.fill;
      
      for (int i = 0; i < 2; i++) { // Reduced from 3 to 2
          final path = Path();
          double yOffset = size.y * 0.75 + i * 40;
          double amp = 15.0 - i * 3;
          double freq = 0.012 + i * 0.004;
          double shift = _wavePhase * (1.2 + i * 0.4) + i * 80;
          
          wavePaint.color = Color.lerp(
            const Color(0xFF001850),
            const Color(0xFF004060),
            i * 0.35,
          )!.withOpacity(0.6 - i * 0.15);
          
          path.moveTo(0, size.y);
          path.lineTo(0, yOffset);
          
          for (double x = 0; x <= size.x; x += 16) { // Reduced resolution (step 8 -> 16)
              path.lineTo(x, yOffset + amp * sin(x * freq + shift));
          }
          
          path.lineTo(size.x, size.y);
          path.close();
          canvas.drawPath(path, wavePaint);
      }
  }
  
  void _generateHalloween() {
      _pumpkins.clear();
      _bats.clear();
      
      final rng = Random();
      
      // Pumpkins at bottom
      for (int i = 0; i < 6; i++) {
          _pumpkins.add(_Pumpkin(
            x: 50 + i * (size.x / 5) + rng.nextDouble() * 30,
            y: size.y - 30 - rng.nextDouble() * 20,
            scale: 0.6 + rng.nextDouble() * 0.4,
            glowPhase: rng.nextDouble() * 2 * pi,
          ));
      }
      
      // Flying bats
      for (int i = 0; i < 8; i++) {
          _bats.add(_Bat(
            position: Vector2(rng.nextDouble() * size.x, 50 + rng.nextDouble() * size.y * 0.4),
            speed: 30 + rng.nextDouble() * 40,
            scale: 0.4 + rng.nextDouble() * 0.4,
            direction: rng.nextBool() ? 1 : -1,
            wingPhase: rng.nextDouble() * 2 * pi,
            offset: rng.nextDouble() * 10,
          ));
      }
  }
  
  void _renderHalloween(Canvas canvas, bool reducedGlow) {
      // Full moon
      final moonCenter = Offset(size.x * 0.8, size.y * 0.2);
      
      // Moon glow
      if (!reducedGlow) {
        canvas.drawCircle(
          moonCenter,
          80,
          Paint()
            ..color = const Color(0xFFF5E6C8).withOpacity(0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
        );
      }
      
      // Moon body
      canvas.drawCircle(
        moonCenter,
        45,
        Paint()..color = const Color(0xFFF5E6C8),
      );
      
      // Moon craters
      canvas.drawCircle(
        moonCenter + const Offset(-10, -8),
        8,
        Paint()..color = const Color(0xFFE5D6B8),
      );
      canvas.drawCircle(
        moonCenter + const Offset(15, 10),
        5,
        Paint()..color = const Color(0xFFE5D6B8),
      );
      
      // Bare trees silhouettes
      _drawBareTree(canvas, size.x * 0.1, size.y, 120);
      _drawBareTree(canvas, size.x * 0.9, size.y, 100);
      
      // Pumpkins
      for (final pumpkin in _pumpkins) {
          final glowPulse = 0.7 + 0.3 * sin(pumpkin.glowPhase + _batPhase * 2);
          
          // Pumpkin glow
          if (!reducedGlow) {
            canvas.drawCircle(
              Offset(pumpkin.x, pumpkin.y),
              25 * pumpkin.scale,
              Paint()
                ..color = Colors.orange.withOpacity(0.3 * glowPulse)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
            );
          }
          
          // Pumpkin body
          canvas.drawOval(
            Rect.fromCenter(center: Offset(pumpkin.x, pumpkin.y), width: 30 * pumpkin.scale, height: 25 * pumpkin.scale),
            Paint()..color = const Color(0xFFFF6600),
          );
          
          // Pumpkin face (triangle eyes)
          final eyePaint = Paint()..color = Colors.yellow.withOpacity(glowPulse);
          canvas.drawPath(
            Path()
              ..moveTo(pumpkin.x - 8 * pumpkin.scale, pumpkin.y - 3 * pumpkin.scale)
              ..lineTo(pumpkin.x - 4 * pumpkin.scale, pumpkin.y - 8 * pumpkin.scale)
              ..lineTo(pumpkin.x * 1, pumpkin.y - 3 * pumpkin.scale)
              ..close(),
            eyePaint,
          );
          canvas.drawPath(
            Path()
              ..moveTo(pumpkin.x + 8 * pumpkin.scale, pumpkin.y - 3 * pumpkin.scale)
              ..lineTo(pumpkin.x + 4 * pumpkin.scale, pumpkin.y - 8 * pumpkin.scale)
              ..lineTo(pumpkin.x + 0, pumpkin.y - 3 * pumpkin.scale)
              ..close(),
            eyePaint,
          );
          
          // Smile
          canvas.drawPath(
            Path()
              ..moveTo(pumpkin.x - 8 * pumpkin.scale, pumpkin.y + 3 * pumpkin.scale)
              ..lineTo(pumpkin.x - 4 * pumpkin.scale, pumpkin.y + 6 * pumpkin.scale)
              ..lineTo(pumpkin.x, pumpkin.y + 4 * pumpkin.scale)
              ..lineTo(pumpkin.x + 4 * pumpkin.scale, pumpkin.y + 6 * pumpkin.scale)
              ..lineTo(pumpkin.x + 8 * pumpkin.scale, pumpkin.y + 3 * pumpkin.scale),
            eyePaint..style = PaintingStyle.stroke..strokeWidth = 2,
          );
          
          // Stem
          canvas.drawRect(
            Rect.fromCenter(center: Offset(pumpkin.x, pumpkin.y - 14 * pumpkin.scale), width: 4 * pumpkin.scale, height: 6 * pumpkin.scale),
            Paint()..color = const Color(0xFF2D5016),
          );
      }
      
      // Bats
      for (final bat in _bats) {
          final wingOffset = sin(bat.wingPhase) * 8;
          
          canvas.save();
          canvas.translate(bat.position.x, bat.position.y);
          canvas.scale(bat.scale * bat.direction, bat.scale);
          
          // Body
          canvas.drawOval(
            const Rect.fromLTWH(-5, -3, 10, 6),
            Paint()..color = Colors.black,
          );
          
          // Left wing
          canvas.drawPath(
            Path()
              ..moveTo(-5, 0)
              ..quadraticBezierTo(-20, -10 + wingOffset, -25, 5 + wingOffset),
            Paint()
              ..color = const Color(0xFF2a1a3a)
              ..style = PaintingStyle.fill,
          );
          
          // Right wing
          canvas.drawPath(
            Path()
              ..moveTo(5, 0)
              ..quadraticBezierTo(20, -10 + wingOffset, 25, 5 + wingOffset),
            Paint()
              ..color = const Color(0xFF2a1a3a)
              ..style = PaintingStyle.fill,
          );
          
          // Ears
          canvas.drawPath(
            Path()
              ..moveTo(-3, -3)
              ..lineTo(-5, -8)
              ..lineTo(-1, -4)
              ..close(),
            Paint()..color = Colors.black,
          );
          canvas.drawPath(
            Path()
              ..moveTo(3, -3)
              ..lineTo(5, -8)
              ..lineTo(1, -4)
              ..close(),
            Paint()..color = Colors.black,
          );
          
          canvas.restore();
      }
      
      // Purple fog at bottom
      canvas.drawRect(
        Rect.fromLTWH(0, size.y * 0.85, size.x, size.y * 0.15),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, const Color(0xFF4a1a5c).withOpacity(0.3)],
          ).createShader(Rect.fromLTWH(0, size.y * 0.85, size.x, size.y * 0.15)),
      );
  }
  
  void _drawBareTree(Canvas canvas, double x, double baseY, double height) {
      final treePaint = Paint()
        ..color = const Color(0xFF1a0a20)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      
      // Trunk
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY - height * 0.6), treePaint..strokeWidth = 6);
      
      // Branches
      canvas.drawLine(Offset(x, baseY - height * 0.4), Offset(x - 30, baseY - height * 0.7), treePaint..strokeWidth = 3);
      canvas.drawLine(Offset(x, baseY - height * 0.5), Offset(x + 25, baseY - height * 0.8), treePaint..strokeWidth = 3);
      canvas.drawLine(Offset(x, baseY - height * 0.6), Offset(x - 20, baseY - height * 0.9), treePaint..strokeWidth = 2);
      canvas.drawLine(Offset(x, baseY - height * 0.6), Offset(x + 15, baseY - height * 0.85), treePaint..strokeWidth = 2);
      
      // Sub-branches
      canvas.drawLine(Offset(x - 30, baseY - height * 0.7), Offset(x - 40, baseY - height * 0.8), treePaint..strokeWidth = 1);
      canvas.drawLine(Offset(x + 25, baseY - height * 0.8), Offset(x + 35, baseY - height * 0.9), treePaint..strokeWidth = 1);
  }
  
  void _generateAurora() {
      _auroraWaves.clear();
      
      // Create wavy aurora bands
      final colors = [
        const Color(0xFF00FF88),
        const Color(0xFF00FFCC),
        const Color(0xFF8800FF),
        const Color(0xFF00AAFF),
      ];
      
      for (int i = 0; i < 4; i++) {
          _auroraWaves.add(_AuroraWave(
            yBase: size.y * 0.15 + i * (size.y * 0.12),
            amplitude: 30 + i * 10,
            frequency: 0.008 + i * 0.002,
            speed: 0.5 + i * 0.2,
            color: colors[i],
            height: 40 + i * 15,
          ));
      }
  }
  
  void _generateGalaxy() {
      _galaxyStars.clear();
      _spiralArms.clear();
      
      final rng = Random();
      final center = Vector2(size.x * 0.5, size.y * 0.5);
      
      // Create spiral arms
      for (int arm = 0; arm < 3; arm++) {
          _spiralArms.add(_SpiralArm(
            startAngle: arm * (2 * pi / 3),
            length: 200 + rng.nextDouble() * 50,
            width: 40 + rng.nextDouble() * 20,
          ));
      }
      
      // Create stars clustered towards center
      for (int i = 0; i < 150; i++) {
          final angle = rng.nextDouble() * 2 * pi;
          final dist = pow(rng.nextDouble(), 0.5) * size.x * 0.4;
          
          _galaxyStars.add(_GalaxyStar(
            offset: Vector2(cos(angle) * dist, sin(angle) * dist),
            size: 0.5 + rng.nextDouble() * 2,
            brightness: 0.3 + rng.nextDouble() * 0.7,
            color: rng.nextDouble() > 0.8 
                ? Colors.lightBlueAccent 
                : (rng.nextDouble() > 0.5 ? Colors.amber : Colors.white),
          ));
      }
  }
  
  void _renderAurora(Canvas canvas, bool reducedGlow) {
      // Background stars
      final rng = Random(42);
      for (int i = 0; i < 80; i++) {
          canvas.drawCircle(
            Offset(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
            0.5 + rng.nextDouble() * 1,
            Paint()..color = Colors.white.withOpacity(0.3 + rng.nextDouble() * 0.4),
          );
      }
      
      // Aurora waves
      for (final wave in _auroraWaves) {
          final path = Path();
          path.moveTo(0, size.y);
          
          for (double x = 0; x <= size.x; x += 5) {
              final y = wave.yBase + wave.amplitude * sin(x * wave.frequency + _auroraPhase * wave.speed);
              if (x == 0) {
                  path.lineTo(0, y);
              } else {
                  path.lineTo(x, y);
              }
          }
          
          path.lineTo(size.x, wave.yBase - wave.height);
          
          // Draw wave with gradient
          for (double x = size.x; x >= 0; x -= 5) {
              final y = wave.yBase - wave.height + wave.amplitude * 0.5 * sin(x * wave.frequency * 1.2 + _auroraPhase * wave.speed);
              path.lineTo(x, y);
          }
          
          path.close();
          
          // Gradient fill
          canvas.drawPath(path, Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [wave.color.withOpacity(0.0), wave.color.withOpacity(0.4), wave.color.withOpacity(0.1)],
              stops: const [0.0, 0.4, 1.0],
            ).createShader(Rect.fromLTWH(0, wave.yBase - wave.height, size.x, wave.height * 2)));
          
          // Glow effect (Optimized)
          if (!reducedGlow) {
            canvas.drawPath(path, Paint()
              ..color = wave.color.withOpacity(0.2)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
          }
      }
      
      // Snow-capped mountains silhouette
      final mountains = Path();
      mountains.moveTo(0, size.y);
      mountains.lineTo(0, size.y * 0.85);
      mountains.lineTo(size.x * 0.1, size.y * 0.75);
      mountains.lineTo(size.x * 0.2, size.y * 0.85);
      mountains.lineTo(size.x * 0.35, size.y * 0.65);
      mountains.lineTo(size.x * 0.5, size.y * 0.8);
      mountains.lineTo(size.x * 0.65, size.y * 0.7);
      mountains.lineTo(size.x * 0.8, size.y * 0.82);
      mountains.lineTo(size.x * 0.9, size.y * 0.72);
      mountains.lineTo(size.x, size.y * 0.8);
      mountains.lineTo(size.x, size.y);
      mountains.close();
      
      canvas.drawPath(mountains, Paint()..color = const Color(0xFF0a0a15));
  }
  
  void _renderGalaxy(Canvas canvas, bool reducedGlow) {
      final center = Offset(size.x * 0.5, size.y * 0.5);
      
      // Bright galaxy core (Optimized)
      if (!reducedGlow) {
        canvas.drawCircle(
          center,
          60,
          Paint()
            ..color = Colors.amber.withOpacity(0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
        );
        canvas.drawCircle(
          center,
          30,
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
        );
      } else {
        // Simple core fallback
        canvas.drawCircle(center, 40, Paint()..color = Colors.amber.withOpacity(0.3));
      }
      
      canvas.drawCircle(
        center,
        10,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
      
      // Spiral arms
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(_galaxyRotation);
      
      for (final arm in _spiralArms) {
          final armPath = Path();
          
          for (double t = 0; t < 1; t += 0.02) {
              final r = t * arm.length;
              final angle = arm.startAngle + t * 3;
              final x = cos(angle) * r;
              final y = sin(angle) * r;
              
              if (t == 0) {
                  armPath.moveTo(x, y);
              } else {
                  armPath.lineTo(x, y);
              }
          }
          
          canvas.drawPath(armPath, Paint()
            ..color = Colors.purpleAccent.withOpacity(0.15)
            ..strokeWidth = arm.width
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
      }
      
      canvas.restore();
      
      // Stars
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(_galaxyRotation * 0.3);
      
      for (final star in _galaxyStars) {
          canvas.drawCircle(
            star.offset.toOffset(),
            star.size,
            Paint()..color = star.color.withOpacity(star.brightness),
          );
      }
      
      canvas.restore();
  }
}

// Helper classes 
class _NebulaCloud {
  final Vector2 position;
  final double radius;
  final Color color;
  _NebulaCloud({required this.position, required this.radius, required this.color});
}

class _Bioluminescence {
  Vector2 position;
  final double speed;
  final double size;
  final Color color;
  double phase;
  _Bioluminescence({required this.position, required this.speed, required this.size, required this.color, required this.phase});
}

class _FishSilhouette {
  Vector2 position;
  final double speed;
  final double scale;
  int direction;
  _FishSilhouette({required this.position, required this.speed, required this.scale, required this.direction});
}

class _LightRay {
  final double x;
  final double width;
  final double opacity;
  _LightRay({required this.x, required this.width, required this.opacity});
}

class _Pumpkin {
  final double x;
  final double y;
  final double scale;
  final double glowPhase;
  _Pumpkin({required this.x, required this.y, required this.scale, required this.glowPhase});
}

class _Bat {
  Vector2 position;
  final double speed;
  final double scale;
  int direction;
  double wingPhase;
  final double offset;
  _Bat({required this.position, required this.speed, required this.scale, required this.direction, required this.wingPhase, required this.offset});
}

class _AuroraWave {
  final double yBase;
  final double amplitude;
  final double frequency;
  final double speed;
  final Color color;
  final double height;
  _AuroraWave({required this.yBase, required this.amplitude, required this.frequency, required this.speed, required this.color, required this.height});
}

class _GalaxyStar {
  final Vector2 offset;
  final double size;
  final double brightness;
  final Color color;
  _GalaxyStar({required this.offset, required this.size, required this.brightness, required this.color});
}

class _SpiralArm {
  final double startAngle;
  final double length;
  final double width;
  _SpiralArm({required this.startAngle, required this.length, required this.width});
}

class _DustParticle {
  Vector2 position;
  final double velocityX;
  final double velocityY;
  final double size;
  double phase;
  final double twinkleSpeed;
  _DustParticle({
    required this.position, 
    required this.velocityX, 
    required this.velocityY, 
    required this.size, 
    required this.phase, 
    required this.twinkleSpeed
  });
}

class _ShootingStar {
  Vector2 position;
  final double angle;
  final double speed;
  double life;
  _ShootingStar({
    required Vector2 start, 
    required this.angle, 
    required this.speed, 
    required this.life
  }) : position = start.clone();
}

