#!/bin/sh
# Fake screen-capture backend for QA (CAPTURE_BACKEND=COMMAND): writes a fixed
# 640x400 "screenshot" to the path DRAW passes, so capture tests are
# deterministic and never touch the real display.
here=$(dirname "$0")
cp "$here/capture-fixture.png" "$1"
