# CodeGraph (local code intelligence)

[CodeGraph](https://github.com/colbymchenry/codegraph) builds a **local SQLite knowledge graph** of this repo (symbols, call edges, imports) and exposes it to Cursor via MCP. No API keys; data stays on your machine.

Vertiege is indexed as **Dart** (`lib/`, `test/`; ~330 files). Generated code (`*.g.dart`, platform trees, `build/`, `.dart_tool/`) is excluded — see `.codegraph/config.json`. (Dart is parsed via tree-sitter; the config `languages` field only filters TS/JS/Python/etc. — leave it empty and rely on `include` globs.)

## One-time setup

1. **Node.js 20–24** (for `npx`; CodeGraph bundles its own runtime for indexing).
2. **Restart Cursor** after pulling this repo so `.cursor/mcp.json` loads the `codegraph` MCP server.
3. **Build the index** (once per clone, or after large refactors):

   ```powershell
   cd C:\Users\Immabe\Vertiege
   .\scripts\codegraph-index.ps1
   ```

   On **Windows**, prefer the script above — `npx codegraph` often fails with `spawnSync … EINVAL`.

   Or manually (macOS/Linux):

   ```bash
   npx -y @colbymchenry/codegraph@latest init -i
   ```

   Windows manual (after `npm install -g @colbymchenry/codegraph-win32-x64`):

   ```powershell
   $env:CI = 'true'
   & "$env:APPDATA\npm\node_modules\@colbymchenry\codegraph-win32-x64\bin\codegraph.cmd" sync
   ```

   The database (`.codegraph/codegraph.db`) is gitignored; only `config.json` is tracked.

### Optional: global `codegraph` on PATH

The interactive installer can put `codegraph` on your PATH (slightly faster MCP startup than `npx` each time):

```bash
npx -y @colbymchenry/codegraph@latest install --target=cursor --location=local --yes
```

On **Windows**, `.cursor/mcp.json` runs `scripts/codegraph-serve.ps1` (bundled binary). On macOS/Linux, switch the `codegraph` server back to `npx -y @colbymchenry/codegraph@latest serve --mcp --path ${workspaceFolder}`.

## Daily use

| Task | Command |
|------|---------|
| Check index | `.\scripts\codegraph-index.ps1` (sync) then bundled `codegraph.cmd status` — see Windows note below |
| Refresh after many edits | `.\scripts\codegraph-index.ps1` |
| Full rebuild | `.\scripts\codegraph-index.ps1 -Force` |
| Search symbol (CLI) | `$env:CI='true'; & "$env:APPDATA\npm\node_modules\@colbymchenry\codegraph-win32-x64\bin\codegraph.cmd" query WorldService` |

In **Cursor Agent**, prefer MCP tools (`codegraph_search`, `codegraph_context`, …) when exploring structure. Rules: `.cursor/rules/codegraph.mdc`.

The MCP server **auto-syncs** on save while Cursor is open (native file watcher).

## Troubleshooting

| Issue | Fix |
|-------|-----|
| MCP says "not initialized" | Run `.\scripts\codegraph-index.ps1` |
| `npx` / npm `codegraph` fails on Windows (`spawnSync EINVAL`) | Run `npm install -g @colbymchenry/codegraph-win32-x64`, then `.\scripts\codegraph-index.ps1` (uses bundled `codegraph.cmd`, sets `CI=true`) |
| Script hangs on sync | Ensure `CI=true` (script sets this); do not use npm's shim `codegraph` on PATH |
| Index OOM / very slow | Close other apps; index uses RAM proportional to parsed files. Config limits scope to Dart only. |
| `Backend: wasm` in `status` | Native SQLite failed to load; run `npm rebuild better-sqlite3` (see upstream README) |

## CI

CodeGraph is **not** run in GitHub Actions. The graph is a **local dev aid** for agents; CI stays `flutter analyze` + `flutter test` only.
