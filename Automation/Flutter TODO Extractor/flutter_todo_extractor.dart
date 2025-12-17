import 'dart:io';

void main() {
  final Directory libDir = Directory('lib');
  final File outputFile = File('TODO_REPORT.md');

  if (!libDir.existsSync()) {
    print('❌ lib folder not found');
    return;
  }

  final StringBuffer buffer = StringBuffer();
  buffer.writeln('# 📝 TODO / FIXME Report\n');
  buffer.writeln('Generated at: ${DateTime.now()}\n');

  int total = 0;

  for (FileSystemEntity file in libDir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final List<String> lines = file.readAsLinesSync();

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];

        if (line.contains('TODO') || line.contains('FIXME')) {
          total++;

          buffer.writeln('### 📄 ${file.path.replaceAll('\\', '/')}');
          buffer.writeln('- Line ${i + 1}: `${line.trim()}`\n');
        }
      }
    }
  }

  buffer.writeln('---');
  buffer.writeln('🔢 Total TODOs: $total');

  outputFile.writeAsStringSync(buffer.toString());

  print('✅ TODO report generated: TODO_REPORT.md');
  print('🔢 Total TODOs found: $total');
}
