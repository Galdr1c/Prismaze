import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/settings_manager.dart';
import '../game/audio_manager.dart';

class DebugFpsOverlay extends StatefulWidget {
  final int sampleSize;
  final Duration refreshInterval;
  final SettingsManager? settingsManager;

  const DebugFpsOverlay({
    super.key,
    this.sampleSize = 60,
    this.refreshInterval = const Duration(milliseconds: 250),
    this.settingsManager,
  });

  @override
  State<DebugFpsOverlay> createState() => _DebugFpsOverlayState();
}

class _DebugFpsOverlayState extends State<DebugFpsOverlay> {
  final ListQueue<FrameTiming> _samples = ListQueue<FrameTiming>();
  late final TimingsCallback _callback;
  
  // Real FPS Calculation
  final Stopwatch _sec = Stopwatch()..start();
  int _framesInSec = 0;
  double _realFps = 0;

  @override
  void initState() {
    super.initState();

    _callback = (List<FrameTiming> timings) {
      _framesInSec += timings.length;
      
      for (final t in timings) {
        _samples.addLast(t);
        while (_samples.length > widget.sampleSize) {
          _samples.removeFirst();
        }
      }

      final elapsedMs = _sec.elapsedMilliseconds;
      if (elapsedMs >= 1000) {
        _realFps = _framesInSec * 1000.0 / elapsedMs;
        _framesInSec = 0;
        _sec.reset();
        _sec.start();
        if (mounted) setState(() {});
      }
    };

    SchedulerBinding.instance.addTimingsCallback(_callback);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_callback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_samples.isEmpty) return const SizedBox.shrink();

    double avgTotalMs = 0;
    double avgUiMs = 0;
    double avgGpuMs = 0;

    for (final t in _samples) {
      avgTotalMs += t.totalSpan.inMicroseconds / 1000.0;
      avgUiMs += t.buildDuration.inMicroseconds / 1000.0;
      avgGpuMs += t.rasterDuration.inMicroseconds / 1000.0;
    }

    final n = _samples.length;
    if (n > 0) {
        avgTotalMs /= n;
        avgUiMs /= n;
        avgGpuMs /= n;
    }
    
    // Additional metrics
    final sfxCount = AudioManager().debugActiveSfxCount;
    final reducedGlow = widget.settingsManager?.reducedGlowEnabled ?? false;
    final highContrast = widget.settingsManager?.highContrastEnabled ?? false;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 12, color: Colors.white, height: 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FPS: ${_realFps.toStringAsFixed(1)}', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: _realFps < 30 ? Colors.redAccent : Colors.greenAccent)),
              Text('UI: ${avgUiMs.toStringAsFixed(1)}ms  GPU: ${avgGpuMs.toStringAsFixed(1)}ms'),
              Text('Frame: ${avgTotalMs.toStringAsFixed(1)}ms'),
              const SizedBox(height: 4),
              Text('SFX Active: $sfxCount ${AudioManager().debugActiveSfxNames.join(", ")}'),
              Text('Reduced Glow: ${reducedGlow ? "ON" : "OFF"}', 
                  style: TextStyle(color: reducedGlow ? Colors.yellowAccent : Colors.white)),
              Text('High Contrast: ${highContrast ? "ON" : "OFF"}'),
            ],
          ),
        ),
      ),
    );
  }
}
