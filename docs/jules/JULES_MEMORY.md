# Vertiege Jules Memory

Use this as persistent operating context for every Jules task in this repo.

## Repo And Product
- Vertiege is a Flutter mobile app on GitHub branch `main`.
- The current branch is the source of truth. Do not base work on stale branches.
- Supabase is the source of truth for app data and auth.
- Firebase, if present, is infrastructure-only: FCM, Crashlytics, Analytics, Remote Config. Do not move content data to Firestore or Firebase Realtime Database.
- Android release builds require JDK 21. In GitHub Actions use `actions/setup-java@v4` with Temurin 21.

## Design Direction
- UI should be compact, minimal, Forui-led, and mobile-friendly.
- Light theme: white/minimal surfaces with dark readable text.
- Dark theme: AMOLED black with high-contrast readable text.
- Avoid heavy glass, harsh blur, decorative gradients, and oversized hero typography inside app surfaces.
- Images should stay natural. Use only subtle bottom scrims when text overlays image content.
- Empty states should be clean Forui-style icon/title/body/CTA layouts, not noisy raster art.

## Hard Safety Rules
- Generate a plan and wait for explicit approval when a task says plan approval is required.
- Do not auto-approve your own plan.
- Do not open a PR until required verification has passed or the PR clearly documents the failed command and why it is acceptable.
- Never create scratch/test files in the repo root such as `diff.txt`, shell replacement scripts, or `test_fcard*.dart`.
- Do not use broad regex replacements or mechanical app-wide rewrites.
- Do not pass unsupported constructor parameters to Forui widgets. If padding is needed, wrap the child in `Padding`.
- Keep edits within the explicit task scope. If another file seems necessary, explain why before touching it.
- Do not change Supabase migrations from UI-only tasks.
- Do not redesign UI from backend/data tasks.
- Do not return fake success for failed Supabase/auth mutations.

## Verification Expectations
- For Dart changes run `flutter analyze --no-fatal-infos --no-fatal-warnings` and `flutter test`.
- For major or build-sensitive changes also run `flutter build apk --release`, or rely on GitHub Actions and mention the run.
- Analyzer warnings may exist in this repo, but tests and APK build must still pass before a PR is considered mergeable.
- Any PR with compile errors, root scratch files, broken callbacks, or unrelated broad churn should be treated as failed.

## Current Known Coordination
- Codex is the reviewer/merger. Jules should do scoped implementation work and produce PRs for Codex review.
- Previously a broad Jules UI pass produced unsafe scratch files and broken partial Forui replacements. Avoid repeating that pattern.
- Prefer small independent PRs:
  - Supabase migration/RLS fixes
  - default worlds and starter channels
  - onboarding/world-join reliability
  - feed 42501 fixes
  - focused Forui UI passes
