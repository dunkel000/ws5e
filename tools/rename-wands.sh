#!/usr/bin/env bash
set -euo pipefail

SED=$(command -v gsed || command -v sed)

EXCLUDES=(
  --exclude-dir=.git
  --exclude-dir=dist
  --exclude=package-lock.json
  --exclude-dir=node_modules
  --exclude='*.png' --exclude='*.jpg' --exclude='*.webp' --exclude='*.woff*'
)

backup_suffix=".bak_wands_$(date +%s)"

echo "== Step 1: System manifest ids =="
"$SED" -i"$backup_suffix" 's/"id": *"dnd5e"/"id": "wands"/' system.json
"$SED" -i"$backup_suffix" 's/"title": *"Dungeons & Dragons 5e"/"title": "Wizards & Shadows"/' system.json
"$SED" -i"$backup_suffix" 's/"esmodules": *\["dnd5e\\.mjs"\]/"esmodules": ["wands.mjs"]/' system.json

echo "== Step 2: foundryvtt.json metadata (safe string tweaks) =="
"$SED" -i"$backup_suffix" 's/Dungeons & Dragons 5e/Wizards & Shadows/g' foundryvtt.json
"$SED" -i"$backup_suffix" 's/dnd5e/wands/g' foundryvtt.json

echo "== Step 3: entry module rename =="
if [[ -f dnd5e.mjs && ! -f wands.mjs ]]; then
  git mv dnd5e.mjs wands.mjs
fi

echo "== Step 4: CONFIG namespace (code) =="
while IFS= read -r -d '' file; do
  "$SED" -i"$backup_suffix" 's/CONFIG\.DND5E/CONFIG.WANDS/g' "$file"
done < <(rg -0 -l -S 'CONFIG\.DND5E' "${EXCLUDES[@]}" --glob '!system.json' --glob '!foundryvtt.json' --glob '!lang/*.json' || true)

echo "== Step 5: System id in code imports/paths =="
while IFS= read -r -d '' file; do
  "$SED" -i"$backup_suffix" "s/[\"']dnd5e[\"']/\"wands\"/g" "$file"
done < <(rg -0 -l -S "[\"']dnd5e[\"']" "${EXCLUDES[@]}" --glob '!system.json' --glob '!foundryvtt.json' --glob '!lang/*.json' || true)

echo "== Step 6: Packs rename in system.json =="
"$SED" -i"$backup_suffix" 's/"name": *"dnd5e-/"name": "wands-/g' system.json
"$SED" -i"$backup_suffix" 's/"path": *"packs\/dnd5e-/"path": "packs\/wands-/g' system.json

echo "== Step 7: Compendium source folders =="
if ls packs/_source/dnd5e-* >/dev/null 2>&1; then
  for f in packs/_source/dnd5e-*; do
    git mv "$f" "${f/packs\/\_source\/dnd5e-/packs\/\_source\/wands-}"
  done
fi

echo "== Step 8: Localization root keys (optional, staged) =="
while IFS= read -r -d '' file; do
  "$SED" -i"$backup_suffix" 's/DND5E\./WANDS./g' "$file"
done < <(rg -0 -l -S 'DND5E\.' "${EXCLUDES[@]}" --glob '!lang/*.json' || true)

echo "== Step 9: Provide a compatibility alias early in wands.mjs =="
echo "# (manual step) Add: CONFIG.DND5E = CONFIG.WANDS; // TEMP for backward references"

echo "== DONE =="
