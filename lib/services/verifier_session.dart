/// True after signing in via `/verifier/login`; cleared on consumer login or sign-out.
class VerifierSession {
  VerifierSession._();

  static bool active = false;

  static void enter() => active = true;

  static void exit() => active = false;
}
