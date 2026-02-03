import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/templates/templates.dart';
import 'package:prismaze/core/models/models.dart';

void main() {
  group('TemplateCatalog', () {
    test('getTemplate returns valid VerticalCorridor.v0', () {
      final template = TemplateCatalog.getTemplate(TemplateFamily.verticalCorridor, 0);
      
      expect(template.family, equals(TemplateFamily.verticalCorridor));
      expect(template.variantId, equals(0));
      expect(template.anchors, isNotEmpty);
      expect(template.wallPresets, isNotEmpty);
      expect(template.solutionSteps, isNotEmpty);
      
      // Verify Source is present
      final source = template.anchors.firstWhere((a) => a.type == 'source');
      expect(source.position, equals(const GridPosition(2, 1)));
      
      // Verify Target is present
      final target = template.anchors.firstWhere((a) => a.type == 'target');
      expect(target.position, equals(const GridPosition(2, 10)));
    });

    test('All SolutionSteps have descriptions', () {
      final template = TemplateCatalog.getTemplate(TemplateFamily.verticalCorridor, 0);
      for (var step in template.solutionSteps) {
        expect(step.description, isNotEmpty);
      }
    });

    test('Variant Retrieval Fallback (Development Only)', () {
      // Currently requesting v1 returns v0 as fallback check
      final template = TemplateCatalog.getTemplate(TemplateFamily.verticalCorridor, 1);
      expect(template.variantId, equals(0)); // Should be 0 until implemented
    });
  });
}
