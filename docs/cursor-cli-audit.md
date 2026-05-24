# Codebase audit with Cursor CLI

[Agent Swarm](https://github.com/desplega-ai/agent-swarm) does **not** support the Cursor Agent CLI as a harness. Its providers are Claude Code, Codex, pi-mono, Devin, Claude Managed, and opencode only.

For Vertiege we use the **Cursor Agent CLI** (`agent`) directly against this repo.

## Prerequisites

- Cursor Agent CLI on `PATH` (`agent --version`)
- Logged-in Cursor session (or `CURSOR_API_KEY` for CI)

## Run audit

```bash
cd ~/Vertiege
./scripts/audit-codebase.sh
```

Output defaults to `docs/audits/YYYY-MM-DD-cursor-cli-audit.md`.

### Options

| Variable | Default | Purpose |
|----------|---------|---------|
| `AUDIT_MODE` | `ask` | `ask` = read-only Q&A; `plan` = read-only planning |
| `AUDIT_MODEL` | (CLI default) | e.g. `composer-2.5` |
| `AUDIT_OUT_FILE` | dated file under `docs/audits/` | Override report path |
| `AGENT_BIN` | `agent` | CLI binary name |

Example:

```bash
AUDIT_MODE=plan AUDIT_MODEL=composer-2.5 ./scripts/audit-codebase.sh
```

## Agent Swarm (optional, not Cursor)

If you later want multi-agent orchestration with Slack/GitHub workers, Agent Swarm still requires Claude/Codex/opencode credentials — not Cursor CLI. See [agent-swarm.dev](https://agent-swarm.dev).
