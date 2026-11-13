import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_triage/core/util/time_ago.dart';

void main() {
  test('tiempo transcurrido corto', () {
    final now = DateTime(2026, 11, 12, 12);
    String ago(Duration d) => timeAgo(now.subtract(d), now: now);
    expect(ago(const Duration(seconds: 30)), 'ahora');
    expect(ago(const Duration(minutes: 2)), 'hace 2 min');
    expect(ago(const Duration(hours: 3)), 'hace 3 h');
    expect(ago(const Duration(days: 2)), 'hace 2 d');
  });
}
