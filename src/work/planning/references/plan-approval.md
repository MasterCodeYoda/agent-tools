# Plan approval gate

**Load when:** `/work:plan` reaches the approval gate (after draft + leverage check +
optional visual plan).

## Hard refuse

When planning is complete, **stop** and present the plan for approval. Do not begin
execution, save planning documents, or update PM tools until the user explicitly approves.
No exceptions.

## Approval meaning

Approve = **proceed with this plan as the current working hypothesis**. It does **not** freeze
requirements or design forever. Mid-execute learning (code pushback, wrong framing, design
falsified, human steer) may re-enter refine/plan under the unit state machine — expected
process, not a failed plan.

## Present plan for approval

Show the plan summary using the Plan Approval Prompt from @work (`planning/templates.md`).
It summarizes project, source, approach, slices with task counts, required vs out-of-scope
task counts, and key technical decisions; states where the plan will be saved; includes the
**Visual plan** link or skip line when the visual-approval step ran; and offers exactly three
options: **1. Approve & Save**, **2. Approve & Execute**, **3. Revise**.

The three options always approve or revise the **markdown implementation plan**. The visual
surface is optional context — not a fourth option and not execute input.

**STOP and wait** for the user's response. Until then:

- Do NOT save planning documents to disk until approved  
- Do NOT update PM tools until approved  
- Do NOT begin execution until explicitly requested  
- Do NOT treat “looks good” / “LGTM” as execute — ask which option they want  

## On revise

1. Apply feedback to the **draft markdown implementation plan** first.  
2. If a visual surface exists, rewrite `visual-plan.html` to match and print a fresh `file://`
   link (do not auto-launch).  
3. Re-run the Plan Approval Prompt (still no markdown plan / session-state disk write until
   Approve; HTML may be rewritten).

## On approval: save plan

### Step 1 — Enter worktree (if `WORKTREE_MODE=true`)

1. Derive worktree name from the project name  
2. Capture `REPO_ROOT` before enter  
3. Create via @git worktree-create  
4. Rename branch per @work `references/family-contracts.md`  
5. Establish dependencies via @work dependency-establishment  
6. Set `WORKTREE_PATH` for session-state  

### Step 2 — Working branch (if not worktree)

If on `main`/`master`, create/switch to `<type>/<identifier>` per family-contracts.

### Step 3 — Save documents

1. `implementation-plan.md` — only executable plan SoT  
2. `session-state.md` — include `worktree:` / `visual_plan:` when applicable  
3. Ensure `codebase-research.md` present or skip reason  
4. Ensure `design-discussion.md` for feature/hard or skip reason  
5. Ensure `visual-plan.html` current when published  

### Step 4 — Commit planning docs (worktree mode)

```bash
git add ./planning/[project]/
git commit -m "docs: add planning for [project]"
```

### Step 5 — PM tool update

See plan skill §PM Tool Integration / `planning/pm-integration.md`.

### Step 6 — Confirmation

Confirm paths, branch, worktree, visual path/skip, PM update.

### Step 7 — Parallel execution prompt

When 2+ independent slices: prompts from @work (`planning/templates.md`) › Parallel
Execution Prompts.

**Approve & Save** — stop; remind user how to run execute (with/without worktree).  
**Approve & Execute** — handoff to `/work:execute ./planning/[project]/`.
