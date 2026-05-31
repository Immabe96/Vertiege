# Documentation standards

How Vertiege documentation is organized, written, and maintained.

## Model (Diátaxis + project layers)

We use [Diátaxis](https://diataxis.fr/) for **intent**, plus three project-specific layers:

| Layer | Folder | Purpose | Reader question |
|-------|--------|---------|-----------------|
| **Tutorial** | `getting-started/` | First successful run | “How do I run the app?” |
| **How-to** | `guides/` | Task-oriented steps | “How do I ship beta / set up Firebase?” |
| **Reference** | `reference/` | Facts that must stay accurate | “What is the package ID / badge path?” |
| **Explanation** | `product/` | Why and what we’re building | “What’s the roadmap / world vision?” |
| **Operations** | `operations/` | Testers, UAT, release checklists | “What do I verify on device?” |
| **Archive** | `archive/` | Historical audits, old plans | “What did we decide in May?” |

**Code-adjacent docs** stay next to code when they describe that tree only:

- `lib/forui/README.md` — Forui wrappers in-repo
- `supabase/migrations/README.md` — migration workflow
- `releases/README.md` — release artifacts

## File rules

1. **One topic per file** — split when a doc grows past ~300 lines or mixes tutorial + reference.
2. **kebab-case filenames** — e.g. `device-uat.md`, not `DEVICE_UAT.md`.
3. **Status line** at the top when useful:
   - `> **Status: Current**` — canonical, keep updated
   - `> **Status: Archived**` — historical; do not treat as source of truth
4. **Link from the index** — new docs must appear in [docs/README.md](../README.md).
5. **No duplicate truths** — update the canonical doc; add a one-line redirect stub at the old path if links are widespread.
6. **Delete or archive** — session notes, empty audits, and superseded plans go to `archive/` or are removed; do not leave parallel “progress” docs in the root.

## Where to put new content

| You are writing… | Put it in… |
|------------------|------------|
| Setup / first run | `getting-started/` |
| How to configure X, run a script, fix CI | `guides/` |
| Design tokens, catalogs, IDs, manifests | `reference/` |
| Roadmap, waves, vision, IA | `product/` |
| Tester copy, UAT logs, smoke lists | `operations/` |
| Point-in-time audit or completed plan | `archive/` (dated filename) |

## Maintenance cadence

- **After a wave ships:** update `product/planning/wave-status.md` and `operations/uat/issue-log.md`.
- **After design token changes:** update `reference/design-system.md` and `lib/theme/*` together.
- **Quarterly:** skim `archive/` and root redirect stubs; remove stubs when traffic is zero.

## Redirect stubs

When moving a file, leave a short stub at the old path for one release cycle:

```markdown
# Moved

This document lives at **[guides/example.md](../guides/example.md)**.
```

Then delete the stub once grep shows no external links.
