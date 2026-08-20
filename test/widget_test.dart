import 'package:flutter_test/flutter_test.dart';

import 'package:dev_orbit_next/src/domain/json_transformer.dart';
import 'package:dev_orbit_next/src/domain/sql_log_converter.dart';
import 'package:dev_orbit_next/src/domain/text_compare_engine.dart';
import 'package:dev_orbit_next/src/domain/text_compare_models.dart';
import 'package:dev_orbit_next/src/domain/timestamp_converter.dart';

void main() {
  test('timestamp conversion stays inside the domain layer', () {
    final result = TimestampConverter.parseTimestamp('0');
    expect(result.dateTime.millisecondsSinceEpoch, 0);
    expect(
      TimestampConverter.formatDateTime(result.dateTime),
      startsWith('1970-01-01'),
    );
  });

  test('json transformer does not need clipboard state', () async {
    final result = await const JsonTransformer().run(
      '{"ok":true,"items":[1,2]}',
      JsonTransformMode.format,
    );
    expect(result.isValid, isTrue);
    expect(result.output, contains('\n'));
  });

  test('sql log converter substitutes typed parameters', () {
    const source =
        'Preparing: SELECT * FROM users WHERE id = ? AND active = ?\n'
        'Parameters: 42(Integer), true(Boolean)';
    final result = const SqlLogConverter().convert(source);
    expect(result.output, contains('42'));
    expect(result.output, contains('TRUE'));
    expect(result.warningCount, 0);
  });

  test('text comparison returns added line counts', () {
    final result = const TextCompareEngine().compare(
      left: 'one\ntwo',
      right: 'one\ntwo\nthree',
      options: const TextCompareOptions(),
    );
    expect(result.addedCount, 1);
    expect(result.hasChanges, isTrue);
  });
}
