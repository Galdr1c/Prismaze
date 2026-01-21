import 'package:flutter/material.dart';
import '../game/localization_manager.dart';

class VideoGuideOverlay extends StatefulWidget {
  final String videoId;
  final VoidCallback onComplete;

  const VideoGuideOverlay({super.key, required this.videoId, required this.onComplete});

  @override
  State<VideoGuideOverlay> createState() => _VideoGuideOverlayState();
}

class _VideoGuideOverlayState extends State<VideoGuideOverlay> {
  bool _isPlaying = false;
  double _progress = 0.0;
  
  Map<String, dynamic> get _videoInfo {
      switch(widget.videoId) {
          case 'welcome': return {'title': 'PrisMaze\'e Hoş Geldin', 'duration': 3}; // Short for testing (30s real)
          case 'mixing_guide': return {'title': 'Renk Karıştırma Rehberi', 'duration': 4}; // 45s real
          case 'advanced_tactics': return {'title': 'İleri Seviye Taktikler', 'duration': 5}; // 60s real
          default: return {'title': 'Rehber', 'duration': 3};
      }
  }

  @override
  Widget build(BuildContext context) {
    final info = _videoInfo;
    final int duration = info['duration'];
    
    return Container(
      color: Colors.black.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(info['title'], style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Orbitron')),
            const SizedBox(height: 20),
            
            // Mock Player
            Container(
                width: 300,
                height: 180,
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.purpleAccent)),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                        if (!_isPlaying && _progress == 0)
                           IconButton(
                               icon: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                               onPressed: _startVideo,
                           ),
                        if (_isPlaying)
                           Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                   const CircularProgressIndicator(color: Colors.purpleAccent),
                                   const SizedBox(height: 10),
                                   Text(LocalizationManager().getStringParam('video_playing_time', {'time': '${(duration * _progress).toInt()}'}), style: const TextStyle(color: Colors.white54)),
                               ],
                           ),
                       if (!_isPlaying && _progress >= 1.0)
                           const Icon(Icons.check_circle, size: 64, color: Colors.greenAccent),
                    ],
                ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress, backgroundColor: Colors.white10, color: Colors.purpleAccent),
            const SizedBox(height: 20),
            if (_progress >= 1.0)
                ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                    child: Text(LocalizationManager().getString('vid_continue'), style: const TextStyle(color: Colors.black)),
                )
            else
                TextButton(
                    onPressed: widget.onComplete, // Allow skip?
                    child: Text(LocalizationManager().getString('video_skip'), style: const TextStyle(color: Colors.white30)),
                ),
          ],
        ),
      ),
    );
  }
  
  void _startVideo() async {
      setState(() => _isPlaying = true);
      final duration = _videoInfo['duration'] as int;
      final steps = 50;
      final dt = (duration * 1000) ~/ steps;
      
      for(int i=0; i<=steps; i++) {
          if (!mounted) return;
          await Future.delayed(Duration(milliseconds: dt));
          setState(() {
              _progress = i / steps;
          });
      }
      
      if(mounted) setState(() => _isPlaying = false);
  }
}
