import 'package:flame/components.dart';
import '../prismaze_game.dart';

class HintManager extends Component with HasGameRef<PrismazeGame> {
  bool get isShowingHint => false;
  
  void showLightHint({dynamic onComplete}) {
    // Stub
  }
}

class HintHighlightEffect extends PositionComponent {
  final PositionComponent target;
  final dynamic moveType;
  HintHighlightEffect({required this.target, this.moveType});
}
