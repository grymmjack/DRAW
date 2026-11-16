---
name: feedback-reply-where-comment-was
description: Before replying to a pasted GitHub comment, find where it was posted (PR vs issue) and reply there
metadata:
  type: feedback
---

When Rick pastes a maintainer's comment, look it up with `gh pr view N --comments` / `gh issue view N --comments` and reply in that same thread. Don't guess from how Rick describes it.

**Why:** On 2026-11-09 mkilgore commented on PR #812. Rick said "to the issue", and I posted the reply on issue #811. Rick had to delete it and repost it on the PR.

**How to apply:** Any reply to upstream feedback. Related: [[qb64pe-mem-errors-critical]].
