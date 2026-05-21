# Migration reconciliation — 2026-05-21

## Actions taken (repo)

1. Restored from git history:
   - `20260520130000_security_corrective.sql`
   - `20260520140000_create_world_full_rpc.sql`
   - `20260520150000_daily_rewards_and_events.sql`
2. Renamed `20260520121327` → **`20260520121347`** to match remote version (same SQL).
3. Moved **fresh-project-only** SQL to `supabase/migrations_archive/fresh_project_only/` (10 files).
4. Active `supabase/migrations/` now has **12 files** aligned with remote tail + shared May-19 block.

## Remote migration manifest (32 applied)

| Version | Name |
|---------|------|
| 20260512070535 | add_chat_message_media |
| 20260512070617 | align_posts_rls_author_id_uuid |
| 20260512070627 | add_channel_message_media |
| 20260512071003 | supabase_advisor_hardening |
| 20260512071057 | cover_remaining_fk_indexes |
| 20260512071422 | restrict_public_storage_listing |
| 20260512071530 | restrict_security_definer_execute |
| 20260512071607 | revoke_public_security_definer_execute |
| 20260512122347 | add_profile_local_world_ids |
| 20260513044723 | add_achievement_proofs_bucket |
| 20260513045331 | harden_rls_helpers_and_auth_policy_calls |
| 20260513045455 | consolidate_permissive_rls_policies |
| 20260513045523 | split_districts_manage_policy |
| 20260513045608 | replace_thread_count_rpc_with_trigger |
| 20260513091257 | cloud_default_worlds |
| 20260513092742 | achievement_cloud_submission_contract |
| 20260513093719 | dedupe_user_achievement_policies |
| 20260513143811 | restore_private_rls_function_grants |
| 20260513144019 | backfill_profile_world_memberships |
| 20260513144637 | harden_profile_and_member_rls |
| 20260513144900 | define_private_rls_helpers |
| 20260519144052 | phase2_rls_policy_fix |
| 20260519144556 | seed_default_world_channels |
| 20260519145412 | chat_persistence_hardening |
| 20260519145904 | grant_immabe_superuser |
| 20260519193753 | fix_world_members_policy_recursion |
| 20260520080241 | firebase_storage_and_notification_completion |
| 20260520115334 | secure_notification_webhook_secret |
| 20260520121347 | tighten_device_token_rls |
| 20260520130000 | security_corrective |
| 20260520140000 | create_world_full_rpc |
| 20260520150000 | daily_rewards_and_events |

Versions `20260512070535`–`20260513144900` are **not** checked in as files (already on remote). New clones should use `migration repair` (see [supabase/migrations/README.md](../../supabase/migrations/README.md)).

## Verify

```bash
npx supabase migration list --linked
```

Expect local filenames’ version prefixes to match remote for all files in `supabase/migrations/`.
