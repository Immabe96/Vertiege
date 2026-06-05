#!/usr/bin/env bash
# UI migration: track / enforce Forui imports under lib/.
# Default: --report (non-failing). Wire --enforce-screens into CI after Wave A.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT/lib"
MODE="report"

usage() {
  cat <<'EOF'
Usage: check_no_forui_in_lib.sh [--report | --enforce-screens | --enforce-zero]

  --report           Print counts and files (default, exit 0)
  --enforce-screens  Fail if package:forui appears under lib/screens/ or
                     lib/widgets/ outside the transition allowlist
  --enforce-zero     Fail if any package:forui remains under lib/ (Wave F)
EOF
}

# Paths allowed to import Forui during migration (shrink each wave).
ALLOWLIST=(
  "lib/forui/"
  "lib/theme/forui_theme.dart"
  "lib/ui_spike/"
  "lib/ui/shell/"
  "lib/app.dart"
  "lib/router/app_router.dart"
  "lib/ui/buttons/v_button.dart"
  "lib/widgets/v_section_list.dart"
  "lib/widgets/core/v_dialog.dart"
  "lib/widgets/core/glass_sheet.dart"
  "lib/widgets/core/v_feedback.dart"
  "lib/widgets/core/v_surface_card.dart"
  "lib/widgets/core/v_app_banner.dart"
  "lib/widgets/core/tier_up_dialog.dart"
  "lib/widgets/core/prestige_up_dialog.dart"
  "lib/widgets/core/v_accessible.dart"
  "lib/services/device_permission_service.dart"
)

is_allowlisted() {
  local file="$1"
  local rel="${file#"$ROOT"/}"
  local entry
  for entry in "${ALLOWLIST[@]}"; do
    if [[ "$rel" == "$entry" || "$rel" == ${entry%/}* ]]; then
      return 0
    fi
  done
  return 1
}

find_forui_files() {
  grep -rl "package:forui/forui.dart" "$LIB" 2>/dev/null || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report) MODE="report" ;;
    --enforce-screens) MODE="enforce-screens" ;;
    --enforce-zero) MODE="enforce-zero" ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

ALL_FILES=()
while IFS= read -r line; do
  [[ -n "$line" ]] && ALL_FILES+=("$line")
done < <(find_forui_files)
TOTAL="${#ALL_FILES[@]}"

echo "forui import files under lib/: $TOTAL"

SCREEN_FILES=()
WIDGET_FILES=()
OTHER_FILES=()
VIOLATIONS=()

for f in "${ALL_FILES[@]}"; do
  rel="${f#"$ROOT"/}"
  echo "  $rel"
  if [[ "$rel" == lib/screens/* ]]; then
    SCREEN_FILES+=("$rel")
    if [[ "$MODE" != "report" ]] && ! is_allowlisted "$f"; then
      VIOLATIONS+=("$rel")
    fi
  elif [[ "$rel" == lib/widgets/* ]]; then
    WIDGET_FILES+=("$rel")
    if [[ "$MODE" == "enforce-screens" ]] && ! is_allowlisted "$f"; then
      VIOLATIONS+=("$rel")
    fi
  else
    OTHER_FILES+=("$rel")
    if [[ "$MODE" == "enforce-zero" ]]; then
      VIOLATIONS+=("$rel")
    fi
  fi
done

echo ""
echo "summary: screens=${#SCREEN_FILES[@]} widgets=${#WIDGET_FILES[@]} other=${#OTHER_FILES[@]}"
echo "allowlist entries: ${#ALLOWLIST[@]} (see script header)"

case "$MODE" in
  report)
    echo "ok: report mode (non-failing)"
    ;;
  enforce-screens)
    if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
      echo "error: Forui import outside allowlist in screens/widgets:" >&2
      printf '  %s\n' "${VIOLATIONS[@]}" >&2
      exit 1
    fi
    echo "ok: no disallowed Forui imports in screens/widgets"
    ;;
  enforce-zero)
    if [[ "$TOTAL" -gt 0 ]]; then
      echo "error: Forui imports remain under lib/ ($TOTAL files)" >&2
      exit 1
    fi
    echo "ok: zero Forui imports under lib/"
    ;;
esac
