---
name: qb64pe-print-file-crlf
description: [Linux] QB64-PE PRINT # writes CRLF line ends - QA greps of DRAW-written files need tr -d '\r'; LINE INPUT drops the CR on read
metadata:
  type: project
---

[Linux, checked 2026-11-22 with a 5-line probe] QB64-PE's `PRINT #fh, "a"` writes `a\r\n`, not `a\n`.
Every text file DRAW writes (DRAW.cfg, `.dact` action sets, presets...) ends its lines CRLF on Linux too.
DRAW reading its own files is fine (`LINE INPUT` drops the CR), but a QA test that greps one with an
anchored pattern (`grep -q '^STEP 2007 1 0 Invert$'`) never matches, and `$(grep ...)` in a fail message
shows overlapping lines (the CR returns the cursor). Untested on macOS / Windows (Windows is CRLF anyway).

**Why:** cost a debugging round on actions-palette.sh - the file was right, the grep was not.
**How to apply:** in a test, read DRAW-written text through `tr -d '\r'` (actions-palette.sh `setf`).
Related: [[qa-windows-test-portability]].
