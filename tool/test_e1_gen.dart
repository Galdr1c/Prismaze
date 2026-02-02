import '../lib/game/procedural/level_generator.dart';
import '../lib/game/procedural/templates/library/template_library.dart';

void main() async {
  print('Loading templates...');
  TemplateLibrary().loadAll();
  
  final generator = LevelGenerator();
  
  print('Generating 20 levels for Episode 1...');
  try {
    final templates = <String, int>{};
    for (int i = 0; i < 20; i++) {
        final level = generator.generate(1, i, i * 123);
        final tid = level.meta.templateId;
        templates[tid!] = (templates[tid] ?? 0) + 1;
        print('Generated Level $i: $tid');
    }
    
    print('Summary:');
    templates.forEach((k, v) => print('$k: $v'));
    
    if (templates.length > 1) {
        print('SUCCESS: Variety achieved.');
    } else {
        print('FAILURE: Only one template used.');
    }
    
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
