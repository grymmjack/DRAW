---
name: feedback-sandbox-dotfile-pollution
description: "Claude Code's Bash sandbox creates 0-byte mount-point files in cwd (.bashrc, .zshrc, .idea, .profile, .ripgreprc, .zprofile, .bash_profile, .gitconfig) on every invocation. They persist on disk and pollute the repo root. Fix: prefix all sandboxed Bash with `cd \"$TMPDIR\" && ` so mount points land in /tmp/claude-1000 instead."
metadata:
  node_type: memory
  type: feedback
---

**User directive (explicit, repeated):** Do NOT let those husk dotfiles appear in the project repo. They were annoying enough that user already objected to .gitignoring them as a workaround.

## What's happening

Claude Code's Bash tool runs each invocation through a sandbox that:
1. Allocates bind-mount target files for known dotfile names (`.bashrc`, `.zshrc`, `.idea`, `.profile`, `.ripgreprc`, `.zprofile`, `.bash_profile`, `.gitconfig`) at the current working directory if they don't exist
2. Bind-mounts `/dev/null` over those targets to deny writes
3. Tears down mounts when the command finishes — but **leaves the 0-byte regular files on disk**

Symptom inside sandbox: `ls -la` shows them as `crw-rw-rw- 1,3 nobody nogroup` (char device 1,3 = `/dev/null`).
Symptom outside sandbox / after sandbox tears down: 0-byte regular files owned by user.

Removing them with sandbox-disabled `rm` works for that moment, but the next sandboxed Bash call from project cwd recreates them.

## How to apply

**Always prefix sandboxed Bash commands with `cd "$TMPDIR" && `** when the working directory doesn't fundamentally need to be the project root. The sandbox then creates its mount points in `/tmp/claude-1000` (which is sandbox-writable and out of sight) instead of in the project.

```bash
cd "$TMPDIR" && /home/grymmjack/git/qb64pe/qb64pe -w -x ...  # build
cd "$TMPDIR" && ls /home/grymmjack/git/DRAW/EFFECTS/         # listing
cd "$TMPDIR" && grep -n "CRT" /home/grymmjack/git/DRAW/...   # search
```

Use **absolute paths** for all project files in those commands — the cwd is now $TMPDIR so relative paths won't resolve.

**Exceptions where you MUST run from project cwd:**

- `git status`, `git diff`, `git log`, `git add`, `git commit`, `git push`, `git checkout` — git resolves the repo from cwd. Use `git -C /home/grymmjack/git/DRAW <cmd>` from $TMPDIR if you want to avoid even those, OR accept the dotfile pollution and clean up afterward.
- Anything that fundamentally inherits cwd as project context (rare — most tools take a `--cwd` or path arg).

After any inescapable project-cwd run, sweep the dotfiles via a sandbox-disabled `rm` call:
```bash
# dangerouslyDisableSandbox: true
rm -f /home/grymmjack/git/DRAW/.bashrc /home/grymmjack/git/DRAW/.zshrc /home/grymmjack/git/DRAW/.idea \
      /home/grymmjack/git/DRAW/.profile /home/grymmjack/git/DRAW/.ripgreprc /home/grymmjack/git/DRAW/.zprofile \
      /home/grymmjack/git/DRAW/.bash_profile /home/grymmjack/git/DRAW/.gitconfig
```

## What does NOT help

- Adding the names to `.gitignore` — user has explicitly rejected this as unacceptable
- Removing without changing cwd — they come right back on next sandboxed call
- `dangerouslyDisableSandbox: true` — works per-call but defeats sandbox safety
