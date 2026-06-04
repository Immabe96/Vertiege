import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/invite_service.dart';

void main() {
  group('InviteService links', () {
    test('invitePath encodes code', () {
      expect(InviteService.invitePath('ABC123'), '/invite/ABC123');
    });

    test('inviteDeepLink uses vertiege scheme', () {
      expect(
        InviteService.inviteDeepLink('ABC123'),
        'vertiege://invite/ABC123',
      );
    });
  });

  group('InviteRedeemResult', () {
    test('succeeded when worldId set', () {
      const r = InviteRedeemResult(worldId: 'world-1');
      expect(r.succeeded, isTrue);
      expect(r.errorMessage, isNull);
    });

    test('not succeeded on error', () {
      const r = InviteRedeemResult(errorMessage: 'nope');
      expect(r.succeeded, isFalse);
    });
  });
}
