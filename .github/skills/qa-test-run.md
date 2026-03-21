---
description: "Execute a QA test checklist for DRAW. Moves test file to WIP, presents tests one by one, tracks pass/fail, cascades checkmarks hierarchically, and moves completed files to RESULTS."
---

# QA Test — Run Test Checklist

When the user invokes this skill (e.g. "run tests for X", "qa-test-run", "start testing FILL"), execute an existing test checklist from `PLANS/TESTS/`. Follow these steps **in order**. Do not skip steps.

---

## Step 0 — Accept test file and move to WIP

Ask the user which test file to run:

> "Which test file should I run? Available files in `PLANS/TESTS/`:"

List all `.md` files in `PLANS/TESTS/` (excluding WIP and RESULTS subdirectories). If only one file exists, confirm it.

Once confirmed, move the file to `PLANS/TESTS/WIP/`:

```bash
mv PLANS/TESTS/{NAME}.md PLANS/TESTS/WIP/{NAME}.md
```

If the user specifies a file already in `PLANS/TESTS/WIP/`, skip the move and resume from where testing left off.

---

## Step 1 — Read and present overview

Read the WIP test file. Present a summary:

> **Test file**: `PLANS/TESTS/WIP/{NAME}.md`
> **Categories**: N
> **Total tests**: P
> **Already passed**: Q
> **Remaining**: P - Q
>
> **Ready to start.**

If some tests are already marked `[x]`, resume from the first unchecked test.

---

## Step 2 — Present next test

Find the first unchecked (`[ ]`) test case (an `####` heading with `[ ]`). Present it with:

1. **Category** and **sub-category** context (the parent `##` and `###` headings)
2. **Setup instructions** (the description text under the `###` sub-category)
3. **Test name** (the `####` heading)
4. **Steps** (the numbered `[ ]` list)

Format:

> ### Testing: {CATEGORY} → {SUB-CATEGORY} → {TEST NAME}
>
> **Setup**: {setup instructions from sub-category description}
>
> **Steps**:
> 1. {step 1}
> 2. {step 2}
> ...
>
> Run through these steps and tell me the result: **passed**, **failed**, or **skip**.

---

## Step 3 — Record result

### On pass ("works", "fixed", "passed", "pass", "ok", "good", "yes", "done")

1. Mark the test's `####` heading as `[x]`
2. Mark all its steps as `[x]`
3. **Cascade upward**:
   - Check if ALL tests under the parent `### SUB-CATEGORY` are now `[x]` → if yes, mark the `###` heading as `[x]`
   - Check if ALL sub-categories under the parent `## CATEGORY` are now `[x]` → if yes, mark the `##` heading as `[x]`
   - Check if ALL categories under `# {NAME} TESTING` are now `[x]` → if yes, mark the `#` heading as `[x]` and go to **Step 5**
4. Save the updated file
5. Continue to **Step 2** (next test)

### On fail ("failed", "fail", "broken", "bug", "no", "nope")

1. Leave the test as `[ ]`
2. Ask the user to briefly describe the failure
3. Add a blockquote note under the test steps:
   ```markdown
   > **FAILED**: {user's description} — {date}
   ```
4. Save the updated file
5. Continue to **Step 2** (next test)

### On skip ("skip", "later", "defer")

1. Leave the test as `[ ]`
2. Add a blockquote note:
   ```markdown
   > **SKIPPED**: {reason if given} — {date}
   ```
3. Continue to **Step 2** (next test)

---

## Step 4 — Progress updates

After every 5 tests (or when a category completes), show a progress summary:

> **Progress**: Q/{P} tests passed ({percentage}%)
> **Categories complete**: {list of [x] categories}
> **Current category**: {current ## heading}
> **Remaining in category**: {count}

---

## Step 5 — Completion

When ALL tests are marked `[x]` (the top-level `#` heading is `[x]`):

1. Move the file from WIP to RESULTS:
   ```bash
   mv PLANS/TESTS/WIP/{NAME}.md PLANS/TESTS/RESULTS/{NAME}.md
   ```

2. Announce:
   > **All tests complete!** `{NAME}.md` has been moved to `PLANS/TESTS/RESULTS/`.
   > **Final results**: P/P tests passed across N categories.

If there are still unchecked tests but the user wants to stop:

> Save progress. The file remains in `PLANS/TESTS/WIP/{NAME}.md` with {Q}/{P} tests passed.
> Resume anytime by invoking `qa-test-run` again.
