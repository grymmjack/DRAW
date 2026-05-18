# Claude Code project setup — activity log + version-controlled memory

This directory configures two reusable patterns for working with Claude Code on any project. Both are designed to give you visibility into what Claude does and to make Claude's accumulated knowledge survive across machines, teammates, and sessions.

The pieces are:

1. **`.claude/activity.log`** — a tailable, append-only log of every Bash and Agent tool call Claude makes, written by a hook.
2. **`.claude/agent-memory/<agent-name>/`** — per-agent, version-controlled memory directory that overrides Claude Code's default per-user home-directory memory location.

Everything described here is copy-pasteable into another project (work or personal). Adjust paths and you're done.

---

## 1. Activity log

### What it gives you

A side-terminal `tail -f` view of everything Claude is doing in your project. Each Bash and Agent call appends a record like:

```
=== 2026-05-18 13:42:11  START Bash [BG] [timeout=600000ms] ===
  desc: Compile DRAW to verify revert is clean
  cwd:  /home/grymmjack/git/DRAW
  cmd:  /home/grymmjack/git/qb64pe/qb64pe -w -x DRAW.BAS -o DRAW.run
--- 2026-05-18 13:42:48  END Bash ---
  -- stdout --
  | QB64-PE Compiler V4.4.0-UNKNOWN
  | Beginning C++ output from QB64 code...
  | Compiling C++ code into executable...
  | Output: /home/grymmjack/git/DRAW/DRAW.run
```

`[BG]` marks `run_in_background: true` calls — useful because the Claude Code VSCode panel doesn't show stdout from background calls. `[timeout=...]` shows the explicit timeout. `!! INTERRUPTED` appears when a call was killed.

### How it works

A `PreToolUse` + `PostToolUse` hook (matcher: `Bash|Agent`) calls `.claude/hooks/activity-log.sh`. The script reads Claude Code's hook JSON from stdin, extracts the relevant fields with `jq`, and appends a record.

Per-stream output is capped (80 lines / 8 KB) so a runaway compile log can't fill the file.

### Setup in any project

1. Copy `.claude/hooks/activity-log.sh` to your new project. The script is self-contained — only depends on `jq` (silently no-ops if missing).
2. Register the hook in `.claude/settings.local.json`:

   ```jsonc
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash|Agent",
           "hooks": [
             { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/activity-log.sh" }
           ]
         }
       ],
       "PostToolUse": [
         {
           "matcher": "Bash|Agent",
           "hooks": [
             { "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/activity-log.sh" }
           ]
         }
       ]
     }
   }
   ```

3. Add `.claude/activity.log` to `.gitignore`. The log is per-machine, not shareable, and grows fast.
4. In a side terminal: `tail -f .claude/activity.log`.

### Critical rule for the hook script

Claude Code interprets hook stdout as protocol JSON. **The hook must stay silent on stdout** (redirect everything to the log file or `/dev/null`). It also must exit 0 even on internal errors so it never blocks a tool call. The reference script (`activity-log.sh`) follows both rules.

### Bonus: compile log tee'd from your Makefile

For projects with a build step worth replaying after the fact, tee the build's stdout/stderr into a second log file. In this project's Makefile:

```makefile
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
MAKE_LOG := .claude/make.log

$(OUT): $(SOURCES)
	@echo "=== $$(date '+%Y-%m-%d %H:%M:%S')  $(COMPILER) ... ===" >> $(MAKE_LOG)
	$(COMPILER) ... 2>&1 | tee -a $(MAKE_LOG)
```

`pipefail` is what makes this safe — without it, `tee`'s success exit code masks the compiler's failure. With it, `make` still fails correctly when the compile fails, and the log gets every warning the build emitted. Add `.claude/make.log` to `.gitignore`.

---

## 2. Version-controlled agent memory

### The problem

Claude Code's default memory location is `~/.claude/projects/<encoded-project-path>/memory/`. That's per-user, per-machine, not version-controlled. If you switch machines, change accounts, or onboard a teammate, all the knowledge Claude has built up about your project is lost.

### The fix

Put memory in the repo at `.claude/agent-memory/<agent-name>/`, commit it, and leave a one-line redirect stub in the home-dir location so Claude Code follows it.

### Directory layout

```
.claude/agent-memory/
├── main/                          ← default Claude session writes here
│   ├── MEMORY.md                  ← index (one line per memory)
│   ├── feedback_<topic>.md        ← corrections + confirmed-good approaches
│   ├── project_<topic>.md         ← project-specific facts with motivation/deadlines
│   ├── reference_<topic>.md       ← pointers to external systems
│   ├── user_<topic>.md            ← user role/preferences/context
│   └── feedback_memory_location.md ← REQUIRED — tells future sessions to write here, not home dir
└── qb64pe-draw-editor/            ← per-sub-agent memory (one dir per specialized agent)
    ├── MEMORY.md
    └── project-conventions.md
```

### File format

Each memory file uses YAML frontmatter + markdown body:

```markdown
---
name: short-kebab-case-slug
description: one-line summary used to decide future relevance
metadata:
  type: feedback   # or user, project, reference
---

For feedback/project memories, lead with the rule or fact, then:

**Why**: the reason the user gave (often a past incident or strong preference)
**How to apply**: when and where this guidance kicks in

Use [[other-memory-slug]] to link to related memories.
```

`MEMORY.md` is the index — one line per file, under ~150 characters, e.g.:

```markdown
- [Memory location](feedback_memory_location.md) — ALWAYS write project memory to `.claude/agent-memory/main/`, NOT to `~/.claude/projects/...`
- [Trust user symptoms](feedback_trust_user_symptoms.md) — echo the user's exact symptom words; don't silently reinterpret
```

It must stay short — Claude loads `MEMORY.md` into context at session start and truncates after 200 lines.

### Memory types — what to save vs. not

| Type | Save when… | Example |
|---|---|---|
| `user` | You learn about the user's role, expertise, preferences | "career BASIC programmer, prefers visibility over autonomy" |
| `feedback` | The user corrects your approach **or confirms a non-obvious approach worked** | "isolated tests in `DEV/EXPERIMENTS/` before touching main source — user explicitly asked for this" |
| `project` | You learn project facts with motivation/deadlines that won't show up in git | "merge freeze begins 2026-03-05 for mobile release cut" |
| `reference` | You learn about external systems (issue trackers, dashboards, etc.) | "pipeline bugs tracked in Linear project INGEST" |

**Don't** save: code patterns, architecture, file paths, debugging fix recipes, anything already in `CLAUDE.md` or derivable from `git log`. Those rot fast and live better in the code or docs.

### The home-dir redirect — the trick that makes this stick

Claude Code's system prompt names the home-dir memory location at session start. To override it permanently for this project, replace `~/.claude/projects/<encoded>/memory/MEMORY.md` with a one-line redirect:

```markdown
- **REDIRECT** — Project memory has moved to `<absolute path>/.claude/agent-memory/main/MEMORY.md`. Read that index and write all new/updated memories to `<absolute path>/.claude/agent-memory/main/<slug>.md`. Do NOT write to this directory.
```

Future sessions load that line, see the redirect, and follow it to the version-controlled location. Reinforce it inside the project memory with a `feedback_memory_location.md` so the policy lives in two places — the home-dir stub (system-prompted) and the project memory (loaded after redirect).

### Setup in any project

1. `mkdir -p .claude/agent-memory/main`
2. Create `.claude/agent-memory/main/MEMORY.md` with at least one entry (the memory-location feedback below).
3. Create `.claude/agent-memory/main/feedback_memory_location.md` with the policy ("write here, not to home dir").
4. Find your home-dir path (Claude Code encodes the project path with hyphens): for `/home/you/work/proj` it's `~/.claude/projects/-home-you-work-proj/memory/`.
5. Replace that directory's `MEMORY.md` with a one-line redirect pointing back to `.claude/agent-memory/main/MEMORY.md`. Delete the old per-memory files in the home dir if you have any (they're orphaned now).
6. Commit `.claude/agent-memory/` to the repo. `.claude/agent-memory/` should **not** be in `.gitignore`.

After step 6, every machine and teammate that clones the repo gets the same memory. The home-dir redirect stub is per-user, so each user has to seed it once — but they only have to do that step, and the project memory carries the policy forward.

### Why per-agent subdirectories

If you use Claude Code sub-agents (e.g. a specialized agent invoked via `Agent({ subagent_type: "..." })`), each one keeps its own memory namespace under `.claude/agent-memory/<agent-name>/`. The default Claude session uses `.claude/agent-memory/main/`. This keeps specialized-agent context from polluting general-session context and vice versa.

---

## 3. What `.gitignore` should say

```
.claude/activity.log
.claude/make.log
.claude/settings.local.json   # if it contains user-specific permission allowlists
```

**Don't** ignore:

```
.claude/agent-memory/         # version-controlled, the whole point
.claude/hooks/                # the hook script is part of the project
.claude/instructions/         # focused docs for Claude (if you use them)
.claude/README.md             # this file
```

---

## Quick reference — replicating this in a work project

```bash
# 1. Hooks + activity log
mkdir -p .claude/hooks
cp /path/to/DRAW/.claude/hooks/activity-log.sh .claude/hooks/
chmod +x .claude/hooks/activity-log.sh
# Add the PreToolUse/PostToolUse blocks to .claude/settings.local.json

# 2. Memory
mkdir -p .claude/agent-memory/main
# Write MEMORY.md + feedback_memory_location.md (copy the DRAW versions and edit)

# 3. Home-dir redirect (one-time per machine)
# Path = ~/.claude/projects/<dashes-instead-of-slashes>/memory/MEMORY.md
echo '- **REDIRECT** — Project memory has moved to <abs path>/.claude/agent-memory/main/MEMORY.md. Read that index and write all new/updated memories to <abs path>/.claude/agent-memory/main/<slug>.md. Do NOT write to this directory.' \
  > ~/.claude/projects/<encoded-path>/memory/MEMORY.md

# 4. .gitignore
printf '.claude/activity.log\n.claude/make.log\n' >> .gitignore

# 5. Commit
git add .claude/hooks .claude/agent-memory .claude/settings.local.json .claude/README.md
git commit -m "claude: activity log + version-controlled memory"
```

After this, run a session, watch `tail -f .claude/activity.log` in a side terminal, and let memory accumulate in `.claude/agent-memory/main/` over time. Diff-reviewable, teammate-shareable, machine-portable.
