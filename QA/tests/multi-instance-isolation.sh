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

SB=$(mktemp -d)
trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/cfg" "$SB/cache" "$SB/data"

run_inst() { # $1 = extra CLI args
    ( cd "$DRAW_ROOT" && \
      XDG_CONFIG_HOME="$SB/cfg" XDG_CACHE_HOME="$SB/cache" XDG_DATA_HOME="$SB/data" \
      DRAW_HEADLESS=1 timeout 20 "$DRAW_BIN" $1 >/dev/null 2>&1 )
}

run_inst ""             # primary — auto-assigns the lowest free slot (1)
run_inst "--instance 2" # secondary — explicit slot 2, isolated seeded config

REG="$SB/cache/DRAW/instances"

if [ -f "$REG/1.instance" ] && [ -f "$REG/2.instance" ]; then
    pass "registry files created for both instances"
else
    fail "registry files missing (expected 1.instance + 2.instance in $REG)"
fi

if grep -q '^id=1' "$REG/1.instance" 2>/dev/null && grep -q '^heartbeat=' "$REG/1.instance" 2>/dev/null; then
    pass "registry file carries id + heartbeat fields"
else
    fail "registry file is malformed (no id/heartbeat)"
fi

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
