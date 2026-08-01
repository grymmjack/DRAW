#!/bin/bash
# ai-echo.sh — pseudo AI engine for testing DRAW's AI integration.
#
# Stands in for a real generator (pixelmon) so the whole pipeline — macro
# expansion, async launch, sentinel, newest-PNG import — can be exercised in
# about a second instead of several minutes.
#
# It honours the same contract DRAW expects of any tool:
#   * accepts a prompt plus arbitrary flags
#   * writes its PNG into the directory given by --output-to
#   * names it after --name
#
# Usage (as configured in DRAW.ai.cfg ARGS):
#   "{prompt}" --size {sw}x{sh} --seed {seed} --output-to {outdir} --name {outname}
#
# Options:
#   --size WxH | N   output size (default 64x64)
#   --seed N         seed; drives the generated pattern so runs are reproducible
#   --output-to DIR  where to write (default cwd)
#   --name BASE      filename base (default "ai-echo")
#   --delay SECS     fake "generation time" (default 1)
#   --fail           exit non-zero, to test DRAW's error path
#   --no-png         exit 0 but produce nothing, to test the no-output path

set -u

PROMPT=""
SIZE="64x64"
SEED=0
OUTDIR="."
NAME="ai-echo"
DELAY=1
FAIL=0
NOPNG=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --size)      SIZE="$2"; shift 2 ;;
        --seed)      SEED="$2"; shift 2 ;;
        --output-to) OUTDIR="$2"; shift 2 ;;
        --name)      NAME="$2"; shift 2 ;;
        --delay)     DELAY="$2"; shift 2 ;;
        --fail)      FAIL=1; shift ;;
        --no-png)    NOPNG=1; shift ;;
        --*)         shift ;;            # ignore unknown flags, like a real CLI would
        *)           [[ -z "$PROMPT" ]] && PROMPT="$1"; shift ;;
    esac
done

W="${SIZE%x*}"
H="${SIZE#*x}"
[[ "$H" == "$SIZE" ]] && H="$W"          # square form: --size 64
[[ "$W" =~ ^[0-9]+$ ]] || W=64
[[ "$H" =~ ^[0-9]+$ ]] || H=64

echo "ai-echo: prompt='$PROMPT'"
echo "ai-echo: size=${W}x${H} seed=$SEED"
echo "ai-echo: output-to=$OUTDIR name=$NAME"

sleep "$DELAY"

if [[ $FAIL -eq 1 ]]; then
    echo "ai-echo: failing on purpose" >&2
    exit 3
fi
if [[ $NOPNG -eq 1 ]]; then
    echo "ai-echo: exiting 0 without producing a PNG"
    exit 0
fi

mkdir -p "$OUTDIR"
OUT="$OUTDIR/${NAME}-${SEED}.png"

# Seed-driven colours so a repeated seed reproduces the same image, and a
# different seed visibly differs — enough to verify import end to end.
hue() { printf "%02x" $(( ($1 * 37 + $2 * 53) % 256 )); }
C1="#$(hue "$SEED" 1)$(hue "$SEED" 2)$(hue "$SEED" 3)"
C2="#$(hue "$SEED" 7)$(hue "$SEED" 5)$(hue "$SEED" 11)"

# NB: no -annotate here on purpose — ImageMagick needs a configured font for
# text and fails outright without one, which would look like a generator bug.
if command -v magick &>/dev/null; then
    magick -size "${W}x${H}" "gradient:${C1}-${C2}" \
        -fill "$C1" -draw "rectangle 0,0 $(( W / 4 )),$(( H / 4 ))" \
        "$OUT" 2>/dev/null
elif command -v convert &>/dev/null; then
    convert -size "${W}x${H}" "gradient:${C1}-${C2}" "$OUT" 2>/dev/null
else
    # No ImageMagick: emit a minimal valid 1x1 PNG so the pipeline still works
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\xcf\xc0\x00\x00\x03\x01\x01\x00\x18\xdd\x8d\xb0\x00\x00\x00\x00IEND\xaeB\x60\x82' > "$OUT"
fi

if [[ -f "$OUT" ]]; then
    echo "ai-echo: wrote $OUT"
    exit 0
fi
echo "ai-echo: failed to write $OUT" >&2
exit 1
