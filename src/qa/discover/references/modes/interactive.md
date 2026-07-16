# Mode 3: Interactive Discovery

Load when `/qa:discover <area-name>`.

## Mode 3: Interactive Discovery (`<area-name>`)

Guide the user through creating NL test specs for a specific functional area.

### Step 1: Load Context

Check if `specs/_sitemap.md` exists:
- If yes, read it and find the section for `<area-name>`. Use the discovered pages and elements as context.
- If no, proceed without pre-existing context.

Check if any specs already exist for this area by looking for files matching `specs/<area-name>-*.md`.

If specs exist, mention them so the user can decide whether to add or replace.

### Step 2: Gather Information

Use `AskUserQuestion` for each prompt. Ask one question at a time and wait for the answer before proceeding.

**Question 1: Main User Flows**
> "What are the main things a user does in the [area-name] area? Describe the key user flows or actions."

**Question 2: Critical Happy Path**
> "Which of these flows is the most critical — the one that absolutely must work? What does the ideal path look like step by step?"

**Question 3: Error Cases**
> "What are the common error cases? What happens when users provide bad input or do something wrong?"

**Question 4: Edge Cases**
> "Are there any edge cases or tricky scenarios you're worried about? (e.g., race conditions, unusual data, permissions issues)"

**Question 5: Persona**
> "Which persona does this flow primarily serve? (new-user = someone setting up for the first time, power-user = someone using advanced features daily, returning-user = someone resuming work)"

**Question 6: Test Data**
> "What test data is needed? (e.g., test accounts, specific values, environment setup)"

### Step 3: Generate NL Spec

From the user's answers, create a structured NL spec file:

1. Derive spec `id` and feature name from the area and user's description
2. Set `area`, `priority`, `persona`, `tags`, and `seed` in the YAML frontmatter
3. Write an Overview from the user's flow descriptions
4. Build Preconditions from test data and setup requirements
5. Create numbered H3 scenario sections with step-by-step actions and **Expected:** lines
6. Populate the Test Data table
7. Add Notes if the user mentioned known issues or constraints

Follow the template from @qa `templates/spec-template.md` exactly.

### Step 4: Write Spec File

Write to `specs/<area-name>-<feature>.md`.

### Step 5: Present for Review

Show the complete generated spec to the user. Use `AskUserQuestion`:

> "Here is the generated spec. Would you like to make any changes, or does this look good?"

If changes are requested, edit the file accordingly.

### Step 6: Planner Handoff

```
Spec saved: specs/<area-name>-<feature>.md

Next steps:
1. Discover another feature in this area
2. Discover a different area
3. Generate tests from this spec using Playwright Planner/Generator
4. Done for now
```

Use `AskUserQuestion` to let the user choose.

---

