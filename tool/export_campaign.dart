/// Campaign Level Export Tool (Standalone)
///
/// Offline Dart tool to export generated campaign levels as JSON files.
/// These files are shipped as Flutter assets.
///
/// Usage:
///   dart tool/export_campaign.dart --episode 3 --count 100 --seed 100000
///
/// Must be run with: flutter test tool/export_campaign_test.dart
/// (Because it needs Flutter test environment for package imports)

// This file must be run via flutter test, not dart run
// See tool/run_export.dart for the actual implementation

void main() {
  print('ERROR: This tool must be run via flutter test');
  print('');
  print('Usage:');
  print('  flutter test tool/export_campaign_runner.dart --no-pub');
  print('');
  print('Or use the batch script:');
  print('  tool\\export_all.bat');
}
