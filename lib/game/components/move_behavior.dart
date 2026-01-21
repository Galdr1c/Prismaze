import 'package:flame/components.dart';

class MoveBehavior extends Component {
  final List<Vector2> waypoints;
  final double speed;
  
  int _targetIndex = 0;
  bool _forward = true;
  
  MoveBehavior({
    required this.waypoints,
    this.speed = 100.0,
  });

  @override
  void update(double dt) {
    if (parent is! PositionComponent) return;
    if (waypoints.isEmpty) return;
    
    final p = parent as PositionComponent;
    final target = waypoints[_targetIndex];
    
    final dir = target - p.position;
    final dist = dir.length;
    
    if (dist < speed * dt) {
        // Reached waypoint
        p.position = target;
        
        // Loop or PingPong? "Preset path" usually implies cycling or ping-pong.
        // Let's do PingPong
        if (_forward) {
            _targetIndex++;
            if (_targetIndex >= waypoints.length) {
                _targetIndex = waypoints.length - 2;
                _forward = false;
            }
        } else {
            _targetIndex--;
            if (_targetIndex < 0) {
                _targetIndex = 1;
                _forward = true;
            }
        }
    } else {
        dir.normalize();
        p.position += dir * speed * dt;
    }
  }
}
