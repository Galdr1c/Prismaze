// Level Generator Tool - Run with: dart run lib/tools/generate_levels.dart
import 'dart:io';
import '../game/campaign_level_generator.dart';

void main() async {
  print('🎮 PrisMaze Level Generator');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  
  final generator = CampaignLevelGenerator();
  
  // Generate all levels
  print('Generating 100 campaign levels...');
  final json = generator.exportAsJson();
  
  // Save to file
  final outputFile = File('assets/levels/campaign_levels.json');
  await outputFile.writeAsString(json);
  
  print('✅ Saved to: ${outputFile.path}');
  print('✅ Total levels: 100');
  
  // Also generate individual level files
  print('\nGenerating individual level files...');
  final levels = generator.generateAllLevels();
  
  for (final level in levels) {
    final id = level['id'] as int;
    final file = File('assets/levels/level_$id.json');
    await file.writeAsString(_formatJson(level));
  }
  
  print('✅ Generated ${levels.length} individual level files');
  print('\n🎉 Level generation complete!');
}

String _formatJson(Map<String, dynamic> data) {
  final buffer = StringBuffer();
  buffer.writeln('{');
  
  data.forEach((key, value) {
    if (value is List) {
      buffer.writeln('  "$key": [');
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          buffer.write('    {');
          final entries = item.entries.toList();
          for (int j = 0; j < entries.length; j++) {
            final e = entries[j];
            buffer.write('"${e.key}": ${_valueToJson(e.value)}');
            if (j < entries.length - 1) buffer.write(', ');
          }
          buffer.write('}');
        } else {
          buffer.write('    ${_valueToJson(item)}');
        }
        if (i < value.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.writeln('  ],');
    } else {
      buffer.writeln('  "$key": ${_valueToJson(value)},');
    }
  });
  
  // Remove trailing comma
  var result = buffer.toString();
  final lastComma = result.lastIndexOf(',');
  if (lastComma > 0) {
    result = result.substring(0, lastComma) + result.substring(lastComma + 1);
  }
  
  return result + '}';
}

String _valueToJson(dynamic value) {
  if (value is String) return '"$value"';
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  if (value is List) return '[${value.map(_valueToJson).join(', ')}]';
  return value.toString();
}
