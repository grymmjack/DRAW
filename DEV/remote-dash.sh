#!/usr/bin/env bash
# remote-dash.sh — at-a-glance status of DRAW builds on remote test machines.
#
# Shows, per host: reachable?, build running?, DRAW binary size+mtime, and the
# tail of the newest log. Queries all hosts in PARALLEL so a down host doesn't
# stall the others.
#
#   ./DEV/remote-dash.sh            # one snapshot
#   ./DEV/remote-dash.sh --watch    # refresh every 3s (Ctrl+C to quit)
#   ./DEV/remote-dash.sh --watch 5  # refresh every 5s
#   ./DEV/remote-dash.sh --log HOST # dump the newest full log from HOST and exit
#
# Hosts are declared below as "name|type|drawdir". type = unix | win.

set -u

# ── host table ────────────────────────────────────────────────────────────────
HOSTS=(
  "mac|unix|\$HOME/git/DRAW"
  "titan|unix|\$HOME/git/DRAW"
  "thinkpad|win|C:/Users/grymmjack/git/DRAW"
)

SSH_OPTS=(-o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
TAIL_N=18

# Per-host "next human action" notes. I (or you) set these as a task moves along;
# the dashboard shows them in the NEXT column. Falls back to a derived hint.
STATUS_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)/.claude/remote-status"
mkdir -p "$STATUS_DIR" 2>/dev/null

# ── colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RST=$'\e[0m'; C_DIM=$'\e[2m'; C_BOLD=$'\e[1m'
  C_GRN=$'\e[32m'; C_RED=$'\e[31m'; C_YEL=$'\e[33m'; C_CYN=$'\e[36m'; C_MAG=$'\e[35m'
else
  C_RST=; C_DIM=; C_BOLD=; C_GRN=; C_RED=; C_YEL=; C_CYN=; C_MAG=
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── remote probe payloads ─────────────────────────────────────────────────────
# Emit key=value lines + a LOGSTART/LOGEND block. Unix and Windows produce the
# same schema so the renderer is host-agnostic.

unix_probe() {  # $1 = drawdir (unquoted, may contain $HOME)
  cat <<UNIX
d="$1"
echo "REACH=1"
if pgrep -x qb64pe >/dev/null 2>&1; then echo "BUILD=building"; else echo "BUILD=idle"; fi
bin="\$d/DRAW.run"
if [ -f "\$bin" ]; then
  # GNU stat (-c) first — both Linux hosts; fall back to BSD stat (-f) on macOS.
  sz=\$(stat -c%s "\$bin" 2>/dev/null || stat -f%z "\$bin" 2>/dev/null)
  mt=\$(stat -c "%y" "\$bin" 2>/dev/null | awk '{print \$2}' | cut -d. -f1)
  [ -z "\$mt" ] && mt=\$(stat -f "%Sm" -t "%H:%M:%S" "\$bin" 2>/dev/null)
  echo "BINSZ=\$sz"; echo "BINMT=\$mt"
else echo "BINSZ=0"; echo "BINMT=-"; fi
log=\$(ls -t "\$d"/*.log 2>/dev/null | head -1)
echo "LOGFILE=\$log"
echo "LOGSTART"
[ -n "\$log" ] && tail -${TAIL_N} "\$log" 2>/dev/null
echo "LOGEND"
UNIX
}

win_probe_ps() {  # $1 = drawdir (windows path)
  cat <<PS
\$d = '$1'
Write-Output "REACH=1"
\$b = Get-Process qb64pe -ErrorAction SilentlyContinue
Write-Output ("BUILD=" + \$(if (\$b) { 'building' } else { 'idle' }))
\$bin = Join-Path \$d 'DRAW.exe'
if (Test-Path \$bin) { \$f = Get-Item \$bin; Write-Output ("BINSZ=" + \$f.Length); Write-Output ("BINMT=" + \$f.LastWriteTime.ToString('HH:mm:ss')) }
else { Write-Output "BINSZ=0"; Write-Output "BINMT=-" }
\$log = Get-ChildItem (Join-Path \$d '*.log') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Output ("LOGFILE=" + \$(if (\$log) { \$log.FullName } else { '' }))
Write-Output "LOGSTART"
if (\$log) { Get-Content \$log.FullName -Tail ${TAIL_N} }
Write-Output "LOGEND"
PS
}

probe_host() {  # $1=name $2=type $3=drawdir  → writes $WORK/$1.out
  local name="$1" type="$2" dir="$3" out="$WORK/$1.out"
  if [ "$type" = "win" ]; then
    # UTF-16LE base64 → -EncodedCommand sidesteps all cmd/ps quoting.
    local enc
    enc=$(win_probe_ps "$dir" | iconv -f utf-8 -t utf-16le | base64 | tr -d '\n')
    # Windows PowerShell emits CRLF — strip \r so key=value compares work.
    ssh "${SSH_OPTS[@]}" "$name" "powershell -NoProfile -EncodedCommand $enc" 2>/dev/null | tr -d '\r' >"$out"
    [ -s "$out" ] || echo "REACH=0" >"$out"
  else
    ssh "${SSH_OPTS[@]}" "$name" "bash -s" >"$out" 2>/dev/null <<<"$(unix_probe "$dir")" \
      || echo "REACH=0" >"$out"
  fi
}

getv() { sed -n "s/^$2=//p" "$1" | head -1; }

human() { # bytes → e.g. 20.1M
  local b="${1:-0}"
  if [ "$b" -ge 1048576 ] 2>/dev/null; then awk "BEGIN{printf \"%.1fM\", $b/1048576}"
  elif [ "$b" -ge 1024 ] 2>/dev/null; then awk "BEGIN{printf \"%.0fK\", $b/1024}"
  else echo "${b}B"; fi
}

# Print a colored cell padded to a fixed DISPLAY width. Padding is computed from
# the plain text's CHARACTER count (${#plain}) — which equals display width for
# our width-1 glyphs (● ○ ⚙) — so ANSI codes and multibyte symbols don't skew it.
emit_cell() { # $1=plain  $2=width  $3=color(optional)
  local plain="$1" width="$2" color="${3:-}" pad
  pad=$(( width - ${#plain} )); [ "$pad" -lt 0 ] && pad=0
  printf '%s%s%s%*s' "$color" "$plain" "$C_RST" "$pad" ''
}

# ── --set / --clear: manage the per-host NEXT note ────────────────────────────
if [ "${1:-}" = "--set" ] && [ -n "${2:-}" ]; then
  shift; host="$1"; shift
  printf '%s' "$*" >"$STATUS_DIR/$host.status"
  echo "set NEXT for $host: $*"; exit 0
fi
if [ "${1:-}" = "--clear" ] && [ -n "${2:-}" ]; then
  rm -f "$STATUS_DIR/$2.status"; echo "cleared NEXT for $2"; exit 0
fi

# Derived NEXT hint when no explicit note is set.
derive_next() { # $1=reach $2=build $3=binsz
  if [ "$1" != "1" ]; then echo "⚠ host down — check SSH/power"
  elif [ "$2" = "building" ]; then echo "⏳ wait — build running"
  elif [ -n "${3:-}" ] && [ "${3:-0}" != "0" ]; then echo "▶ ready — run/test"
  else echo "—"; fi
}

# ── --log HOST mode: dump newest full log ─────────────────────────────────────
if [ "${1:-}" = "--log" ] && [ -n "${2:-}" ]; then
  name="$2"
  for h in "${HOSTS[@]}"; do
    IFS='|' read -r hn ht hd <<<"$h"
    [ "$hn" = "$name" ] || continue
    if [ "$ht" = "win" ]; then
      enc=$(printf '$l=Get-ChildItem (Join-Path "%s" "*.log") -EA SilentlyContinue|Sort LastWriteTime -Desc|Select -First 1; if($l){Write-Output $l.FullName; Get-Content $l.FullName}' "$hd" | iconv -f utf-8 -t utf-16le | base64 | tr -d '\n')
      ssh "${SSH_OPTS[@]}" "$hn" "powershell -NoProfile -EncodedCommand $enc"
    else
      ssh "${SSH_OPTS[@]}" "$hn" "bash -s" <<<'d='"$hd"'; l=$(ls -t "$d"/*.log 2>/dev/null|head -1); echo "$l"; [ -n "$l" ] && cat "$l"'
    fi
    exit 0
  done
  echo "unknown host: $name" >&2; exit 1
fi

# ── render one frame ──────────────────────────────────────────────────────────
render() {
  # kick off all probes in parallel
  local pids=()
  for h in "${HOSTS[@]}"; do
    IFS='|' read -r hn ht hd <<<"$h"
    # NOTE: hd keeps a literal $HOME for unix hosts so the REMOTE shell expands it
    # (mac/titan home paths differ from this box). Do not expand it locally.
    probe_host "$hn" "$ht" "$hd" &
    pids+=($!)
  done
  wait "${pids[@]}" 2>/dev/null

  printf "%s╭─ %sDRAW Remote Build Dashboard%s %s──%s %s %s─╮%s\n" \
    "$C_CYN" "$C_BOLD" "$C_RST$C_CYN" "$C_DIM" "$C_RST$C_CYN" "$(date +%H:%M:%S)" "$C_CYN" "$C_RST"
  printf "  %s%-10s %-7s %-11s %-22s%s\n" "$C_DIM" "HOST" "REACH" "BUILD" "BINARY" "$C_RST"

  for h in "${HOSTS[@]}"; do
    IFS='|' read -r hn ht hd <<<"$h"
    local out="$WORK/$hn.out"
    local reach build binsz binmt
    reach=$(getv "$out" REACH); build=$(getv "$out" BUILD)
    binsz=$(getv "$out" BINSZ); binmt=$(getv "$out" BINMT)

    local reach_plain reach_color build_plain build_color bin_main
    if [ "$reach" = "1" ]; then reach_plain="● up"; reach_color="$C_GRN"; else reach_plain="○ down"; reach_color="$C_RED"; fi
    case "$build" in
      building) build_plain="⚙ building"; build_color="$C_YEL";;
      idle)     build_plain="idle";       build_color="$C_DIM";;
      *)        build_plain="-";          build_color="$C_DIM";;
    esac
    if [ -n "${binsz:-}" ] && [ "${binsz:-0}" != "0" ]; then
      bin_main="$(human "$binsz")  ${C_DIM}${binmt}${C_RST}"
    else bin_main="${C_DIM}(none)${C_RST}"; fi

    printf "  "
    emit_cell "$hn"          10 "$C_BOLD"; printf " "
    emit_cell "$reach_plain"  7 "$reach_color"; printf " "
    emit_cell "$build_plain" 11 "$build_color"; printf " "
    printf "%b\n" "$bin_main"
  done
  printf "%s╰%s╯%s\n" "$C_CYN" "$(printf '─%.0s' {1..54})" "$C_RST"

  # log tails
  for h in "${HOSTS[@]}"; do
    IFS='|' read -r hn ht hd <<<"$h"
    local out="$WORK/$hn.out" logfile
    [ "$(getv "$out" REACH)" = "1" ] || continue
    logfile=$(getv "$out" LOGFILE)
    [ -n "$logfile" ] || continue
    printf "%s ── %s: %s ──%s\n" "$C_MAG" "$hn" "$(basename "$logfile")" "$C_RST"
    sed -n '/^LOGSTART$/,/^LOGEND$/p' "$out" | sed '1d;$d' | sed 's/^/   /'
  done
}

# ── main ──────────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--watch" ]; then
  interval="${2:-3}"
  while true; do
    frame=$(render)
    clear
    printf '%s\n' "$frame"
    printf "%s refreshing every %ss — Ctrl+C to quit%s\n" "$C_DIM" "$interval" "$C_RST"
    sleep "$interval"
  done
else
  render
fi
