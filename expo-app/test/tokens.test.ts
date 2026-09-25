import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

import { HEX, contrastRatio } from '@/lib/theme/tokens';

const root = join(__dirname, '..');

/** Everything that ships in the client except the token source itself. */
function walk(dir: string, out: string[] = []): string[] {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      walk(full, out);
    } else if (/\.(ts|tsx)$/.test(entry)) {
      out.push(full);
    }
  }
  return out;
}

const clientFiles = ['app', 'components', 'lib']
  .map((dir) => walk(join(root, dir)))
  .flat()
  .filter((file) => relative(root, file) !== 'lib/theme/tokens.ts');

/**
 * Web bootstrap runs before any module can be imported, so it carries the
 * ground colour as a literal. The "platform config" test below keeps it in
 * step with the tokens instead.
 */
const hexAllowlist = new Set(['app/+html.tsx']);

const TEXT_AA = 4.5;

describe('neobrutalism tokens — contrast', () => {
  const grounds: [string, string][] = [
    ['background', HEX.background],
    ['secondary-background', HEX['secondary-background']],
    ['background-raised', HEX['background-raised']],
  ];

  test.each(grounds)('ink reads on %s', (name, ground) => {
    expect(contrastRatio(HEX.foreground, ground)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['muted-foreground'], ground)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['success-ink'], ground)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['warning-ink'], ground)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['danger-ink'], ground)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX.secondary, ground)).toBeGreaterThanOrEqual(TEXT_AA);
  });

  test('ink reads on the main (CTA) fill', () => {
    expect(contrastRatio(HEX.foreground, HEX.main)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['main-foreground'], HEX.main)).toBeGreaterThanOrEqual(TEXT_AA);
  });

  test('each status fill carries its own foreground at AA', () => {
    expect(contrastRatio(HEX['success-foreground'], HEX.success)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['warning-foreground'], HEX.warning)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['danger-foreground'], HEX.danger)).toBeGreaterThanOrEqual(TEXT_AA);
    expect(contrastRatio(HEX['secondary-foreground'], HEX.secondary)).toBeGreaterThanOrEqual(
      TEXT_AA
    );
  });

  test('borders are the same ink as body text (≥ 3:1 on every ground)', () => {
    expect(HEX.border).toBe(HEX.foreground);
    for (const [, ground] of grounds) {
      expect(contrastRatio(HEX.border, ground)).toBeGreaterThanOrEqual(3);
    }
  });
});

describe('neobrutalism tokens — light only', () => {
  test('no dark-mode branches in client code', () => {
    const offenders = clientFiles.filter((file) => {
      const source = readFileSync(file, 'utf8');
      return /prefers-color-scheme| dark:/.test(source);
    });
    expect(offenders).toEqual([]);
  });

  test('no colour-scheme switching left behind', () => {
    const offenders = clientFiles.filter((file) =>
      /useColorScheme|NAV_THEME|ThemeToggle/.test(readFileSync(file, 'utf8'))
    );
    expect(offenders).toEqual([]);
  });
});

describe('neobrutalism tokens — single source of truth', () => {
  test('no colour literals outside lib/theme/', () => {
    const offenders = clientFiles
      .filter((file) => !hexAllowlist.has(relative(root, file)))
      .map((file) => ({ file, source: readFileSync(file, 'utf8') }))
      .flatMap(({ file, source }) =>
        source
          .split('\n')
          .map((line, index) => ({ line, index: index + 1 }))
          .filter(({ line }) => /#[0-9a-fA-F]{6}\b/.test(line))
          .map(({ index }) => `${relative(root, file)}:${index}`)
      );
    expect(offenders).toEqual([]);
  });

  test('tailwind.tokens.json matches tokens.ts', () => {
    const generated = JSON.parse(readFileSync(join(root, 'tailwind.tokens.json'), 'utf8'));
    expect(generated.colors).toEqual(HEX);
    expect(generated.palette).toBe('yellow');
  });

  test('platform config carries the same ground colour', () => {
    const appJson = readFileSync(join(root, 'app.json'), 'utf8');
    expect(appJson.toLowerCase()).toContain(HEX.background.toLowerCase());

    const html = readFileSync(join(root, 'app/+html.tsx'), 'utf8');
    expect(html.toLowerCase()).toContain(HEX.background.toLowerCase());
    expect(html).not.toContain('prefers-color-scheme');
  });
});
