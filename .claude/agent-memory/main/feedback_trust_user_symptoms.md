---
name: trust-user-symptoms
description: "When the user describes a visual symptom, use their words literally — don't reinterpret 'partial paint' as 'alpha trails' or substitute your own theory of cause"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74038101-3a17-49bd-acf2-1a71a21ba671
---

When the user describes what they see on screen, take the description at face value and investigate that specific symptom. Don't translate it into your preferred theory of cause.

**Why**: During the HW image debugging session, the user reported a visual glitch and I labeled it "ghost trails / alpha leak" based on my mental model of the HW1 framebuffer. The user corrected me: *"to be clear, it was never a transparent issue - it was not trails, what you interepretted was incorrect. so to be sure - it looks like partial paint issue, not a alpha issue to me."* The two descriptions sound similar but point at different cause families — alpha leak suggests `_BLEND` corruption of dest alpha; partial paint suggests *which pixels got drawn at all*, a different debugging path entirely. My misinterpretation cost real investigation time.

**How to apply**:
- Echo the user's exact symptom words back when scoping an investigation ("partial paint", "ghost trails", "flicker", "black rectangle", "trailing pixels", etc.) — don't paraphrase into a category.
- If a screenshot is provided, describe what's actually visible in the image before forming a hypothesis. Match the user's words to the visual.
- If you do form a hypothesis that requires reframing the user's words, surface it explicitly: "you said X — I think the underlying cause is in the Y family, can you confirm that aligns with what you're seeing?" Don't silently substitute.
- The user is a career BASIC programmer (see [[user_background_and_collaboration]]) and chooses their visual vocabulary carefully. Trust the precision.

Related: [[user_background_and_collaboration]] — user wants visibility, not autonomy; that includes visibility into how you're interpreting their reports.
