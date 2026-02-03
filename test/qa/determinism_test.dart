import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/generator/generator.dart';
import 'package:prismaze/core/models/models.dart';
import 'package:prismaze/generator/validators/readability_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('QA Determinism & Metrics Suite', () {
    late GeneratorPipeline pipeline;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      pipeline = GeneratorPipeline();
    });

    test('Verify 100 random levels are perfectly deterministic (10x runs each)', () async {
      final int levelCount = 100;
      final int iterationsPerLevel = 10;
      final String version = 'v1';

      for (int i = 1; i <= levelCount; i++) {
        final referenceLevel = await pipeline.generateLevel(version: version, levelIndex: i);
        final referenceSignature = _computeLevelSignature(referenceLevel);

        for (int iter = 0; iter < iterationsPerLevel; iter++) {
          final testLevel = await pipeline.generateLevel(version: version, levelIndex: i);
          final testSignature = _computeLevelSignature(testLevel);

          expect(testSignature, equals(referenceSignature));
        }
      }
    });

    test('Generate Distribution Metrics (1000 levels)', () async {
      final int totalLevels = 1000;
      final String version = 'v1';
      
      print('--- Metric Generation for 1000 levels ($version) ---');
      
      final familyCounts = <TemplateFamily, int>{};
      final templateUsage = <String, int>{};
      final silhouetteHashes = <String>{};
      final cooldownViolations = <String, List<int>>{};
      
      Map<String, int> lastUsedAt = {};

      for (int i = 1; i <= totalLevels; i++) {
        final level = await pipeline.generateLevel(version: version, levelIndex: i);
        final family = level.template.family;
        final templateId = "${family.name}_${level.template.variantId}";
        
        familyCounts[family] = (familyCounts[family] ?? 0) + 1;
        templateUsage[templateId] = (templateUsage[templateId] ?? 0) + 1;
        
        // Track unique silhouettes (walls + distribution)
        final sHash = ReadabilityValidator.calculateSilhouetteHash(level);
        silhouetteHashes.add(sHash);

        if (lastUsedAt.containsKey(templateId)) {
          final distance = i - lastUsedAt[templateId]!;
          if (distance < 3) {
            cooldownViolations.putIfAbsent(templateId, () => []).add(i);
          }
        }
        lastUsedAt[templateId] = i;
      }

      print('\n[Family Distribution]');
      familyCounts.forEach((family, count) {
        print('${family.name.padRight(20)}: $count (${(count/totalLevels*100).toStringAsFixed(1)}%)');
      });

      print('\n[Silhouette Uniqueness]');
      final double uniqueRatio = silhouetteHashes.length / totalLevels;
      print('Unique Silhouettes: ${silhouetteHashes.length} / $totalLevels (${(uniqueRatio * 100).toStringAsFixed(1)}%)');
      if (uniqueRatio < 0.2) {
        print('⚠️ WARNING: Low silhouette diversity detected!');
      } else {
        print('✅ Good silhouette variety.');
      }

      print('\n[Cooldown Status]');
      if (cooldownViolations.isEmpty) {
        print('✅ No cooldown violations detected.');
      } else {
        print('⚠️ Cooldown violations found!');
        cooldownViolations.forEach((id, levels) {
          print('  - $id at levels: $levels');
        });
      }
    });
  });
}

String _computeLevelSignature(GeneratedLevel level) {
  final buffer = StringBuffer();
  buffer.writeln('LevelID: ${level.id}');
  buffer.writeln('Seed: ${level.seed}');
  buffer.writeln('Template: ${level.template.family.name}-${level.template.variantId}');
  for (final obj in level.objects) {
    buffer.writeln(obj.toString());
  }
  return buffer.toString();
}
