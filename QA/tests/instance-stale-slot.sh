#!/bin/bash
# =============================================================================
# instance-stale-slot.sh — QA test: the multi-instance registry frees a slot
# whose DRAW is gone at once (Rick 2026-11-18: "it is still showing the [2]" /
# "can we clean these up somehow" - "i used the x or the alt-x").
#
# Each registry file (<cache>/DRAW/instances/N.instance) now carries pid=; a slot
# whose pid no longer exists is stale straight away, not after 60 s of heartbeat.
#   1. a running DRAW's slot 1 names its own pid
#   2. a planted slot 2 with a fresh heartbeat but a dead pid: a second DRAW
#      takes slot 2 (it is free)
#   3. a planted slot 2 with a fresh heartbeat and a live pid: the second DRAW
#      takes slot 3 (that one is in use)
#   4. Alt+X: DRAW exits and removes its slot file
# (draw_launch wipes the cache dir, so the second DRAW is started here)
# The QA cache is the run's own (XDG_CACHE_HOME), never the user's registry.
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Instances: stale slots ==="

if [[ "${QA_OS:-}" == Windows ]]; then # (the harness points LOCALAPPDATA at the run's cache there)
    REG="$(cygpath -u "$LOCALAPPDATA")/DRAW/instances"
else
    REG="${XDG_CACHE_HOME:-$HOME/.cache}/DRAW/instances"
fi
ospid() { if [[ -r /proc/$1/winpid ]]; then cat "/proc/$1/winpid"; else echo "$1"; fi; } # DRAW writes the OS pid; Git Bash's $! is its own
field() { sed -n "s/^$2=//p" "$1" 2>/dev/null | tr -d '\r'; }
now_timer() { echo $(( $(date +%s) - $(date -d 00:00 +%s) )); } # QB64 TIMER: seconds since midnight
plant() { # SLOT PID: a slot file with a fresh heartbeat
    mkdir -p "$REG"
    printf 'id=%s\r\ntoken=1\r\nheartbeat=%s\r\ntitle=DRAW\r\nmailbox=%s/mailbox/%s/\r\npid=%s\r\n' "$1" "$(now_timer)" "$REG" "$1" "$2" > "$REG/$1.instance"
}
mine() { # -> the slot whose pid is DRAW's
    local f; for f in "$REG"/*.instance; do [[ "$(field "$f" pid)" == "$(ospid "$DRAW_PID")" ]] && basename "$f" .instance && return; done
}
relaunch() { draw_quit; draw_settle 2>/dev/null; draw_launch 15; wait_for 2.0 "registered"; }

info "registry: $REG"
# --- 1. own pid ------------------------------------------------------------------------
wait_for 2.0 "registered"
S=$(mine)
[[ "$S" == 1 ]] && pass "slot 1 names this DRAW's pid ($DRAW_PID)" || fail "no slot with pid $DRAW_PID [$(grep -H pid= "$REG"/*.instance 2>/dev/null | tr '\n' ' ')]"

# --- a second DRAW started here (draw_launch wipes the cache: a planted slot would go) --
second() { # -> B_PID, B_SLOT: a DRAW beside the harness's one, on the same registry
    ( cd "$DRAW_ROOT" && QB64PE_NOPROMPT=y exec "$DRAW_BIN" --config "$QA_CFG" $DRAW_TEST_OPTIONS ) > /dev/null 2>&1 &
    B_PID=$!; B_OS=$(ospid "$B_PID")
    B_SLOT=""
    for _ in $(seq 1 30); do
        sleep 0.5
        for f in "$REG"/*.instance; do [[ "$(field "$f" pid)" == "$B_OS" ]] && B_SLOT=$(basename "$f" .instance); done
        [[ -n "$B_SLOT" ]] && break
    done
}
stop_second() { kill "$B_PID" 2>/dev/null; for _ in $(seq 1 20); do kill -0 "$B_PID" 2>/dev/null || break; sleep 0.5; done; kill -9 "$B_PID" 2>/dev/null; wait "$B_PID" 2>/dev/null; rm -f "$REG/$B_SLOT.instance"; }

# --- 2. a dead pid with a fresh heartbeat in slot 2 ---------------------------------------
sleep 0.3 & DEAD=$!; DEAD_OS=$(ospid "$DEAD"); wait "$DEAD" 2>/dev/null
plant 2 "$DEAD_OS"
second
[[ "$B_SLOT" == 2 ]] && pass "slot 2 (fresh heartbeat, dead pid) is taken over by a new DRAW" || fail "with a dead pid in slot 2 the new DRAW took slot '$B_SLOT' [$(/bin/ls "$REG")]"
stop_second

# --- 3. a live pid keeps its slot -------------------------------------------------------------
sleep 300 & LIVE=$!
plant 2 "$(ospid "$LIVE")"
second
[[ "$B_SLOT" == 3 ]] && pass "a live pid keeps slot 2: the new DRAW is slot 3" || fail "with a live pid in slot 2 the new DRAW took slot '$B_SLOT' [$(/bin/ls "$REG")]"
stop_second
kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null
rm -f "$REG/2.instance"

# --- 4. Alt+X removes its slot ------------------------------------------------------------------
P=$DRAW_PID
key alt+x; wait_for 3.0 "exit"
for _ in 1 2 3 4 5 6; do kill -0 "$P" 2>/dev/null || break; sleep 0.5; done
if kill -0 "$P" 2>/dev/null; then
    fail "Alt+X: DRAW (pid $P) still running"
else
    pass "Alt+X: DRAW exited"
    [[ -f "$REG/1.instance" ]] && fail "Alt+X: slot 1 left behind [$(tr '\r\n' '  ' < "$REG/1.instance")]" || pass "Alt+X: its slot file is gone"
fi
DRAW_PID=""
# (no assert_no_crash: step 4 quits DRAW; the runner still checks the crash log)
info "=== Instances: stale slots: done ==="
