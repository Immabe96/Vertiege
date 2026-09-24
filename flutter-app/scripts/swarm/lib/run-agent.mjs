import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const SWARM_DIR = dirname(dirname(fileURLToPath(import.meta.url)));
const MODEL = "composer-2.5";

export { MODEL, SWARM_DIR };

export async function loadRolePrompt(role) {
  const path = join(SWARM_DIR, "agents", `${role}.md`);
  try {
    return await readFile(path, "utf8");
  } catch {
    return `# ${role}\n`;
  }
}

/**
 * Run Cursor Agent CLI (composer-2.5 only).
 */
export function runAgent({ prompt, cwd, mode = "ask", logPath }) {
  return new Promise((resolve, reject) => {
    const args = [
      "--trust",
      "--print",
      "--model",
      MODEL,
      "--mode",
      mode,
      "--output-format",
      "text",
      prompt,
    ];

    const child = spawn(process.env.AGENT_BIN || "agent", args, {
      cwd,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => {
      stdout += d;
    });
    child.stderr.on("data", (d) => {
      stderr += d;
    });
    child.on("error", reject);
    child.on("close", async (code) => {
      const body = stdout.trim() || stderr.trim();
      if (logPath) {
        const { writeFile } = await import("node:fs/promises");
        await writeFile(
          logPath,
          `# exit ${code}\n\n## stderr\n${stderr}\n\n## stdout\n${stdout}\n`,
          "utf8",
        );
      }
      if (code !== 0) {
        reject(new Error(`agent exited ${code}: ${stderr.slice(0, 500) || body.slice(0, 500)}`));
        return;
      }
      resolve(body);
    });
  });
}

export function extractJson(text) {
  const trimmed = text.trim();
  const fence = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
  const candidate = fence ? fence[1].trim() : trimmed;
  const start = candidate.indexOf("{");
  const end = candidate.lastIndexOf("}");
  if (start === -1 || end === -1) {
    throw new Error("No JSON object found in agent response");
  }
  return JSON.parse(candidate.slice(start, end + 1));
}
