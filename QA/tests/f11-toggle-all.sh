#!/bin/bash
# =============================================================================
# f11-toggle-all.sh — QA test: F11 hides every panel and puts back exactly
# what was showing, in Default and in a workspace (Rick, 2026-11-14: "F11
# hide/show all ... is missing a bunch of panels and breaking state of
# workspace layout").
#
# Before: in a workspace that hid anything, F11 only toggled what the
# workspace hid (the rest stayed up); and its "show" forced the toolbar,
# status bar, layers and menu bar on, even ones that were off.
#
#  1. Default, with Swatches / Animation / Color Mixer / Preview showing:
#     F11 hides every element; F11 again restores the same set and dock tree
#  2. hidden, then a CONFIG_save (the strip's size menu is not reachable, so a
#     DRAW.cfg still says the panels are visible
#  3. workspace F11 TEST (hides the layer panel + edit bar): F11 hides all, F11
#     brings back the workspace's layout - layers / edit bar stay hidden
#  4. Shift+F11 there shows what the workspace hid; again hides it
#  5. F11 hidden, then back to Default: Default's panels show (not all hidden)
#
# Dump: UIALL <hiddenByF11> <tbed> NAME=0/1 ... (each WS_EL_ element, live) | WSA | TREE
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=/tmp/draw-qa-ws-f11 STOCK_DEFAULT_LAYOUT=0 WORKSPACE_SAVE_PROMPT=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# (the panels are shown with their toggles, not --option pins: pins are never saved, and 2 checks DRAW.cfg)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
WSD="/tmp/draw-qa-ws-f11"
mkdir -p "$WSD"; rm -f "$WSD"/*.workspace
printf '; QA fixture\n[WORKSPACE]\nNAME=F11 Test\n[CHROME]\nLAYER_PANEL=HIDE\nEDIT_BAR=HIDE\n' > "$WSD/f11-test.workspace"

pal() { # QUERY - run a command palette entry
    local try
    for try in 1 2 3; do
        dk_park; key question; wait_for 1.0 "palette"
        grep -q '^POPUP cmdpalette' "$DK_DUMP" && break
    done
    type_text "$1"; wait_for 1.2 "filtered"; key Return; wait_for 1.5 "$1"; dk_settle
}
wsa() { awk '$1=="WSA" {print $2}' "$DK_DUMP"; }
uiall() { UI_LINE=$(grep -m1 '^UIALL ' "$DK_DUMP"); read -r _ UI_HID UI_TBED _ <<< "$UI_LINE"; UI_ELS=$(cut -d' ' -f4- <<< "$UI_LINE"); }
el() { grep -o "\b$1=[01]" <<< "$UI_ELS" | cut -d= -f2; }
# the elements F11 hides (organizer / drawer go with the toolbox, the strip with the status bar)
F11_ELS="MENUBAR TOOLBOX LAYER_PANEL EDIT_BAR ADVANCED_BAR STATUS_BAR PREVIEW COLOR_MIXER CHARMAP COLOR_SPACE_3D ADV_COLOR_PICKER PEN_PANEL BROWSER ANIM_PANEL SWATCHES"
all_off() { local e bad=""; for e in $F11_ELS; do [[ "$(el $e)" == 0 ]] || bad+=" $e"; done; echo "$bad"; }
f11() { dk_park; key F11; wait_for 0.8 "F11"; dk_settle; uiall; }

info "=== F11: hide all / restore exactly ==="
dk_begin
pal "reload workspaces"

# --- 1. Default ------------------------------------------------------------------------
uiall
[[ "$(el SWATCHES)" == 1 ]] || pal "toggle swatches panel"
uiall; [[ "$(el ANIM_PANEL)" == 1 ]] || pal "toggle animation panel"
uiall; [[ "$(el COLOR_MIXER)" == 1 ]] || pal "toggle color mixer"
uiall; [[ "$(el PREVIEW)" == 1 ]] || pal "preview window"
dk_park; wait_for 0.6 "settle"; dk_settle; uiall
BEFORE="$UI_ELS"; TREE0="$(dk_tree)"
info "Default before: $BEFORE"
for e in SWATCHES ANIM_PANEL COLOR_MIXER PREVIEW; do [[ "$(el $e)" == 1 ]] || fail "setup: $e is not showing"; done
grep -qE '^SWATCHES_VISIBLE=-?1' "$QA_CFG" || info "(DRAW.cfg: $(grep '^SWATCHES_VISIBLE' "$QA_CFG"))"

f11
BAD=$(all_off)
(( UI_HID == 1 )) && [[ -z "$BAD" ]] && pass "Default, F11: every panel hidden" || fail "F11 left showing:$BAD (hidden flag $UI_HID)"
screenshot "f11-all-hidden"

# --- 2. a save while hidden keeps the real state ----------------------------------------
pal "snap panel edges"; pal "snap panel edges"
vis_on() { grep -qE "^$1_VISIBLE=-?1\b" "$QA_CFG"; } # (CONFIG_save writes -1 or 1 for on; CRLF lines)
vis_on SWATCHES && vis_on COLOR_MIXER && vis_on PREVIEW && vis_on ANIM_PANEL \
    && pass "hidden by F11: DRAW.cfg still has the panels visible" \
    || fail "DRAW.cfg took F11's hiding: $(grep -E '^(SWATCHES|COLOR_MIXER|PREVIEW|ANIM_PANEL)_VISIBLE=' "$QA_CFG" | tr '\n' ' ')"

f11
[[ "$UI_ELS" == "$BEFORE" && "$UI_HID" == 0 ]] && pass "Default, F11 again: exactly the same panels back" || fail "F11 restore: [$UI_ELS] want [$BEFORE]"
[[ "$(dk_tree)" == "$TREE0" ]] && pass "and the same dock tree" || fail "dock tree changed: [$(dk_tree)] was [$TREE0]"

# --- 3. a workspace that hides the layers + edit bar --------------------------------------
pal "workspace: f11 test"
[[ "$(wsa)" == f11-test ]] && pass "F11 TEST is active" || fail "active '$(wsa)'"
dk_park; wait_for 0.6 "settle"; dk_settle; uiall
WS_BEFORE="$UI_ELS"; WTREE0="$(dk_tree)"
[[ "$(el LAYER_PANEL)" == 0 && "$(el EDIT_BAR)" == 0 ]] || fail "the workspace did not hide layers / edit bar: $UI_ELS"
f11
BAD=$(all_off)
[[ -z "$BAD" ]] && pass "in the workspace, F11: every panel hidden (not only what it hid)" || fail "F11 in the workspace left showing:$BAD"
f11
[[ "$UI_ELS" == "$WS_BEFORE" ]] && pass "F11 again: the workspace's layout exactly (layers / edit bar still hidden)" || fail "restore: [$UI_ELS] want [$WS_BEFORE]"
[[ "$(dk_tree)" == "$WTREE0" ]] && pass "and the same dock tree" || fail "dock tree changed: [$(dk_tree)] was [$WTREE0]"

# --- 4. Shift+F11: what the workspace hid ----------------------------------------------
dk_park; key shift+F11; wait_for 0.8 "reveal"; dk_settle; uiall
[[ "$(el LAYER_PANEL)" == 1 ]] && pass "Shift+F11 shows what the workspace hid (layers)" || fail "Shift+F11: $UI_ELS"
dk_park; key shift+F11; wait_for 0.8 "re-hide"; dk_settle; uiall
[[ "$UI_ELS" == "$WS_BEFORE" ]] && pass "Shift+F11 again: hidden again" || fail "Shift+F11 again: [$UI_ELS] want [$WS_BEFORE]"

# --- 5. hidden by F11, then Default -------------------------------------------------------
f11
pal "workspace: default"
dk_park; wait_for 0.6 "settle"; dk_settle; uiall
[[ "$(wsa)" == default && "$UI_HID" == 0 && "$UI_ELS" == "$BEFORE" ]] && pass "F11-hidden, then Default: Default's panels, all showing" || fail "Default after F11: '$(wsa)' hidden $UI_HID [$UI_ELS] want [$BEFORE]"
[[ "$(dk_tree)" == "$TREE0" ]] && pass "and Default's dock tree" || fail "dock tree: [$(dk_tree)] was [$TREE0]"
grep -q 'LAYER_PANEL\|EDIT_BAR' "$WSD/f11-test.workspace" && [[ "$(grep -c . "$WSD/f11-test.workspace")" -le 8 ]] \
    && pass "the workspace file did not take F11's hiding" || info "workspace file now: $(tr '\n' '|' < "$WSD/f11-test.workspace")"
grep -qiE '^(PREVIEW|SWATCHES|COLOR_MIXER|ANIM_PANEL|MENUBAR|TOOLBOX)=HIDE' "$WSD/f11-test.workspace" \
    && fail "F11's hiding was written into the workspace: $(tr '\n' '|' < "$WSD/f11-test.workspace")" || pass "no HIDE from F11 in the workspace file"
assert_no_crash
rm -rf "$WSD"
info "=== F11: hide all / restore exactly: done ==="
