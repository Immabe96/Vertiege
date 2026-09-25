#!/usr/bin/env node
/**
 * Generates `tailwind.tokens.json` from `lib/theme/tokens.ts`.
 *
 * `lib/theme/tokens.ts` is the single source of truth; this JSON is the
 * materialised copy that `tailwind.config.js` (CommonJS) can `require`.
 *
 *   node scripts/gen-tokens.mjs           # write
 *   node scripts/gen-tokens.mjs --check   # exit 1 if the JSON is stale
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const outFile = resolve(root, 'tailwind.tokens.json');
const check = process.argv.includes('--check');

const { HEX, RADIUS, SHADOW, FONT_WEIGHT, FONT_FAMILY, MOTION, OVERLAY_ALPHA, PALETTE } =
  await import(new URL('../lib/theme/tokens.ts', import.meta.url).href);

const prettier = await import('prettier');

const source = JSON.stringify(
  {
    $comment: 'GENERATED from lib/theme/tokens.ts — do not edit. Run `npm run tokens`.',
    palette: PALETTE,
    colors: HEX,
    radius: RADIUS,
    shadow: SHADOW,
    fontWeight: FONT_WEIGHT,
    fontFamily: FONT_FAMILY,
    motion: MOTION,
    overlayAlpha: OVERLAY_ALPHA,
  },
  null,
  2,
);

// Format through prettier so `prettier -c` in `npm run lint` can never disagree
// with what this script writes.
const prettierOptions = (await prettier.resolveConfig(outFile)) ?? {};
const output = await prettier.format(`${source}\n`, { ...prettierOptions, filepath: outFile });

let current = null;
try {
  current = readFileSync(outFile, 'utf8');
} catch {
  if (check) {
    console.error('tailwind.tokens.json is missing — run `npm run tokens`.');
    process.exit(1);
  }
}

if (check) {
  if (current !== output) {
    console.error('tailwind.tokens.json is stale — run `npm run tokens`.');
    process.exit(1);
  }
  console.log('tailwind.tokens.json is up to date.');
} else {
  writeFileSync(outFile, output);
  console.log(`wrote ${outFile} (${Object.keys(HEX).length} colours)`);
}
