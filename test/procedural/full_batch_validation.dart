import 'package:flutter_test/flutter_test.dart';
import 'package:prismaze/game/procedural/batch_validator.dart';
import 'dart:io';

void main() {
  test('Full Batch Validation', () {
    print('Starting Full Batch Validation...');
    final validator = BatchValidator();
    
    final reports = validator.validateAll(
      levelsPerEpisode: 20, // Quick validation of 20 levels per episode
      onProgress: (ep, cur, total) {
        print('Episode $ep: $cur/$total');
      },
    );
    
    final markdown = validator.generateMarkdownReport(
      reports,
      title: 'PrisMaze Full Campaign Validation Report',
    );
    
    final dir = Directory('lib/tools/logs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    
    final file = File('lib/tools/logs/full_campaign_validation_report.md');
    file.writeAsStringSync(markdown);
    
    print('\nValidation Complete!');
    print('Report saved to ${file.path}');
    expect(reports.length, equals(5));
  });
}
