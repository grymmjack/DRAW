#!/bin/bash
# =============================================================================
# multi-instance-isolation.sh — QA test: --instance N registry + isolated config.
#
# Multi-instance identity resolves at INCLUDE time (INSTANCE_bootstrap, before any
# window is created), so it is verified headless as subprocesses inside an ISOLATED
# XDG sandbox — this touches NONE of the user's real config/cache/data dirs and does
# not interfere with the harness's own GUI DRAW instance. Same subprocess approach as
# cli-options.sh. Guards: CORE/INSTANCE (registry, heartbeat, mailbox) and the
# per-instance seeded config in CFG/CONFIG.BI.
# =============================================================================

info "=== Multi-instance isolation test ==="
# The sandbox redirects DRAW through the XDG dirs, which only DRAW's Linux build
# uses; on macOS / Windows it would reach the user's real cache - skip there.
[[ "${QA_OS:-Linux}" == Linux ]] || { skip "multi-instance-isolation: XDG sandbox is Linux-only (on $QA_OS)"; return 0; }

SB=$(mktemp -d)
trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/cfg" "$SB/cache" "$SB/data"

run_inst() { # $1 = extra CLI args
    ( cd "$DRAW_ROOT" && \
      XDG_CONFIG_HOME="$SB/cfg" XDG_CACHE_HOME="$SB/cache" XDG_DATA_HOME="$SB/data" \
      DRAW_HEADLESS=1 timeout 20 "$DRAW_BIN" $1 >/dev/null 2>&1 )
}

REG="$SB/cache/DRAW/instances"

# Each headless run exits and leaves its slot file, but its pid is then gone, so the
# next DRAW frees that slot at once (stale by pid, 7210c4a2) - check slot 1 before the
# second run, not after it.
run_inst ""             # primary — auto-assigns the lowest free slot (1)
[ -f "$REG/1.instance" ] && S1=1 || S1=0
if grep -q '^id=1' "$REG/1.instance" 2>/dev/null && grep -q '^heartbeat=' "$REG/1.instance" 2>/dev/null && grep -q '^pid=' "$REG/1.instance" 2>/dev/null; then
    pass "registry file carries id + heartbeat + pid fields"
else
    fail "registry file is malformed (no id/heartbeat/pid): $(tr '\r\n' '  ' < "$REG/1.instance" 2>/dev/null)"
fi
run_inst "--instance 2" # secondary — explicit slot 2, isolated seeded config

if (( S1 )) && [ -f "$REG/2.instance" ]; then
    pass "registry files created for both instances"
else
    fail "registry files missing (slot 1 after the first run: $S1; 2.instance now: $([ -f "$REG/2.instance" ] && echo yes || echo no) in $REG)"
fi
[ -f "$REG/1.instance" ] && fail "slot 1's DRAW is gone but its file stayed (not freed by pid)" || pass "the second DRAW freed slot 1 (its pid is gone)"

# Secondary must get its OWN config, seeded from the base config (not shared).
if ls "$SB/cfg/DRAW/"*instance-2*.cfg >/dev/null 2>&1; then
    pass "secondary instance received an isolated instance-2 config"
else
    fail "no isolated instance-2 config was created (config would be shared/clobbered)"
fi

# Per-instance mailbox inboxes exist (the layer-handoff drop points).
if [ -d "$REG/mailbox/1" ] && [ -d "$REG/mailbox/2" ]; then
    pass "per-instance mailbox dirs created"
else
    fail "mailbox dirs missing"
fi

assert_no_crash
info "=== Multi-instance isolation test PASSED ==="
