import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/deep_link_redirects.dart';

void main() {
  test('redirectResidentsHostDeepLink maps host to path', () {
    final uri = Uri.parse('vertiege://residents/user-1?achievement=edu-hs');
    expect(
      redirectResidentsHostDeepLink(uri, '/'),
      '/residents/user-1?achievement=edu-hs',
    );
  });

  test('redirectResidentsHostDeepLink skips when already on path', () {
    final uri = Uri.parse('vertiege://residents/user-1');
    expect(
      redirectResidentsHostDeepLink(uri, '/residents/user-1'),
      isNull,
    );
  });
}
