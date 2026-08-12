---
name: deliver-viewables-as-artifacts
description: Anything the user should VIEW → publish as an Artifact (claude.ai-hosted), never a local file. He often runs remote/web Claude Code where local files can't be reached.
metadata:
  type: feedback
---

**Always deliver anything meant to be *viewed* as an Artifact** (the `Artifact`
tool → claude.ai-hosted page with a URL). Never surface a viewable via
`SendUserFile`/local path expecting him to see it: reports, charts, rendered HTML,
screenshots, dashboards, diagrams.

**Why:** Rick frequently works in **remote / web Claude Code sessions** (the web UI
running against his Linux box). Files I create then live on the *remote*
filesystem; his browser can't reach those paths, so `SendUserFile` images don't
render and HTML won't open. This bit us repeatedly on 2026-08-12 (QA report PNGs +
HTML all unviewable) until switched to an Artifact. His words: *"just make it so
the results you share are VIEWABLE and ACCESSIBLE remotely — forever and ever."*

**How to apply:**
- Don't try to auto-detect remote vs local — I can't do it reliably. Artifacts work
  in BOTH, so default to them for every viewable deliverable.
- HTML/report output (e.g. `qa-report.py`): publish the page as an Artifact rather
  than sending the `.html` file. To render a program's HTML to an image is still
  worse than an Artifact — skip it.
- `SendUserFile` is still fine for things he'll *download/consume elsewhere* (a
  built binary, a data file), just not for things he needs to look at.
- Artifacts are private by default; he can share from the page. See
  [[qa-harness-toolkit]].
