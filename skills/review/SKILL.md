---
name: review
description: >
  Reviews the current branch's diff against the feature doc and reports findings ranked by severity,
  with file and line references. Works locally on git with no hosting platform. Reports only and
  changes no code unless asked. Use when the user asks for a code review, to review a branch or diff,
  or as the step before merging.
---

# review: branch review against the contract

**Goal**: current branch diff → findings against the feature doc → a triaged list for the human.

## SETTINGS

Resolve settings first: invocation arguments (`review rigor=fast`), then `overrides` in
`.agents/workflow.yaml`, then its active preset. With no file, use the defaults below. State the
resolved values in one line before starting.

| Setting | Default | Used in |
|---|---|---|
| `review_nits` | `3` | Step 3 |
| `rereview` | `full` | Step 5 |
| `project.base_branch` | remote's default branch | Step 1 |

## INPUT

- `review`: the current branch against the base branch, plus uncommitted changes
- `review <ref>`: the current branch against `<ref>`
- `review <path>`: limit the diff to a path

## PROCEDURE

### Step 1: Get the diff

```bash
git diff <base>...HEAD
git diff HEAD
```

The second command covers uncommitted work. Skip binary files, lock files and generated or minified
files. An empty diff → stop and say so.

### Step 2: Load the contract

**The source of truth is the diff plus the feature doc.** Plans are ephemeral, so the contract to review
against is `docs/features/{feature}.md`: its state transitions, invariants, test plan and decisions.
Find it from the branch name or the changed behavior. Read the surrounding code wherever the diff alone
does not show the effect.

No feature doc → review the diff on its own and say in the report that the contract was not checked.

### Step 3: Analyze the diff

Comment only on changed lines. Write one entry per finding, in severity order:

| Severity | Means |
|---|---|
| `bug` | broken logic, a missing guard, a wrong state, a security issue |
| `risk` | works but is fragile: an unhandled exception, a race, a swallowed error |
| `nit` | naming, dead code, style. At most `review_nits`. |
| `q` | a genuine ambiguity where the intent is unclear |

**Also a finding, at any rigor:**

- The diff changes behavior the feature doc does not describe → `q`.
- The diff adds behavior the test plan does not cover → `risk`.
- A test-plan row is still `⏳` although this branch should close it → `risk`.

### Step 4: Report

```
Review: <branch> against <base>. N findings: X bug, Y risk, Z nit, W q.

bug   <file>:<line>  <problem in one line>. <concrete fix>.
risk  <file>:<line>  <problem>. <fix>.
nit   <file>:<line>  <problem>. <fix>.
q     <file>:<line>  <what is unclear>.
```

Use several lines only for security or architectural findings: a short title, 2-3 sentences of root
cause and impact, then the fix. With zero findings, say so plainly and name what was checked.

Stop here. Do not edit code unless the user asks.

### Step 5: After fixes

Re-review on request. With `rereview: full`, re-read the **whole diff**, not only the fix commits,
because one fix can break a neighbor. With `rereview: fixes`, re-read what the fixes touched. Rounds end
on zero new findings.

## TRIAGE RULES

- **The human filters validity first.** Agent review is probabilistic and has false positives. The
  triager judges *correctness* before severity, and discards invalid findings. An agent `bug` is not a
  verdict. Two or more false positives of one kind mean this skill is miscalibrated: fix the skill.
- **You are one reviewer slot, not the whole review.** A human and an agent can review the same diff
  independently, and findings merge into one queue with no anchoring.
- **A finding that pulls a decision is fixed at that altitude, in this branch.** When a finding is about
  *what* rather than *how* (new behavior, a changed contract, a missing invariant), the fix updates the
  feature doc in the same branch. A silent inline patch leaves the doc lying.
- **Two or more repeats become a gate.** A finding seen twice on different cards is not a review item.
  Turn it into something mechanical (a lint rule, a test, a skill step) so review stops catching it by
  eye.
