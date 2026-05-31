# Understand Anything (codebase map)

[Understand-Anything](https://github.com/Lum1104/Understand-Anything) replaces **CodeGraph** in this repo. It builds an interactive **knowledge graph** (files, symbols, layers, tours) stored under `.understand-anything/`, with Cursor skills such as `/understand`, `/understand-dashboard`, and `/understand-chat`.

## One-time setup

```bash
./scripts/setup-understand-anything.sh
```

Requires **git**, **Node.js ≥ 22**, and **pnpm ≥ 10** (only for the first `/understand` build of `@understand-anything/core`).

Then **restart Cursor**. The installer:

- Clones/updates `~/.understand-anything/repo`
- Symlinks `understand-anything-plugin` and `.cursor-plugin` into the project root
- Links skills under `.cursor/skills/` (`understand`, `understand-dashboard`, …)
- Creates `.understand-anything/.understandignore` tuned for Flutter

Alternative: **Cursor Settings → Plugins** → add `https://github.com/Lum1104/Understand-Anything`.

## Daily use (Agent chat)

| Command | Purpose |
|---------|---------|
| `/understand lib` | Analyze `lib/` (recommended for Vertiege) |
| `/understand` | Full repo scan (slower; respects `.understandignore`) |
| `/understand-dashboard` | Interactive graph UI |
| `/understand-chat How does world routing work?` | Q&A over the graph |
| `/understand-explain lib/router/app_router.dart` | Deep-dive one file |
| `/understand-diff` | Impact of uncommitted changes |
| `/understand-domain` | Business-domain view |

Re-run `/understand lib` after large refactors; incremental updates only re-analyze changed files.

## What to commit

```gitignore
.understand-anything/intermediate/
.understand-anything/diff-overlay.json
```

Optional (good for onboarding): commit `knowledge-graph.json`, `meta.json`, and `config.json`. Use **git-lfs** if the graph exceeds ~10 MB.

## Vertiege scope

Default ignore list excludes `.dart_tool/`, `build/`, `*.g.dart`, platform trees, and legacy `.codegraph/`. Prefer **`/understand lib`** so agents focus on app architecture (router, screens, services, state).

## CodeGraph (retired)

- MCP entry removed from `.cursor/mcp.json`
- Rule replaced: `.cursor/rules/understand-anything.mdc`
- Old docs: [CODEGRAPH.md](CODEGRAPH.md) (deprecated)
- Scripts `scripts/codegraph-*.ps1` kept for reference only

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `/understand` not found | Run setup script; restart Cursor |
| `pnpm` / build errors | Install Node 22+ and pnpm 10+; re-run setup |
| Graph stale | `/understand lib --full` |
| Too many files | `/understand lib` or `/understand lib/screens` |
