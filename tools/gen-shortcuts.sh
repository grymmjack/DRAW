#!/usr/bin/env bash
# Regenerate the "Generated binding index" in SHORTCUTS.md from the input registry.
#
# Runs `DRAW --dump-shortcuts` (which walks INPUTS_register_all and writes
# SHORTCUTS.tables.md), then splices those tables into SHORTCUTS.md between the
# <!-- BINDINGS:START --> / <!-- BINDINGS:END --> markers. The curated prose
# outside the markers is left untouched (the "augment" model).
#
# Needs a display (the generator runs after SCREEN_init); uses xvfb-run when headless.
set -euo pipefail
cd "$(dirname "$0")/.."   # repo root

DRAW="${DRAW:-./DRAW.run}"
[ -x "$DRAW" ] || { echo "gen-shortcuts: build DRAW first (make)"; exit 1; }

rm -f SHORTCUTS.tables.md
if [ -n "${DISPLAY:-}" ]; then
    "$DRAW" --dump-shortcuts >/dev/null 2>&1 || true
else
    command -v xvfb-run >/dev/null || { echo "gen-shortcuts: no DISPLAY and no xvfb-run"; exit 1; }
    xvfb-run -a "$DRAW" --dump-shortcuts >/dev/null 2>&1 || true
fi
[ -f SHORTCUTS.tables.md ] || { echo "gen-shortcuts: generator produced no SHORTCUTS.tables.md"; exit 1; }

awk '
  $0 ~ /BINDINGS:START/ { print; while ((getline line < "SHORTCUTS.tables.md") > 0) print line; print ""; skip=1; next }
  $0 ~ /BINDINGS:END/   { skip=0; print; next }
  !skip { print }
' SHORTCUTS.md > SHORTCUTS.md.tmp && mv SHORTCUTS.md.tmp SHORTCUTS.md

rm -f SHORTCUTS.tables.md
echo "gen-shortcuts: SHORTCUTS.md binding index regenerated."
