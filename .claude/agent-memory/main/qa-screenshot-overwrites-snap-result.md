---
name: qa-screenshot-overwrites-snap-result
description: QA harness `screenshot` overwrites SNAP_RESULT - take it after the assert that uses the last snap_region
metadata:
  type: reference
---

In the qa-harness DRAW adapter, `screenshot "name"` sets `SNAP_RESULT` too, so
`snap_region ...; screenshot ...; assert_regions_same "$A" "$SNAP_RESULT"` compares against the
full screenshot and fails ("regions differ" by a huge count). Copy the snap first
(`B="$SNAP_RESULT"`) or call `screenshot` after the assert. Hit in actions-palette.sh 5f
(2026-11-22). Harness behaviour, OS-agnostic. Related: [[qa-harness-toolkit]].
