---
name: feedback-overnight-qa-resources
description: "I'm going to bed" / "I am going to work" = Rick's screen + machine + whole farm are free (onscreen + offscreen QA at once); never sit in foreground waits; when he asks for suites, shard them 5-6 lanes over the farm; kill stray DRAW processes
metadata:
  type: feedback
---
[Linux] Rick, 2026-11-17 (after a night where I ran one offscreen suite at a time and polled it in
foreground 10-minute waits):

- **"When i say 'i'm going to bed' that means you can take my screen and you can use off and on
  screen."** Overnight, run an onscreen QA run (`draw-qa.sh --onscreen`, his real display) AND an
  offscreen (Xvfb) run at the same time - two independent lanes, two different test lists, each
  with its own `DRAW_BIN` private build. While he is awake his screen stays off limits.
- **"Don't just start qa jobs in the foreground and simply wait. use the time we have together
  productively. queue things up so that they can run in a sequence that won't create time waste."**
  Start runs in the background (`run_in_background`), chain the next run to start when the
  previous ends (one script / queue per lane), and do other work (code, docs, next fix, next
  build) meanwhile. A `timeout 590 until grep Results` loop that does nothing else is waste.
- **The farm** (titan, daw, mac, thinkpad - [[reference-remote-mac-windows-testing]],
  [[farm-build-recipes-per-host]]): Rick asked "if the farm was up would that help? couldn't you
  test also on the titan and daw and mac and windows?" - yes: split a targeted list across hosts
  in parallel ([[feedback-parallelize-farm-work]]); mac / thinkpad take over their screens
  ([[farm-no-gui-popups-trap-crashes]]). Check which hosts are up first (`DEV/farm-check.sh`).

**Why:** a night has ~8 h; serial offscreen runs plus idle polling used it for ~2 test lanes' worth.
**How to apply:** at "going to bed", plan the lanes (onscreen + offscreen + farm hosts), queue
targeted lists on each ([[feedback-test-scope]] still holds - no full suites), keep working.

**At work (2026-11-17):** "i am going to work you have control over the computer", "you can use
anything in the farm", "kill everything you see if it's draw" (stray DRAW / Xvfb / chains), and
"spread the suites out to the farm so they run faster. you should be able to run like 5 or 6 test
suites in parallel this way." So when Rick is away he does want full suites, sharded: local
offscreen + his screen onscreen + titan + daw + mac + thinkpad, one shard each. Order he set:
the feature work, then the bug fixes, then the suites. Farm hosts sync to `origin/<branch>` - with
uncommitted work, rsync the tree (or ask before pushing).

