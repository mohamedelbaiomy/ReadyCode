import 'dart:convert';
import 'dart:io';

/// Usage:
/// dart tools/smart_build_appbundle.dart --patch
/// dart tools/smart_build_appbundle.dart --minor
/// dart tools/smart_build_appbundle.dart --major

/// dart tools/smart_build_appbundle.dart --patch--minor

void main(List<String> args) {
  final File pubspec = File('pubspec.yaml');

  if (!pubspec.existsSync()) {
    _exit('❌ pubspec.yaml not found');
  }

  final List<String> lines = pubspec.readAsLinesSync();
  final int versionIndex = lines.indexWhere(
    (String l) => l.trim().startsWith('version:'),
  );

  if (versionIndex == -1) {
    _exit('❌ version not found in pubspec.yaml');
  }

  final String oldLine = lines[versionIndex];
  final String oldVersion = oldLine.split(':').last.trim();

  // version format: x.y.z+build
  final List<String> parts = oldVersion.split('+');
  final List<String> versionParts = parts[0].split('.');

  int major = int.parse(versionParts[0]);
  int minor = int.parse(versionParts[1]);
  int patch = int.parse(versionParts[2]);
  int build = parts.length > 1 ? int.parse(parts[1]) : 0;

  bool versionUpdated = false;

  // 🔧 Version increment
  if (args.contains('--major')) {
    major++;
    minor = 0;
    patch = 0;
    versionUpdated = true;
  } else if (args.contains('--minor')) {
    minor++;
    patch = 0;
    versionUpdated = true;
  } else if (args.contains('--patch')) {
    patch++;
    versionUpdated = true;
  }

  // 🚫 Block build if no version update
  if (!versionUpdated) {
    _exit('🚫 Build blocked: You must provide --major, --minor, or --patch');
  }

  // 🔢 Normal build increment
  build++;

  final String newVersion = '$major.$minor.$patch+$build';
  lines[versionIndex] = 'version: $newVersion';

  pubspec.writeAsStringSync(lines.join('\n'));

  print('✅ Version updated');
  print('🔁 $oldVersion → $newVersion');

  print('🔧 Running build commands');
  // 🚀 Flutter build
  _runCommand('flutter', <String>['build', 'appbundle', '--release']);

  print('🎉 Build completed successfully');
}

void _runCommand(String cmd, List<String> args) {
  final ProcessResult result = Process.runSync(
    cmd,
    args,
    runInShell: true,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    _exit('❌ Build failed');
  }
}

Never _exit(String message) {
  print(message);
  exit(1);
}
