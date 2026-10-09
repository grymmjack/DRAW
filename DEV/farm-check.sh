#!/usr/bin/env bash
# farm-check.sh - build-check a branch on the DRAW build farm, and run the full QA
# suite on the Linux host, recording each host's state for the test dashboard
# (DEV/qa-dash.py shows a panel per host: BUILDING / BUILT / FAILED, and titan's
# live QA run).
#
#   DEV/farm-check.sh build HOST [REF]       # sync HOST's DRAW-fstest worktree to REF, build
#   DEV/farm-check.sh build-all [REF]        # every farm host, in parallel
#   DEV/farm-check.sh qa [HOST] [REF] [REGEX] # build, then the QA suite (detached); HOST = titan
#                                            # (default, offscreen Xvfb), mac or thinkpad (ONSCREEN -
#                                            # they take over that machine's screen for ~2h)
#   DEV/farm-check.sh status                 # the recorded states
#
# REF defaults to origin/<current branch>. Builds happen in each host's DRAW-fstest
# worktree (created if missing), never in the host's own checkout. Nothing opens a
# window: builds are compile-only; titan's suite runs under Xvfb, mac / thinkpad drive
# the real desktop (qa-harness drivers/macos, drivers/windows). Hosts = remote-dash.py.
# thinkpad's suite runs from C:\qa-runner (the desktop user can't read the SSH
# user's profile): its DRAW clone is synced to the same REF and gets the built exe.
# State: ~/.cache/qa-dash/farm/<host>.json
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
STATE=~/.cache/qa-dash/farm
mkdir -p "$STATE"
SSH=(ssh -o ConnectTimeout=8 -o BatchMode=yes)
QA_HOST=titan
REF_DEFAULT="origin/$(git rev-parse --abbrev-ref HEAD)"

# name|type|drawdir|compiler   (type: unix = make, win = qb64pe.exe over cmd, wsl = WSL driving the Windows exe)
HOSTS=(
  'mac|unix|$HOME/git/DRAW|$HOME/git/qb64pe/qb64pe'
  'titan|unix|$HOME/git/DRAW|$HOME/git/QB64pe/qb64pe'
  'daw|wsl|/mnt/c/Users/grymm/git/DRAW|/mnt/c/Users/grymm/git/QB64pe/qb64pe.exe'
  'thinkpad|win|C:\Users\grymmjack.thinkpad\git\DRAW|C:\Users\grymmjack.thinkpad\git\qb64pe\qb64pe.exe'
)

json_str() { local s=${1//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\r'/}; s=${s//$'\n'/ | }; printf '"%s"' "$s"; }

# record HOST key=value... (merged into the host's state file)
record() {
    local host=$1; shift
    python3 - "$STATE/$host.json" "$@" <<'PY'
import json, sys, time
f = sys.argv[1]
try:
    d = json.load(open(f))
except Exception:
    d = {}
for kv in sys.argv[2:]:
    k, _, v = kv.partition("=")
    d[k] = int(v) if v.lstrip("-").isdigit() else v
d["updated"] = int(time.time())
json.dump(d, open(f, "w"))
PY
}

host_line() { local h; for h in "${HOSTS[@]}"; do [[ "${h%%|*}" == "$1" ]] && { echo "$h"; return 0; }; done; return 1; }

# remote script that syncs the worktree to REF and builds; prints "BUILD-OK <sha>" / "BUILD-FAIL"
build_cmd() {
    local type=$1 dir=$2 comp=$3 ref=$4
    case "$type" in
      unix) cat <<EOF
set -u
cd "$dir" || exit 1
[ -e "${dir}-fstest/.git" ] || git worktree add -q --detach "${dir}-fstest" >/dev/null 2>&1
cd "${dir}-fstest" || exit 1
git fetch -q origin && git checkout -q --detach "$ref" || { echo BUILD-FAIL checkout; exit 1; }
git submodule foreach --recursive -q 'git reset -q --hard; git clean -qfdx' >/dev/null 2>&1
git submodule update -q --init --recursive --force
"$comp" -w -x -o DRAW.run DRAW.BAS > .farm-build.log 2>&1
if grep -q '^Output:' .farm-build.log; then echo "BUILD-OK \$(git rev-parse --short HEAD) \$(git -C includes/QB64_GJ_LIB rev-parse --short HEAD)"; else echo BUILD-FAIL; tail -5 .farm-build.log; fi
EOF
      ;;
      wsl) local g='"/mnt/c/Program Files/Git/cmd/git.exe"'; cat <<EOF
set -u
cd "$dir" || exit 1
[ -e "${dir}-fstest/.git" ] || $g worktree add -q --detach ../DRAW-fstest >/dev/null 2>&1
cd "${dir}-fstest" || exit 1
$g fetch -q origin && $g checkout -q --detach "$ref" || { echo BUILD-FAIL checkout; exit 1; }
$g submodule foreach --recursive -q "git reset -q --hard; git clean -qfdx" >/dev/null 2>&1
$g submodule update -q --init --recursive --force
"$comp" -w -x DRAW.BAS -o DRAW.exe > .farm-build.log 2>&1
if grep -q '^Output:' .farm-build.log; then echo "BUILD-OK \$($g rev-parse --short HEAD | tr -d '\r') \$($g -C includes/QB64_GJ_LIB rev-parse --short HEAD | tr -d '\r')"; else echo BUILD-FAIL; tail -5 .farm-build.log; fi
EOF
      ;;
      win) # one cmd.exe line
        printf '%s' "cd /d ${dir}-fstest && git fetch -q origin && git checkout -q --detach $ref && git submodule foreach --recursive -q \"git reset -q --hard && git clean -qfdx\" >NUL 2>&1 & git submodule update -q --init --recursive --force && ${comp} -w -x DRAW.BAS -o DRAW.exe > .farm-build.log 2>&1 & findstr /b /c:\"Output:\" .farm-build.log >NUL && (for /f %s in ('git rev-parse --short HEAD') do @echo BUILD-OK %s) || (echo BUILD-FAIL & powershell -NoProfile -Command \"Get-Content .farm-build.log -Tail 5\")"
      ;;
    esac
}

do_build() {
    local host=$1 ref=${2:-$REF_DEFAULT} line type dir comp out t0
    line=$(host_line "$host") || { echo "unknown host $host"; return 2; }
    IFS='|' read -r _ type dir comp <<< "$line"
    t0=$(date +%s)
    record "$host" kind=build state=building ref="$ref" started="$t0" finished=0 msg="" sha=""
    out=$("${SSH[@]}" "$host" "$(build_cmd "$type" "$dir" "$comp" "$ref")" 2>&1 | tr -d '\r' | grep -v 'already awake\|magic packet\|waiting for .* to boot')
    if grep -q '^BUILD-OK' <<< "$out"; then
        record "$host" state=built finished="$(date +%s)" sha="$(grep -m1 '^BUILD-OK' <<< "$out" | awk '{print $2}')" lib="$(grep -m1 '^BUILD-OK' <<< "$out" | awk '{print $3}')" msg="compiled"
        echo "$host: BUILT ($(( $(date +%s) - t0 ))s)"
    else
        record "$host" state=failed finished="$(date +%s)" msg="$(tail -3 <<< "$out" | tr '\n' ' ' | cut -c1-300)"
        echo "$host: FAILED"; tail -6 <<< "$out"
        return 1
    fi
}

# a shell snippet that sets T to the tests matching REGEX
qa_tests() { printf '%s' "T=\$(ls tests | grep -E '$1' | sed 's|^|tests/|' | tr '\n' ' ')"; }

do_qa() {
    local host=$QA_HOST
    if host_line "${1:-}" >/dev/null; then host=$1; shift; fi
    local ref=${1:-$REF_DEFAULT} re=${2:-.} line type dir comp rdir probe=""
    do_build "$host" "$ref" || return 1
    line=$(host_line "$host"); IFS='|' read -r _ type dir comp <<< "$line"
    rdir="${dir}-fstest/QA/.farm-results"
    case "$host" in
      mac)
        rsync -a --exclude results/ --exclude .git/ "$HOME/git/qa-harness/" mac:git/qa-harness/ || return 1
        "${SSH[@]}" mac 'bash -s' <<REMOTE 2>&1 | grep -v 'already awake'
set -u; export PATH=/opt/homebrew/bin:\$PATH
cd ${dir}-fstest/QA && rm -rf .farm-results && mkdir -p .farm-results && $(qa_tests "$re") && \
~/git/qa-harness/drivers/macos/qa-run env QA_HARNESS=\$HOME/git/qa-harness QA_RESULTS_DIR=$rdir ./draw-qa.sh --onscreen --rerun-passed \$T && echo started
REMOTE
        ;;
      thinkpad)
        rdir=/c/qa-runner/DRAW/QA/.farm-results; probe=gitbash
        tar czf - -C "$HOME/git/qa-harness" --exclude=results --exclude=.git . | "${SSH[@]}" thinkpad 'tar -xzf - -C C:/qa-runner/qa-harness' || return 1
        "${SSH[@]}" thinkpad '"C:\Program Files\Git\bin\bash.exe" -s' <<REMOTE 2>&1 | tr -d '\r' | grep -v 'already awake'
set -u
cd /c/qa-runner/DRAW || exit 1
git fetch -q origin && git checkout -q --detach "$ref" && git submodule update -q --init --recursive --force || { echo "sync failed"; exit 1; }
cp "\$(cygpath -u '${dir}')-fstest/DRAW.exe" DRAW.exe || exit 1
cd QA && rm -rf .farm-results && mkdir -p .farm-results && $(qa_tests "$re") && \
/c/qa-runner/qa-harness/drivers/windows/qa-run env QA_HARNESS=/c/qa-runner/qa-harness QA_RESULTS_DIR=$rdir ./draw-qa.sh --onscreen --rerun-passed \$T && echo started
REMOTE
        ;;
      *)
        rsync -a --exclude results/ --exclude .git/ "$HOME/git/qa-harness/" "$host:git/qa-harness/" || return 1
        "${SSH[@]}" "$host" "set -u; cd ${dir}-fstest/QA && rm -rf .farm-results && mkdir -p .farm-results && \
            $(qa_tests "$re") && \
            nohup env QA_HARNESS=\$HOME/git/qa-harness QA_RESULTS_DIR=$rdir QA_XVFB_RES=3840x2160 setsid ./draw-qa.sh --rerun-passed \$T > .farm-results/runner.out 2>&1 < /dev/null & echo started" \
            2>&1 | grep -v 'already awake\|magic packet\|waiting for .* to boot'
        ;;
    esac
    record "$host" kind=qa state=qa-running results="$rdir" probe="$probe" qa_started="$(date +%s)" pattern="$re"
    echo "$host: QA suite started (results in $rdir) - watch it on ./DEV/qa-dash.sh"
}

case "${1:-}" in
  build)     shift; do_build "$@" ;;
  build-all) shift; for h in "${HOSTS[@]}"; do do_build "${h%%|*}" "${1:-$REF_DEFAULT}" & done; wait ;;
  qa)        shift; do_qa "$@" ;;
  status)    for f in "$STATE"/*.json; do [[ -f "$f" ]] && { echo "== $(basename "$f" .json)"; cat "$f"; echo; }; done ;;
  *)         sed -n '2,14p' "$0"; exit 2 ;;
esac
