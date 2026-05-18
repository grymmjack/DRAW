---
name: user-background-and-collaboration
description: "grymmjack is a career programmer (52, started Apple II + Applesoft BASIC in the 80s). Deep BASIC roots, wants to LEARN from collaboration, dislikes hidden/autonomous work. Show mechanisms, not just outcomes."
metadata: 
  node_type: memory
  type: user
  originSessionId: 5d441d41-d017-4658-8146-6ebf42a81f5f
---

## Background

- 52 years old. Started programming on an Apple II in the 1980s, self-taught Applesoft BASIC by reading dot-matrix printouts of listings.
- Programming became his career — it's a lifelong passion, not a job he picked up.
- The choice of QB64-PE for DRAW is rooted in this history: BASIC is his native tongue, and DRAW's "export artwork as QB64 source code" feature reflects a deep affection for the language.

## Collaboration preferences

- **Explicitly installed the Learn / Explanatory output style plugins** to combat skill atrophy from over-delegation. His own words: "my own skills are atrophying as a result of so much delegation."
- **Hates hidden/autonomous work.** Verbatim: "kinda hate how everything is hidden and going on behind my back." This is the motivation behind the `.claude/activity.log` hook ([[reference-draw-activity-log]]) — he wants visibility into what I'm doing, not just the result.
- **Wants to LEARN, not just consume output.** When I make implementation choices, surface the reasoning, the alternatives I considered, and the trade-offs. Don't just deliver — teach as I deliver.
- **Treat him as a peer.** He's a senior programmer with decades of experience. Don't over-explain basics. DO explain anything Claude-Code-specific, anything QB64-PE-internal that's non-obvious from the code, and anything that touches design decisions where a junior would just copy a pattern without understanding why.

## How to apply

- Default to the explanatory/learning output style behavior even when the system reminder isn't visible: brief `★ Insight` callouts at decision points, code shown before written (so he can react), reasoning surfaced inline rather than buried in commit messages.
- Before doing anything autonomous (background jobs, long-running tasks, multi-step refactors), tell him what's about to happen so he can intercept. The activity log is a safety net, not a replacement for clear communication.
- For DRAW-specific work, leverage his BASIC fluency — he can read QB64-PE source directly, so don't paraphrase code in prose when showing the actual lines is faster.
- For Claude Code mechanics (hooks, agents, MCP servers, skills), assume he's still learning the harness itself — those internals are worth explaining even when the task is simple.
