---
name: project-animation
description: Animation feature (started 2026-11-07) - branch `animation`, plan PLANS/ANIMATION.md, the canvas is the sprite sheet; requirements gathered with an interactive field kit
metadata:
  type: project
---

Animation is being built on branch `animation` (from main @ bb3a8e08). The plan and every decision
live in `PLANS/ANIMATION.md` on that branch; Rick's sketch is `PLANS/ANIMATION.drawy` + its PNG/SVG.

Core decision (Rick, 2026-11-07): **the canvas is the sprite sheet** - a frame is a W×H cell in
reading order, layers span the whole sheet, and the lightbox (strip + transport + 3/5/7 drawable
panes) is a separate view toggle over the same pixels. "No compromise to the existing, and only
additive tools for animators."

Requirements were gathered with an interactive "field kit" artifact (one card per question,
recommendation marked, Build report to paste back): https://claude.ai/artifact/BUDpnL2AqtaQUaJKBnFidq
(round 1: 31 answered; round 2: 12 sheet-model questions). Source in the session scratchpad
(`kit/anim-kit.src.html`, `r2-body.html`, `build-r2.py`).

**Why:** Rick asked for field-kit style interrogation over plain text for requirements.
**How to apply:** read PLANS/ANIMATION.md before animation work; for new open questions, add a
round to the same artifact rather than asking in chat. Numpad handling: see ~/git/bu1ld0r.
Related: [[feedback-test-like-the-user]].
