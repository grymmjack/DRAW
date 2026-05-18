---
name: isolated-tests-first
description: "When investigating QB64-PE quirks or proposing risky changes to DRAW, build the smallest standalone .BAS test in DEV/EXPERIMENTS/ that asserts the hypothesis BEFORE touching DRAW source"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74038101-3a17-49bd-acf2-1a71a21ba671
---

Before any risky or speculative change to DRAW — especially anything touching QB64-PE rendering/alpha/blend quirks — build a minimal standalone `.BAS` reproduction in `DEV/EXPERIMENTS/` first.

**Why**: The user said it directly: *"let's check your hunches. make a separate test outside of draw that asserts what you want to test in the simplest way before we waste a ton of time."* When we followed this during the HW image investigation, the 8 test programs (`HW_IMAGE_TEST`, `HW_PARTIAL_MIX_TEST`, `ALPHA_PRESERVE_TEST`, `SETALPHA_VERIFY_TEST`, etc.) all reported "clean, no issues in any mode" — which correctly told us the bug wasn't where we thought (it was a HW1-vs-modal-dialog interaction we couldn't reach with isolated tests). Without those tests we would have churned in DRAW for hours chasing the wrong cause. The user explicitly validated the approach by greenlighting it and engaging deeply with the test outputs.

**How to apply**:
- Any time the proposal involves QB64-PE behavior you can't cite chapter-and-verse on (alpha handling, `_BLEND`/`_DONTBLEND` semantics, hardware images, `_PUTIMAGE` source/dest combinations, `_SETALPHA` propagation), write the isolation test first.
- Keep the test self-contained: single `.BAS` file, no DRAW includes, console-printed pass/fail, runs in seconds.
- Save it under `DEV/EXPERIMENTS/`. The directory is committed but excluded from the DRAW build chain — pure scratch space.
- After landing the change, leave the test files in place. They become regression anchors and document QB64-PE quirks discovered along the way.

Related: [[feedback_qb64pe_wiki_first]] — wiki check before isolated test; both happen before touching DRAW source.
