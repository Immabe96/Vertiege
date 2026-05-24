#!/usr/bin/env node
/**
 * Local Agent Swarm replica for Vertiege — Cursor CLI + composer-2.5 only.
 * Mirrors desplega-ai/agent-swarm presets: research | dev | solo.
 *
 * Flow (research/dev):
 *   1. Lead decomposes mission → subtasks (JSON)
 *   2. Workers execute in dependency order
 *   3. Lead synthesizes final report
 *
 * Flow (solo):
 *   1. Single coder executes mission
 */

import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { extractJson, loadRolePrompt, MODEL, runAgent, SWARM_DIR } from "./lib/run-agent.mjs";

const ROOT = process.env.SWARM_ROOT || join(SWARM_DIR, "../..");
const PRESETS = JSON.parse(await readFile(join(SWARM_DIR, "presets.json"), "utf8"));

function usage() {
  console.log(`Vertiege Cursor Swarm (model: ${MODEL} only)

Usage:
  node scripts/swarm/swarm.mjs run --preset <research|dev|solo> "<mission>"
  node scripts/swarm/swarm.mjs audit              # codebase audit (research preset)
  node scripts/swarm/swarm.mjs audit-ui           # UI/UX + Forui + theming audit

Options:
  --preset <id>     Preset (default: research)
  --mode <ask|plan> Worker mode (default: ask = read-only)
  --out <path>      Final report path
  --run-dir <path>  State directory (default: .swarm/runs/<timestamp>)

Env:
  AGENT_BIN         Cursor agent CLI (default: agent)
  SWARM_ROOT        Repo root (default: Vertiege)
`);
}

function parseArgs(argv) {
  const args = [...argv];
  const cmd = args.shift() || "help";
  let preset = "research";
  let mode = "ask";
  let out = null;
  let runDir = null;
  const positional = [];

  while (args.length > 0) {
    const a = args[0];
    if (a === "--preset" && args[1]) {
      preset = args[1];
      args.splice(0, 2);
    } else if (a === "--mode" && args[1]) {
      mode = args[1];
      args.splice(0, 2);
    } else if (a === "--out" && args[1]) {
      out = args[1];
      args.splice(0, 2);
    } else if (a === "--run-dir" && args[1]) {
      runDir = args[1];
      args.splice(0, 2);
    } else {
      positional.push(args.shift());
    }
  }

  return { cmd, preset, mode, out, runDir, mission: positional.join(" ").trim() };
}

function stamp() {
  return new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
}

const DEFAULT_AUDIT_MISSION = `Audit the Vertiege Flutter codebase (read-only). Deliver a markdown report with:
executive summary, architecture, security, reliability, data layer, testing, Android/build,
findings table (severity/area/finding/fix/files), and prioritized next steps.

Prioritize recent Linux port work: lib/main.dart, lib/app.dart, lib/router/app_router.dart,
lib/state/resident_provider.dart, world channel routes, firebase_bootstrap, android/gradle.properties.
Cross-check docs/audits/ when relevant.`;

const DEFAULT_UI_AUDIT_MISSION = `Audit Vertiege UI/UX (read-only). Deliver markdown with:
executive summary, design system inventory (VTheme, VColors, Forui VertiegeForuiTheme, theme_provider),
Forui adoption vs Material/Cupertino, light/dark/system mode behavior and gaps,
navigation/shell consistency (tab bar, VHubPage, FScaffold, AppBar),
feedback patterns (SnackBar vs FToast/FDialog/FSheet),
accessibility (text scale, contrast, touch targets),
screen-by-screen migration tiers (Tier A/B/C),
findings table (ID/severity/area/finding/fix/files),
and prioritized implementation waves.

MANDATORY — read and apply these project skills before auditing:
- .cursor/skills/vertiege-forui-ui/SKILL.md (Forui + Vertiege conventions)
- .cursor/skills/flutter-ai-ui-skill/SKILL.md (+ data/*.csv guidelines)
- .cursor/skills/ui-design-brain/SKILL.md (+ components.md for patterns)

Run if possible: python .cursor/skills/flutter-ai-ui-skill/scripts/analyse_flutter_project.py
and incorporate analyzer output into findings.

Cross-check prior audit: docs/audits/2026-05-24-cursor-swarm-ui-ux-audit.md (validate/update, do not duplicate blindly).

Focus: lib/app.dart, lib/theme/*, lib/forui/*, lib/widgets/v_section_list.dart,
lib/ui/*, lib/screens/tabs/*, auth/onboarding, world_channel_screen, settings appearance.
Verify splash vs post-splash theme, FTheme sync with MaterialApp themeMode, hardcoded VColors.`;

async function leadDecompose({ mission, preset, cwd, runPath, mode }) {
  const presetDef = PRESETS[preset];
  const roles = presetDef.agents.filter((a) => !a.isLead).map((a) => a.role);
  const leadSoul = await loadRolePrompt("lead");

  const prompt = `${leadSoul}

## Decompose mission

Preset: ${preset} (${presetDef.name})
Available worker roles: ${[...new Set(roles)].join(", ")}
Repository: ${cwd}
Mission:
${mission}

Respond with ONLY valid JSON (no markdown fences):
{
  "subtasks": [
    {
      "id": "1",
      "role": "researcher",
      "title": "short title",
      "task": "detailed instructions",
      "dependsOn": []
    }
  ]
}

Rules:
- Assign each subtask to exactly one role from the available list.
- Use dependsOn for sequential work (e.g. reviewer after researcher).
- 2–5 subtasks for audits; cover architecture, security, reliability, tests.
- Workers are read-only when mode is ask.`;

  console.log("[lead] Decomposing mission…");
  const raw = await runAgent({
    prompt,
    cwd,
    mode: "ask",
    logPath: join(runPath, "lead-decompose.log"),
  });
  const plan = extractJson(raw);
  if (!Array.isArray(plan.subtasks) || plan.subtasks.length === 0) {
    throw new Error("Lead returned no subtasks");
  }
  await writeFile(join(runPath, "plan.json"), JSON.stringify(plan, null, 2));
  return plan.subtasks;
}

function topoSort(tasks) {
  const byId = new Map(tasks.map((t) => [t.id, t]));
  const done = new Set();
  const order = [];

  while (order.length < tasks.length) {
    let progressed = false;
    for (const t of tasks) {
      if (done.has(t.id)) continue;
      const deps = t.dependsOn || [];
      if (deps.every((d) => done.has(d))) {
        order.push(t);
        done.add(t.id);
        progressed = true;
      }
    }
    if (!progressed) {
      throw new Error("Circular or missing dependsOn in subtasks");
    }
  }
  return order;
}

async function runWorker({ subtask, cwd, runPath, mode, priorOutputs }) {
  const roleSoul = await loadRolePrompt(subtask.role);
  const context =
    priorOutputs.length > 0
      ? `\n## Prior worker outputs\n\n${priorOutputs.map((p) => `### ${p.id} (${p.role})\n${p.output}`).join("\n\n")}\n`
      : "";

  const prompt = `${roleSoul}

## Your subtask (${subtask.id})

**Title:** ${subtask.title || subtask.id}
**Role:** ${subtask.role}

${subtask.task}
${context}

Repository root: ${cwd}
Output structured markdown. Do not edit files unless explicitly told to write.`;

  console.log(`[worker:${subtask.role}] ${subtask.title || subtask.id}…`);
  const output = await runAgent({
    prompt,
    cwd,
    mode,
    logPath: join(runPath, `worker-${subtask.id}-${subtask.role}.log`),
  });
  const record = {
    id: subtask.id,
    role: subtask.role,
    title: subtask.title,
    output,
    completedAt: new Date().toISOString(),
  };
  await writeFile(join(runPath, `result-${subtask.id}.md`), output, "utf8");
  return record;
}

async function leadSynthesize({ mission, preset, cwd, runPath, workerResults }) {
  const leadSoul = await loadRolePrompt("lead");
  const bodies = workerResults
    .map((r) => `## Subtask ${r.id} (${r.role})\n\n${r.output}`)
    .join("\n\n---\n\n");

  const prompt = `${leadSoul}

## Synthesize final deliverable

Preset: ${preset}
Mission:
${mission}

Merge the worker outputs below into ONE polished markdown report for the user.
Remove duplication; resolve conflicts; keep a single findings table and one prioritized next-steps list.

${bodies}`;

  console.log("[lead] Synthesizing final report…");
  return runAgent({
    prompt,
    cwd,
    mode: "ask",
    logPath: join(runPath, "lead-synthesize.log"),
  });
}

async function runSolo({ mission, cwd, runPath, mode }) {
  const soul = await loadRolePrompt("coder");
  const prompt = `${soul}\n\n## Mission\n\n${mission}`;
  console.log("[solo:coder] Running mission…");
  const output = await runAgent({
    prompt,
    cwd,
    mode,
    logPath: join(runPath, "solo-coder.log"),
  });
  return output;
}

async function runSwarm({ preset, mission, mode, out, runDir, auditKind = "codebase" }) {
  if (!PRESETS[preset]) {
    throw new Error(`Unknown preset "${preset}". Options: ${Object.keys(PRESETS).join(", ")}`);
  }
  if (process.env.AUDIT_MODEL && process.env.AUDIT_MODEL !== MODEL) {
    console.warn(`warn: ignoring AUDIT_MODEL=${process.env.AUDIT_MODEL}; swarm uses ${MODEL} only`);
  }

  const cwd = ROOT;
  const runPath = runDir || join(cwd, ".swarm", "runs", stamp());
  await mkdir(runPath, { recursive: true });

  const meta = {
    model: MODEL,
    preset,
    mode,
    mission,
    auditKind,
    startedAt: new Date().toISOString(),
    runPath,
  };
  await writeFile(join(runPath, "meta.json"), JSON.stringify(meta, null, 2));

  console.log(`Swarm run: ${runPath}`);
  console.log(`Model: ${MODEL} | Preset: ${preset} | Mode: ${mode}`);

  let finalReport;

  if (preset === "solo") {
    finalReport = await runSolo({ mission, cwd, runPath, mode });
  } else {
    const subtasks = await leadDecompose({ mission, preset, cwd, runPath, mode });
    const ordered = topoSort(subtasks);
    const results = [];
    const outputsById = new Map();

    for (const subtask of ordered) {
      const deps = subtask.dependsOn || [];
      const prior = deps.map((id) => outputsById.get(id)).filter(Boolean);
      const record = await runWorker({
        subtask,
        cwd,
        runPath,
        mode,
        priorOutputs: prior,
      });
      results.push(record);
      outputsById.set(subtask.id, record);
    }

    await writeFile(join(runPath, "results.json"), JSON.stringify(results, null, 2));
    finalReport = await leadSynthesize({
      mission,
      preset,
      cwd,
      runPath,
      workerResults: results,
    });
  }

  const reportPath = join(runPath, "report.md");
  await writeFile(reportPath, finalReport, "utf8");

  const dated = new Date().toISOString().slice(0, 10);
  const defaultBasename = meta.auditKind === "ui-ux"
    ? `${dated}-cursor-swarm-ui-ux-audit.md`
    : `${dated}-cursor-swarm-audit.md`;
  const outPath = out || join(cwd, "docs", "audits", defaultBasename);
  await mkdir(join(cwd, "docs", "audits"), { recursive: true });

  const title =
    meta.auditKind === "ui-ux"
      ? "Vertiege UI/UX swarm audit"
      : "Vertiege swarm audit";
  const header = `# ${title}

- **Date:** ${dated}
- **Model:** \`${MODEL}\` (Cursor CLI)
- **Preset:** ${preset} (${PRESETS[preset].name})
- **Mode:** ${mode}
- **Run artifacts:** \`${runPath}\`

---

`;

  await writeFile(outPath, header + finalReport, "utf8");
  meta.finishedAt = new Date().toISOString();
  meta.reportPath = outPath;
  await writeFile(join(runPath, "meta.json"), JSON.stringify(meta, null, 2));
  return outPath;

  console.log(`\nDone.\n  Report: ${outPath}\n  Run dir: ${runPath}`);
}

const { cmd, preset, mode, out, runDir, mission } = parseArgs(process.argv.slice(2));

try {
  if (cmd === "help" || cmd === "-h" || cmd === "--help") {
    usage();
  } else if (cmd === "audit") {
    await runSwarm({
      preset: "research",
      mission: mission || DEFAULT_AUDIT_MISSION,
      mode,
      out,
      runDir,
      auditKind: "codebase",
    });
  } else if (cmd === "audit-ui") {
    await runSwarm({
      preset: "research",
      mission: mission || DEFAULT_UI_AUDIT_MISSION,
      mode,
      out,
      runDir,
      auditKind: "ui-ux",
    });
  } else if (cmd === "run") {
    if (!mission) {
      console.error("error: mission text required\n");
      usage();
      process.exit(1);
    }
    await runSwarm({ preset, mission, mode, out, runDir });
  } else {
    usage();
    process.exit(1);
  }
} catch (err) {
  console.error(`\nerror: ${err.message}`);
  process.exit(1);
}
