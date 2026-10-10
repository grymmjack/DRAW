#!/bin/bash
# scratch (not committed): custom brush (noflip), then the line tool zoomed in
info "=== line + custom brush (noflip) ==="
canvas_focus b
key grave; sleep 0.2
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 10 )) $(( CANVAS_CY + 10 )); sleep 0.3
key m; sleep 0.3
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX )) $(( CANVAS_CY + 20 )); sleep 0.3
key ctrl+b; sleep 0.5

key b; sleep 0.3
for n in 1 2 3; do key ctrl+equal; sleep 0.3; done
key l; sleep 0.3
drag $(( CANVAS_CX + 10 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 25 )); sleep 0.5
key ctrl+0; sleep 0.5
park_mouse; screenshot "line-noflip"
