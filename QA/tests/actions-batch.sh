#!/bin/bash
# =============================================================================
# actions-batch.sh — QA test: Actions from the command line (OUTPUT/BATCH + TOOLS/ACTIONS).
#   1. --action SET/NAME --batch-in DIR --batch-out OUT: every image in DIR (PNG, JPG; a .txt
#      skipped) played and saved to OUT as PNG, same names; exit 0; the action really ran
#      (inverted, pixel for pixel for the PNG; within a few levels for the JPG)
#   2. --batch-format draw: .draw files (PNG with the drAw chunk)
#   3. a stop in the action does not hold a batch up (it goes on by itself)
#   4. FILE --action NAME --export out.png: the action on one document, then the export
#   5. an unknown --action: exit 1, the message lists the actions there are
#   6. --batch-in without --action: exit 1
# Each run is its own DRAW (no window input: a CLI run exits when done), with its own HOME /
# XDG folders and --option ACTIONS_DIR=<scratch> holding the set file this test writes.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Actions: --action / --batch-in on the command line ==="

AB="$(mktemp -d /tmp/draw-qa-actbatch-XXXXXX)"
mkdir -p "$AB/acts" "$AB/in" "$AB/home"
cat > "$AB/acts/QA CLI.dact" <<'EOF'
SET 1 1 QA CLI
ACTION 1 1 Negate
STEP 2007 1 0 Invert
ACTION 1 1 Negate Stop
STEP -1 1 0 This stop must not hold a batch up
STEP 2007 1 0 Invert
EOF
: > "$AB/acts/.seeded" # (no starter set)
magick -size 40x30 gradient:orange-navy "PNG32:$AB/in/alpha.png"
magick -seed 7 -size 32x32 plasma:fractal -quality 95 "$AB/in/beta.jpg"
echo "not an image" > "$AB/in/readme.txt"
neg() { magick "$1" -channel RGB -negate +channel "PNG32:$2"; }
neg "$AB/in/alpha.png" "$AB/alpha-neg.png"

# run DRAW ARGS...: its exit code in RC, its console in $AB/out.txt
run() { ( cd "$DRAW_ROOT" && HOME="$AB/home" XDG_CONFIG_HOME="$AB/home/.config" XDG_DATA_HOME="$AB/home/.local/share" \
        XDG_CACHE_HOME="$AB/home/.cache" timeout --foreground -k 5 120 "$DRAW_BIN" --option "ACTIONS_DIR=$AB/acts" "$@" </dev/null >"$AB/out.txt" 2>&1 ); RC=$?; }
ae() { magick compare -metric AE "$1" "$2" null: 2>&1 | awk '{print $1}'; }

draw_quit
draw_settle

# --- 1. a folder, PNG -------------------------------------------------------------------------
run --action "QA CLI/Negate" --batch-in "$AB/in" --batch-out "$AB/out"
info "console: $(grep -iE 'wrote|failed|batch' "$AB/out.txt" | tail -3 | tr '\n' '|')"
N=$(ls "$AB/out" 2>/dev/null | wc -l)
(( RC == 0 && N == 2 )) && [[ -f "$AB/out/alpha.png" && -f "$AB/out/beta.png" ]] && pass "--batch-in: alpha.png + beta.png in the output folder, exit 0 (readme.txt skipped)" || fail "exit $RC, $N files [$(ls "$AB/out" 2>&1 | tr '\n' ' ')] $(tail -2 "$AB/out.txt" | tr '\n' '|')"
[[ "$(ae "$AB/out/alpha.png" "$AB/alpha-neg.png")" == 0 ]] && pass "alpha.png: inverted, pixel for pixel" || fail "alpha.png differs from its negative ($(ae "$AB/out/alpha.png" "$AB/alpha-neg.png") px)"
# the JPG: the negative of DRAW's own decode (DRAW opens it, so compare against a PNG of it)
if [[ -f "$AB/out/beta.png" ]]; then
    m=$(magick "$AB/out/beta.png" -alpha off \( "$AB/in/beta.jpg" -alpha off -negate \) -compose difference -composite -format '%[fx:maxima*255]' info: 2>/dev/null)
    awk -v m="$m" 'BEGIN { exit !(m != "" && m <= 6) }' && pass "beta.jpg -> beta.png: inverted (largest difference $m of 255: the JPEG decoders)" || fail "beta.png: largest difference from the negative '$m'"
fi

# --- 2. --batch-format draw ---------------------------------------------------------------------
run --action "Negate" --batch-in "$AB/in" --batch-out "$AB/out-draw" --batch-format draw
TY=$(python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" types "$AB/out-draw/alpha.draw" 2>/dev/null | tr '\n' ' ')
(( RC == 0 )) && [[ -f "$AB/out-draw/beta.draw" && "$TY" == *drAw* ]] && pass "--batch-format draw: .draw files (drAw chunk), a bare action name found" || fail "exit $RC, [$(ls "$AB/out-draw" 2>&1 | tr '\n' ' ')] chunks '$TY'"

# --- 3. a stop does not hold a batch up ---------------------------------------------------------
run --action "QA CLI/Negate Stop" --batch-in "$AB/in" --batch-out "$AB/out-stop"
(( RC == 0 )) && [[ "$(ae "$AB/out-stop/alpha.png" "$AB/alpha-neg.png")" == 0 ]] && pass "an action with a stop: the batch goes on past it (inverted)" || fail "with a stop: exit $RC, alpha $(ae "$AB/out-stop/alpha.png" "$AB/alpha-neg.png" 2>&1)"

# --- 4. one document: --action then --export -----------------------------------------------------
run "$AB/in/alpha.png" --action "Negate" --export "$AB/one.png"
(( RC == 0 )) && [[ "$(ae "$AB/one.png" "$AB/alpha-neg.png")" == 0 ]] && pass "FILE --action Negate --export: the export is inverted" || fail "one document: exit $RC, $(ae "$AB/one.png" "$AB/alpha-neg.png" 2>&1) px; $(tail -2 "$AB/out.txt" | tr '\n' '|')"

# --- 5. an unknown action ----------------------------------------------------------------------
run "$AB/in/alpha.png" --action "No Such/Thing" --export "$AB/none.png"
(( RC == 1 )) && [[ ! -f "$AB/none.png" ]] && grep -q "QA CLI/Negate" "$AB/out.txt" && pass "an unknown --action: exit 1, nothing written, the actions listed" || fail "unknown action: exit $RC; $(tail -2 "$AB/out.txt" | tr '\n' '|')"

# --- 6. --batch-in without --action ------------------------------------------------------------
run --batch-in "$AB/in" --batch-out "$AB/out-none"
(( RC == 1 )) && [[ ! -d "$AB/out-none" ]] && pass "--batch-in without --action: exit 1" || fail "--batch-in alone: exit $RC; $(tail -2 "$AB/out.txt" | tr '\n' '|')"

draw_launch 15
assert_window_exists
rm -rf "$AB"
