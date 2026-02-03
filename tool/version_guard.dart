import 'dart:io';

/// Version Bump Guard
/// Fails if lib/generator/templates has changed but the version hasn't been bumped.
void main() {
  const currentVersion = 'v1'; // This should ideally be read from a config or RecipeDeriver
  final lockFile = File('tool/template_version.lock');
  
  final currentHash = _calculateDirHash('lib/generator/templates');
  
  if (!lockFile.existsSync()) {
    print('Initial run. Recording hash $currentHash for version $currentVersion.');
    lockFile.writeAsStringSync('$currentVersion:$currentHash');
    return;
  }
  
  final content = lockFile.readAsStringSync().split(':');
  if (content.length < 2) {
    print('Corrupt lock file. Resetting.');
    lockFile.writeAsStringSync('$currentVersion:$currentHash');
    return;
  }
  
  final lastVersion = content[0];
  final lastHash = content[1];
  
  if (currentHash != lastHash) {
    if (currentVersion == lastVersion) {
      print('CRITICAL: Templates changed but version is still $currentVersion!');
      print('Action: Bump version in RecipeDeriver and update QA scripts.');
      exit(1);
    } else {
      print('Detected version bump from $lastVersion to $currentVersion. Updating hash.');
      lockFile.writeAsStringSync('$currentVersion:$currentHash');
    }
  } else {
    print('Templates unchanged for version $currentVersion. OK.');
  }
}

String _calculateDirHash(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return 'not_found';
  final files = dir.listSync(recursive: true).whereType<File>().toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  
  int hash = 0;
  for (var file in files) {
    final content = file.readAsStringSync();
    for (int i = 0; i < content.length; i++) {
        hash = (31 * hash + content.codeUnitAt(i)) & 0xFFFFFFFF;
    }
  }
  return hash.toUnsigned(32).toRadixString(16);
}
