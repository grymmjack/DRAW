#!/bin/bash
# Vendor libmypaint (ISC) into native/mypaint/ for DRAW's MyPaint brushes (PLANS/MYPAINT.md).
#   DEV/mypaint/vendor.sh [LIBMYPAINT_CHECKOUT]   (default ~/git/_ext/libmypaint, tag v1.6.1)
# Copies the brush engine + tiled surface, generates the settings headers, and patches it to
# build as C++ inside a QB64-PE DECLARE LIBRARY header without json-c or glib: DRAW parses
# .myb itself (native/mypaint_draw.h) and feeds the settings through the public setters.
set -euo pipefail
SRC="${1:-$HOME/git/_ext/libmypaint}"
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
DST="$HERE/native/mypaint"
mkdir -p "$DST/fastapprox"
FILES="helpers.c helpers.h rng-double.c rng-double.h mypaint-mapping.c mypaint-mapping.h
 mypaint-brush-settings.c mypaint-brush-settings.h mypaint-surface.c mypaint-surface.h
 mypaint-matrix.c mypaint-matrix.h mypaint-symmetry.c mypaint-symmetry.h brushmodes.c brushmodes.h
 fifo.c fifo.h tilemap.c tilemap.h operationqueue.c operationqueue.h mypaint-tiled-surface.c
 mypaint-tiled-surface.h mypaint-fixed-tiled-surface.c mypaint-fixed-tiled-surface.h
 mypaint-brush.c mypaint-brush.h mypaint.c mypaint.h mypaint-glib-compat.h mypaint-config.h
 mypaint-rectangle.c mypaint-rectangle.h tiled-surface-private.h mypaint-surface.h COPYING"
for f in $FILES; do [ -f "$SRC/$f" ] && cp "$SRC/$f" "$DST/$f"; done
cp "$SRC"/fastapprox/*.h "$DST/fastapprox/"
mkdir -p "$DST/glib"; cp "$SRC"/glib/mypaint-brush.[ch] "$DST/glib/" # (empty without MYPAINT_CONFIG_USE_GLIB)
( cd "$SRC" && python3 generate.py "$DST/mypaint-brush-settings-gen.h" "$DST/brushsettings-gen.h" )
cat > "$DST/config.h" <<'EOC'
#ifndef CONFIG_H
#define CONFIG_H
/* DRAW: no glib, no json-c, no gegl, no OpenMP */
#define MYPAINT_CONFIG_USE_GLIB 0
#endif
EOC
python3 "$HERE/DEV/mypaint/patch.py" "$DST"
echo "vendored libmypaint from $SRC ($(cd "$SRC" && git describe --tags 2>/dev/null || echo ?)) -> $DST"
