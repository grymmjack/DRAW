---
name: copilot-migration
description: Where Copilot-era assets ended up after the 2026-05-16 migration to Claude Code, and which are intentionally not migrated yet.
metadata:
  type: project
---

On 2026-05-16, grymmjack migrated this repo off GitHub Copilot to Claude Code.

**Why:** Switching primary AI tool. User insisted "nothing left behind."

**How to apply:** When looking for DRAW deep-dive docs, check `.claude/instructions/` (not `.github/instructions/` — those are scheduled for deletion). When looking for workflows, check `.claude/skills/` (not `.github/skills/`). Stop suggesting paths under `.github/instructions/` or `.github/skills/` — those are about to be deleted.

Migration map (all 14 skills and 9 instruction files copied; content identical):

- `.github/instructions/draw-*.instructions.md` → `.claude/instructions/draw-*.md` (Copilot `applyTo:` frontmatter stripped; filenames lost the `.instructions` infix)
- `.github/skills/<name>/SKILL.md` → `.claude/skills/<name>/SKILL.md` (frontmatter compatible across both tools; cross-refs to instruction files rewritten to new paths)
- `.github/copilot-instructions.md` — Copilot-only RTK shim, redundant with global `~/.claude/RTK.md`; staged for deletion
- `.github/hooks/rtk-rewrite.json` — references `rtk hook copilot`; staged for deletion
- `.github/prompts/QB64PE.toolsets.jsonc` — Copilot MCP toolset config naming `mcp_qb64pe_*` tools; staged for deletion (Claude Code MCP config lives elsewhere)

Not touched:

- `.vscode/settings.json` does name `copilot/*` models inside `chat.mcp.serverSampling` for VS Code's built-in chat. That is VS Code workspace state, not a Copilot dependency. Left alone.
- `.github/workflows/`, `.github/ISSUE_TEMPLATE/` — GitHub Actions / GitHub UI, not Copilot. Left alone.

Cross-references updated:

- `CLAUDE.md` table at "Specialized instruction files" now points at `.claude/instructions/*.md`
- `.claude/skills/create-release/SKILL.md` (Step 6) — instruction-file table now uses new paths
- `.claude/skills/qa-auto-test/SKILL.md` (Step 1a)
- `.claude/skills/qa-test/SKILL.md` (Step 1a)
- `.claude/skills/fix-text-tool-bug/SKILL.md` (gotcha #9) — `draw-rendering.instructions.md` → `.claude/instructions/draw-rendering.md`
- `.claude/instructions/draw-text-tool.md` (now a 2-line redirector pointing at the `fix-text-tool-bug` skill at its new location)
