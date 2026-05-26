---
name: feedback-self-blocking-context-bug
description: In context-aware dispatchers where the context table is updated before the dispatch pass, a binding must never include its own state-trigger bit in forbidCtx. Otherwise the binding self-blocks the moment its key transitions to down.
metadata:
  type: feedback
---

When adding a binding for a key that *also* sets a context bit (chord
initiator: M/Z/E/F/W in DRAW), do NOT put that key's own CTX_*_HELD bit
in the binding's `forbidCtx`. The key will never fire.

**Why:** the DRAW main loop runs `INPUT_update_context` BEFORE
`INPUT_detect_events` and `INPUT_dispatch_frame`. On the very first
frame a chord-initiator key is pressed:
1. update_context sees the raw _KEYDOWN and sets CTX_<key>_HELD
2. detect_events sees the up→down edge and enqueues EVT_KEY_PRESS
3. dispatch_frame matches against the binding — CTX_<key>_HELD is
   now TRUE, forbidCtx blocks → no fire, ever.

**How to apply:** when registering a binding for a chord-initiator
tool key, build a custom `chordHeldNo<X>` mask that excludes the
own bit. See `chordHeldNoM/Z/E/F/W` in INPUTS_register_all in
INPUT/INPUT.BM for the pattern. The chord bindings (Z+1..0, M+=, etc.)
are unaffected — they live on a different keycode and *require*
CTX_<X>_HELD, which is fine.

This is a class of bug specific to dispatchers where context updates
and binding matches happen in the same frame. Pure "level"-based
checks don't have this issue; the bug only appears with the combination
of (edge-triggered fire) + (context-gating) + (self-set context).

Caught and fixed in `7d1c196` after Phase 6a-iii flipped M/Z/E/F/W to
dispatched=TRUE. User reported "i cannot switch to the zoom tool with
z key" — symptom was the chord-initiator tools silently doing nothing.

Related memories:
- [[reference-input-system]] — full input dispatch architecture
- [[feedback-hotkey-grep-sweep]] — manual grep approach that motivated
  the dispatcher rearchitecture
