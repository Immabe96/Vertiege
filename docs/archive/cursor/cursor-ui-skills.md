# Design skills for Vertiege (Cursor)

Installed **project skills** under `.cursor/skills/` so agents apply real UI guidance instead of generic Flutter output.

## Installed skills

| Skill | Path | Purpose |
|-------|------|---------|
| **Vertiege Forui UI** | `.cursor/skills/vertiege-forui-ui/` | **Start here** — Forui, VTheme, AMOLED/light, VHubPage, audit U01–U12 |
| **Flutter AI UI** | `.cursor/skills/flutter-ai-ui-skill/` | Palettes, typography, 120+ guidelines, animations, project analyzer |
| **UI Design Brain** | `.cursor/skills/ui-design-brain/` | 60+ component best practices, layouts, anti-patterns |

Cursor rule **`.cursor/rules/flutter-ui.mdc`** loads these for `lib/**` UI work.

## Update skills

```bash
# Flutter AI UI Skill (upstream)
curl -sSL https://raw.githubusercontent.com/SpeakQuery/flutter-ai-ui-skill/main/install.sh | sh -s -- --ai cursor

# UI Design Brain
git -C .cursor/skills/ui-design-brain pull

# Vertiege Forui UI is maintained in-repo — edit SKILL.md directly
```

## Optional upstream skills (not installed)

| Skill | Install |
|-------|---------|
| [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | `npx uipro init --ai cursor` (multi-stack design system CLI) |
| [ui-craft](https://github.com/educlopez/ui-craft) | Clone into `.cursor/skills/ui-craft` (design taste / polish passes) |

## Analyzer (Flutter AI UI)

```bash
python .cursor/skills/flutter-ai-ui-skill/scripts/analyse_flutter_project.py
python .cursor/skills/flutter-ai-ui-skill/scripts/search_guidelines.py accessibility
```

## Related

- [cursor-swarm.md](cursor-swarm.md) — `./scripts/audit-ui-ux.sh`
- [audits/2026-05-24-cursor-swarm-ui-ux-audit.md](audits/2026-05-24-cursor-swarm-ui-ux-audit.md)
