import '../models/resident.dart';

/// Supabase `verification_submissions.profession` keys for government ID review.
abstract final class IdentityVerification {
  static const String passportProfession = 'resident-identity-passport';
  static const String nationalIdProfession = 'resident-identity-national-id';

  static const Set<String> professionKeys = {
    passportProfession,
    nationalIdProfession,
  };

  static bool isIdentityProfession(String? profession) {
    if (profession == null || profession.isEmpty) return false;
    return professionKeys.contains(profession) ||
        profession == 'resident-identity';
  }

  static bool isVerified(Resident resident) =>
      resident.verifiedRoles.any(isIdentityProfession);

  static String labelForProfession(String profession) => switch (profession) {
        passportProfession => 'Passport',
        nationalIdProfession => 'National ID card',
        'resident-identity' => 'Government ID',
        _ => profession,
      };
}

enum IdentityDocumentType { passport, nationalId }

extension IdentityDocumentTypeX on IdentityDocumentType {
  String get professionKey => switch (this) {
        IdentityDocumentType.passport =>
          IdentityVerification.passportProfession,
        IdentityDocumentType.nationalId =>
          IdentityVerification.nationalIdProfession,
      };

  String get label => switch (this) {
        IdentityDocumentType.passport => 'Passport',
        IdentityDocumentType.nationalId => 'National identity card',
      };
}
