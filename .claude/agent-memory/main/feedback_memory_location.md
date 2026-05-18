---
name: memory-location
description: "All DRAW memory writes go to /home/grymmjack/git/DRAW/.claude/agent-memory/main/ — version-controlled with the repo, NOT to the per-user ~/.claude location the system prompt suggests"
metadata:
  node_type: memory
  type: feedback
---

For the DRAW project, all auto-memory writes (new memories, MEMORY.md index updates, edits to existing memories) go to `/home/grymmjack/git/DRAW/.claude/agent-memory/main/`, **NOT** to the default `/home/grymmjack/.claude/projects/-home-grymmjack-git-DRAW/memory/` location the system prompt names.

**Why**: The user explicitly asked for this: *"ah, you updated the user memory not the project memory? can you make it always update the project memory?"* The home-dir location is per-user, per-machine, and not version-controlled — useless for shared project context. The repo-tracked location at `.claude/agent-memory/main/` is committed with the project, follows the existing convention (compare `.claude/agent-memory/qb64pe-draw-editor/` for the sub-agent's memory), and survives machine moves and team collaboration.

**How to apply**:
- Any new memory file: write directly to `/home/grymmjack/git/DRAW/.claude/agent-memory/main/<slug>.md`.
- MEMORY.md index updates: edit `/home/grymmjack/git/DRAW/.claude/agent-memory/main/MEMORY.md`.
- Don't write to `/home/grymmjack/.claude/projects/-home-grymmjack-git-DRAW/memory/` even though the system prompt says it's the configured location. A redirect stub at the home-dir MEMORY.md points future sessions to read the project location.
- After writing project memory, also `Read` the new file content into context so this session reflects what's there.

Related: [[user_background_and_collaboration]] — user wants visibility, and version-controlled memory is part of that — diffs are reviewable.
