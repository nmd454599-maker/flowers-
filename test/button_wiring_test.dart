import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interactive callbacks are not empty', () {
    final emptyCallback = RegExp(
      r'on(?:Pressed|Tap)\s*:\s*\(\s*\)\s*\{\s*\}',
      multiLine: true,
    );
    final violations = <String>[];
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      if (emptyCallback.hasMatch(file.readAsStringSync())) {
        violations.add(file.path);
      }
    }
    expect(violations, isEmpty,
        reason: 'Empty button callbacks found in: ${violations.join(', ')}');
  });
}
