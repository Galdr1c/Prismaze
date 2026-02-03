import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/core/models/models.dart';

// Concrete implementation for testing abstract GameObject
class TestGameObject extends GameObject {
  const TestGameObject({
    required super.position,
    super.orientation,
    super.rotatable,
  });

  @override
  GameObject copyWith({GridPosition? position, int? orientation, bool? rotatable}) {
    return TestGameObject(
      position: position ?? this.position,
      orientation: orientation ?? this.orientation,
      rotatable: rotatable ?? this.rotatable,
    );
  }

  @override
  GameObject moveTo(GridPosition newPosition) {
    return copyWith(position: newPosition);
  }
}

void main() {
  group('GridPosition', () {
    test('Equality and HashCode are deterministic', () {
      const p1 = GridPosition(2, 3);
      const p2 = GridPosition(2, 3);
      const p3 = GridPosition(2, 4);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.hashCode, isNot(equals(p3.hashCode)));
    });

    test('step works correctly', () {
      const start = GridPosition(1, 1);
      
      expect(start.step(Direction.north), equals(const GridPosition(1, 0)));
      expect(start.step(Direction.east), equals(const GridPosition(2, 1)));
      expect(start.step(Direction.south), equals(const GridPosition(1, 2)));
      expect(start.step(Direction.west), equals(const GridPosition(0, 1)));
    });

    test('isValid bounds check', () {
      expect(const GridPosition(0, 0).isValid, isTrue);
      expect(const GridPosition(5, 11).isValid, isTrue);
      expect(const GridPosition(-1, 0).isValid, isFalse);
      expect(const GridPosition(0, -1).isValid, isFalse);
      expect(const GridPosition(6, 0).isValid, isFalse);
      expect(const GridPosition(0, 12).isValid, isFalse);
    });
  });

  group('Direction', () {
    test('Rotation logic', () {
      expect(Direction.north.rotateRight, equals(Direction.east));
      expect(Direction.east.rotateRight, equals(Direction.south));
      expect(Direction.south.rotateRight, equals(Direction.west));
      expect(Direction.west.rotateRight, equals(Direction.north));

      expect(Direction.north.rotateLeft, equals(Direction.west));
    });

    test('Opposite logic', () {
      expect(Direction.north.opposite, equals(Direction.south));
      expect(Direction.east.opposite, equals(Direction.west));
    });
  });

  group('LightColor', () {
    test('Mixing logic', () {
      expect(LightColor.red.mix(LightColor.blue), equals(LightColor.purple));
      expect(LightColor.red.mix(LightColor.green), equals(LightColor.yellow));
      expect(LightColor.green.mix(LightColor.blue), equals(LightColor.cyan));
      expect(LightColor.red.mix(LightColor.green).mix(LightColor.blue), equals(LightColor.white));
    });

    test('Contains logic', () {
      expect(LightColor.purple.contains(LightColor.red), isTrue);
      expect(LightColor.purple.contains(LightColor.blue), isTrue);
      expect(LightColor.purple.contains(LightColor.green), isFalse);
    });
  });

  group('GameObject', () {
    test('Equality based on properties', () {
      final obj1 = TestGameObject(position: const GridPosition(1, 1), orientation: 0);
      final obj2 = TestGameObject(position: const GridPosition(1, 1), orientation: 0);
      final obj3 = TestGameObject(position: const GridPosition(1, 1), orientation: 1);

      expect(obj1, equals(obj2));
      expect(obj1.hashCode, equals(obj2.hashCode));
      expect(obj1, isNot(equals(obj3)));
    });

    test('Rotation respects rotatable flag', () {
      // Rotatable
      final objRot = TestGameObject(position: const GridPosition(0, 0), rotatable: true);
      expect(objRot.rotateRight().orientation, equals(1));
      
      // Not rotatable
      final objFixed = TestGameObject(position: const GridPosition(0, 0), rotatable: false);
      expect(objFixed.rotateRight().orientation, equals(0));
      
      // Forced rotation
      expect(objFixed.rotateRight(force: true).orientation, equals(1));
    });
  });
}
