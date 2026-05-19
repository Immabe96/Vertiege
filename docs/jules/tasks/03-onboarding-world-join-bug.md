# Jules Task 03: Onboarding And World Join Reliability

## Plan Approval Required
Generate a plan first and wait for explicit approval before implementation. Do not auto-approve your own plan and do not open a PR until the plan has been approved.

## Goal
Fix the issue where users cannot enter the first starter world and get redirected back to Nexus.

## Scope
Allowed to touch:
- `lib/screens/onboarding/**`
- `lib/screens/world_detail_screen.dart`
- `lib/widgets/worlds/world_access_guard.dart`
- `lib/services/access_control.dart`
- `lib/state/world_provider.dart`
- `lib/repositories/world_repository.dart`
- `lib/services/world_service.dart`
- `test/**`
- `docs/audits/jules-full-app-audit.md`

Do not redesign screens in this task.
Do not change Supabase schema unless a missing RPC/policy is directly required; if so, add a focused migration and document why.
Only touch `lib/services/access_control.dart` for a narrow starter-world access fix, such as allowing `world.isDefault` before tier/profession checks.

## Required Work
- Trace starter world auto-join from onboarding completion to resident/world membership state.
- Ensure default starter memberships are persisted remotely when Supabase is configured.
- Ensure local starter access fallback does not get mistaken for a remote failure.
- Ensure world detail/access guard treats default starter worlds as accessible after onboarding.
- Avoid fake success: failed remote join should show/log an actionable failure and queue retry if appropriate.
- Update audit doc with root cause and fix.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

Add or update tests for:
- starter world ids are not locally queued as remote-only joins,
- default starter worlds are accessible after onboarding,
- failed non-starter joins queue/retry rather than silently disappearing.
