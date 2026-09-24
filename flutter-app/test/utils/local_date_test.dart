import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/local_date.dart';

void main() {
  test('localDateKey uses calendar date', () {
    final dt = DateTime(2026, 5, 30, 23, 59);
    expect(localDateKey(dt), '2026-05-30');
  });

  test('deviceTimezoneLabel encodes offset label', () {
    expect(deviceTimezoneLabel(), matches(RegExp(r'^UTC[+-]\d{2}:\d{2}$')));
  });
}
