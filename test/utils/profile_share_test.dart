import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/profile_share.dart';

void main() {
  test('profileDeepLink uses vertiege residents scheme', () {
    final uri = ProfileShare.profileDeepLink('abc123');
    expect(uri.scheme, 'vertiege');
    expect(uri.host, 'residents');
    expect(uri.pathSegments, ['abc123']);
  });

  test('shareMessage includes achievement query when set', () {
    final msg = ProfileShare.shareMessage(
      name: 'Alex',
      residentId: 'abc123',
      achievementId: 'edu-hs',
    );
    expect(msg, contains('Alex'));
    expect(msg, contains('achievement=edu-hs'));
  });
}
