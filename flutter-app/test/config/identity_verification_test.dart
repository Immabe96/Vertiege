import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/identity_verification.dart';
import 'package:vertiege/models/resident.dart';

void main() {
  test('identity verification profession detection', () {
    expect(
      IdentityVerification.isIdentityProfession(
        IdentityVerification.passportProfession,
      ),
      isTrue,
    );
    expect(IdentityVerification.isIdentityProfession('Aviation'), isFalse);
  });

  test('isVerified when resident has identity role', () {
    const resident = Resident(
      id: 'r1',
      name: 'Test',
      verifiedRoles: [IdentityVerification.nationalIdProfession],
    );
    expect(IdentityVerification.isVerified(resident), isTrue);
  });
}
