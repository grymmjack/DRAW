---
name: feedback-test-like-the-user
description: QA tests must reproduce the user's own steps (overflow, junk input, docked), and region asserts on small snaps need a tight tolerance
metadata:
  type: feedback
---

Write the test the way Rick will use the feature, not the happy path. A test that
typed six hex characters (which fit the box) "proved" the Color Mixer hex box fix;
Rick docked the mixer, typed junk past the box, BackSpaced, and the text drew over
the HEX: label. He asked "did you even try using this? ... how did you test".

**Why:** the bug lived in the overflow/scroll path the tidy test never reached; it
shipped as "verified".

**How to apply:**
- For any input widget: type past its width, junk characters, delete back, click
  away - and in the layout the user has (docked, floating, their profile).
- `assert_regions_same` defaults to tolerance 1500 pixels - larger than a small
  label snap (the old overflow differed by 23-50 px and would have PASSED). Pass an
  explicit tolerance (e.g. 3) for small regions, and look at the snap PNGs once to
  confirm they frame what you mean.
- Related: [[qa-harness-toolkit]]
