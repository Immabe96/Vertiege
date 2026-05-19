# Jules Task 08: Nexus Feed Forui Pass

## Plan Approval Required
Generate a plan first and wait for explicit approval before implementation. Do not auto-approve your own plan and do not open a PR until the plan has been approved.

## Goal
Make Nexus/feed UI compact, minimal, and Forui-aligned without changing data behavior.

## Scope
Allowed to touch:
- `lib/screens/tabs/nexus_screen.dart`
- `lib/widgets/feed/**`
- `lib/widgets/nexus/**`
- `lib/widgets/core/empty_state.dart`
- `test/widget_test.dart`
- `docs/audits/jules-full-app-audit.md`

Do not touch Supabase migrations, world config, onboarding, or repositories.
Do not do broad regex replacements.

## Required Work
- Clean feed cards, composer surfaces, sort/filter controls, and empty states.
- Preserve create/comment/react/bookmark/share behavior.
- Remove mismatched glass/gradient styling in this scope.
- Keep typography compact and readable in light/dark modes.
- Update audit doc with exact changes and residual risks.

## Extra Safety Constraints
- First inspect existing Forui usage in this repo and the installed `forui` package before naming or using Forui widgets.
- Do not speculate about constructors such as `FCard` or `showFSheet`; verify they compile from package docs/source or existing usage.
- If a Forui primitive lacks padding/border parameters, wrap its child in `Padding` or use an existing app wrapper instead of passing unsupported params.
- Do not replace app navigation, routing, providers, repositories, Supabase code, or auth behavior.
- Do not change `AppBar`/top-level shell behavior unless the problematic blur/glass code is directly inside the allowed Nexus scope.
- List the exact files you expect to edit in the plan.
- If another file is needed, pause and ask instead of expanding scope.
- No root scratch files, no throwaway Dart probes, no shell replacement scripts, no broad regex rewrites.

## Verification
Run:
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`

Do not open PR if the feed/composer code has compile errors or broken callbacks.
