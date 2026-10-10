#!/bin/bash
# scratch (not committed): step back through the undo history of Rick's bug file
info "=== undo steps ==="
park_mouse; sleep 0.5
screenshot "u00"
for n in 1 2 3 4 5 6 7 8; do key ctrl+z; sleep 0.4; park_mouse; screenshot "u0$n"; done
