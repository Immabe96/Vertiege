#!/usr/bin/env bash
# Delete old GitHub Actions artifacts to stay under storage quota.
# Requires: gh, GH_TOKEN or GITHUB_TOKEN with actions:write.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-Immabe96/Vertiege}"
KEEP="${ARTIFACT_KEEP_COUNT:-2}"
PREFIX="${ARTIFACT_NAME_PREFIX:-vertiege-apk}"
MODE="${ARTIFACT_PRUNE_MODE:-normal}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found; skipping artifact prune"
  exit 0
fi

echo "Pruning artifacts on ${REPO} (mode=${MODE}, keep=${KEEP} x ${PREFIX}*)"

ids_to_delete=()

while IFS= read -r line; do
  [ -z "$line" ] && continue
  id=$(echo "$line" | cut -f1)
  name=$(echo "$line" | cut -f2)
  created=$(echo "$line" | cut -f3)
  ids_to_delete+=("${id}|${name}|${created}")
done < <(
  gh api --paginate "/repos/${REPO}/actions/artifacts?per_page=100" \
    --jq '.artifacts[] | select(.expired == false) | [.id, .name, .created_at] | @tsv' 2>/dev/null || true
)

if [ "${#ids_to_delete[@]}" -eq 0 ]; then
  echo "No artifacts returned from API."
  exit 0
fi

if [ "$MODE" = "aggressive" ]; then
  for entry in "${ids_to_delete[@]}"; do
    id="${entry%%|*}"
    echo "Deleting artifact ${id} (aggressive)"
    gh api -X DELETE "/repos/${REPO}/actions/artifacts/${id}" >/dev/null 2>&1 || true
  done
  echo "Aggressive prune finished."
  exit 0
fi

# Keep newest KEEP artifacts whose name starts with PREFIX; delete other APK artifacts and stale entries.
apk_rows=()
other_ids=()

for entry in "${ids_to_delete[@]}"; do
  id="${entry%%|*}"
  rest="${entry#*|}"
  name="${rest%%|*}"
  created="${rest#*|}"
  if [[ "$name" == ${PREFIX}* ]]; then
    apk_rows+=("${created}|${id}|${name}")
  else
    other_ids+=("$id")
  fi
done

IFS=$'\n' sorted_apk=($(printf '%s\n' "${apk_rows[@]}" | sort -r))
deleted=0
if [ "${#sorted_apk[@]}" -gt "$KEEP" ]; then
  for ((i = KEEP; i < ${#sorted_apk[@]}; i++)); do
    row="${sorted_apk[$i]}"
    id=$(echo "$row" | cut -d'|' -f2)
    name=$(echo "$row" | cut -d'|' -f3-)
    echo "Deleting ${name} (${id})"
    gh api -X DELETE "/repos/${REPO}/actions/artifacts/${id}" >/dev/null 2>&1 \
      && deleted=$((deleted + 1)) || true
  done
fi

echo "Deleted ${deleted} old ${PREFIX} artifact(s)."
