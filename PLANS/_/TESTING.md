# TESTING

Create human test cases for verifying the functionality of the ________ is 
high quality with robust coverage. Now that we have state diagrams, use those
as required to help me find edge cases, corner cases, and so on.

Since there is no way to automate the testing for a QB64PE program, and DRAW is
so bespoke with the way that it works and it's esoteric keyboard commands, which
make sense to the developer but don't to everyone, and even he forgets them, let's
make sure we cover all of the ways humans will interact with DRAW and the tool.

- Mouse interactions
- Keyboard interactions
- Design considerations
- Tool specific GUI / chrome


## GOAL

A checklist (using `[ ]` and `[x]`) called `________.md` 
stored in PLANS/TESTS like this:

```markdown
# [ ] ________ TESTING

## [ ] CATEGORY OF TEST

### [ ] SUB-CATEGORY NAME OF TEST
What is being tested. How to test. How to setup for the test. 

#### [ ] TEST NAME
1. [ ] STEPs
2. [ ] STEPs
```

## RATIONALE

By creating separate test files in a tests directory we can get more coverage
and a reasonable recipe for success when we think of things in units and groups
and it also helps decrease the cognitive load for the human (me) developer.


## KNOWLEDGE (IN THIS ORDER)

1. Refer to any existing instructions skills and prompts in `.github`
2. Refer to `PLANS/diagrams`
3. Refer to existing documentation and comments in the code itself.
4. Refer to and run any MCP #qb64pe tools necessary


## SKILLS CREATION

### TEST CREATION SKILL

Create a skill called `qa-test` which I can use for this in the future, which will
create a new copy of the checklist that is blank ready to be filled in/actioned
once the LLM has created the tests, and the human can run them.

0. The skill should take as input the name of what is being tested and replaces the _______ placeholder.
1. Create the template file named TESTS/_______.md 
2. Use the contents of the markdown above
3. Using this format, create the categories, sub-categories and tests.
4. When the file is ready the LLM says ready for tests. 
5. The human will take the TESTS/_______.md file and create future chats one by one to go through the tests and results.

### TEST WORK / COMPLETION SKILL

0. This skill should move the file stored in TESTS into PLANS/TESTS/WIP (work in progress)
1. The human should be prompted "ready to start"
2. One by one, the human will create new context windows and chats to run the tests
3. Testing will involve fixing or confirming everything works as intended, no defects
4. When human says "works" or "fixed" or "passed" in one response, that means the test has passed, the bug is fixed, or the feature now works.
5. You should mark the test as done with `[x]` 
  - and hierarchically analyze if the sub-category is also done and if so `[x]` that
  - and check it's own category again to see if the entire category is done and if so `[x]` that
  - and at this time when a category is completed, check the entire file for more tests.
  - if everything is done, make the entire checklist as `[x]` at the top, and tell the user.
6. If there are more tests, the human will continue going through them in separate chat sessions.
7. If there are no more tests and the entire test file is complete, move the file to PLANS/TESTS/RESULTS