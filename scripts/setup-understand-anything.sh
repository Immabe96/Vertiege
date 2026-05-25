#!/usr/bin/env bash
# Install Understand-Anything for Vertiege (replaces CodeGraph file-structure mapping).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UA_DIR="${UA_DIR:-$HOME/.understand-anything/repo}"

echo "→ Vertiege root: $ROOT"
echo "→ Understand-Anything checkout: $UA_DIR"

if [[ -d "$UA_DIR/.git" ]]; then
  echo "→ Updating Understand-Anything..."
  git -C "$UA_DIR" pull --ff-only
else
  echo "→ Cloning Understand-Anything..."
  mkdir -p "$(dirname "$UA_DIR")"
  git clone --depth 1 https://github.com/Lum1104/Understand-Anything.git "$UA_DIR"
fi

link_into_project() {
  local src="$1" dest="$2"
  ln -sfn "$src" "$dest"
  echo " ✓ $dest → $src"
}

link_into_project "$UA_DIR/understand-anything-plugin" "$ROOT/understand-anything-plugin"
link_into_project "$UA_DIR/.cursor-plugin" "$ROOT/.cursor-plugin"
link_into_project "$UA_DIR/understand-anything-plugin" "$HOME/.understand-anything-plugin"

mkdir -p "$ROOT/.cursor/skills"
for skill_dir in "$UA_DIR/understand-anything-plugin/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  link_into_project "$skill_dir" "$ROOT/.cursor/skills/$name"
done

run_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    pnpm "$@"
  else
    npx -y pnpm@10 "$@"
  fi
}

PLUGIN_ROOT="$UA_DIR/understand-anything-plugin"
if [[ -f "$PLUGIN_ROOT/package.json" ]] && [[ ! -f "$PLUGIN_ROOT/packages/core/dist/index.js" ]]; then
  echo "→ Building @understand-anything/core (first run)..."
  if ! command -v pnpm >/dev/null 2>&1; then
    echo "→ Using npx pnpm (global pnpm not on PATH)"
  fi
  (
    cd "$PLUGIN_ROOT"
    run_pnpm install --frozen-lockfile 2>/dev/null || run_pnpm install
    run_pnpm --filter @understand-anything/core build
  )
fi

mkdir -p "$ROOT/.understand-anything"
if [[ ! -f "$ROOT/.understand-anything/.understandignore" ]]; then
  cat > "$ROOT/.understand-anything/.understandignore" <<'EOF'
# Vertiege — exclude generated / platform noise from graph analysis
.dart_tool/
build/
**/node_modules/
.git/
android/.gradle/
android/build/
ios/Pods/
ios/.symlinks/
**/*.g.dart
**/*.freezed.dart
**/*.mocks.dart
releases/
coverage/
supabase/.temp/
.codegraph/
.understand-anything/intermediate/
EOF
  echo " ✓ Wrote .understand-anything/.understandignore"
fi

echo ""
echo "✓ Understand-Anything linked into Vertiege."
echo "  Restart Cursor, then in Agent chat run: /understand lib"
echo "  (scopes to Dart app code; omit path for full repo scan)"
echo "  Dashboard: /understand-dashboard"
echo ""
echo "  Docs: docs/UNDERSTAND_ANYTHING.md"
