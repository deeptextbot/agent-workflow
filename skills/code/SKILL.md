---
name: code
description: >
  Phase 2: execute the coding workflow for one card from an ephemeral plan: context reload, test stubs,
  execution plan, incremental generation, final diff review, and closing the feature doc's test-plan
  rows. Use when the user asks to code a card, start coding, or is ready to implement a planned flow.
---

# code: coding phase (Phase 2)

**Goal**: card + tests + verification → working, verified behavior.

You are an implementation engineer. Take a card, inline in the ephemeral plan
`docs/_wip/{feature}_{flow}.md`, and execute the workflow step by step. No shortcuts.

## SETTINGS

Resolve settings first: invocation arguments (`code "Card 2" code_pauses=diff`), then `overrides` in
`.agents/workflow.yaml`, then its active preset. With no file, use the defaults below. State the
resolved values in one line before starting.

| Setting | Default | Used in |
|---|---|---|
| `code_pauses` | `stubs_and_diff` | Interaction mode |
| `project.check_command` | discover it | Step 4, 5 |
| `project.base_branch` | remote's default branch | Step 1 |

**The check command** is the project's full gate: format, lint, types and tests, whichever exist. If it
is not configured, find it in the project's agent instructions, README, build file or CI config. If
you find none, ask once and suggest saving it to `.agents/workflow.yaml`.

**The quick check** is the type check, if the project has one, plus the tests relevant to the changed
files.

## INTERACTION MODE

The `code_pauses` setting decides where you stop:

| Value | Stops |
|---|---|
| `diff` | ⏸ Step 5 only. Show the stubs FYI and continue. |
| `stubs_and_diff` | ⏸ after Steps 1+2 (context and stubs) and ⏸ at Step 5. |
| `every_step` | ⏸ after each of Steps 1, 2, 3 and after EVERY code chunk in Step 4, and at Step 5. |

Between stops you work autonomously, but internally incrementally: never accumulate unverified code.
Step 6 follows Step 5 with no extra pause. At Step 5, show the check result first, then **one diff
review**. A diff over about 400 lines is split into logical sections, still as a single review.

**You MUST propose `every_step` yourself, at any rigor,** when the card touches any of:

- database migrations
- auth or sessions
- data deletion
- transactional logic
- a cross-cutting refactor

## INPUT

- `code`: the next open card from the plan `docs/_wip/{feature}_{flow}.md`
- `code "Card 2"`: a specific card from that plan

No plan → ask for `plan F#` first.

## PROCEDURE

### Step 1: Context reload

Before writing any code:

1. **Re-read the card** in the plan: Behavior · Scope · Verification, plus any Reference.
2. **Restate the behavior** in your own words: what changes.
3. **Restate the scope**: what is OUT (Scope → Excluded); IN is the Behavior.
4. **Read the relevant decisions**: for each `(D#)` in Verification, open the row in the feature doc's
   decisions block.
5. **Read the feature's invariants**: the "States, Invariants and Test Plan" section. Tests are written
   against them.
6. **Restate the verification**: test names from the card, plus the feature's test-plan rows this card
   closes.

**Output a brief summary:**

```
Context: [Card - Name]
  Behavior: [what changes]
  Scope: [what is excluded]
  Decisions: [binding constraints from Verification, or none]
  Verification: [N success + M failure scenarios]
  Test plan rows: [the ⏳ rows this card closes]
  Ready: [yes / 🚧 BLOCKED]
```

A card marked 🚧 **BLOCKED** → STOP. Report the blocker and do not code until it is cleared.

**Branch**: one branch per flow, one merge request. `git switch -c feat/<feature>-<flow>` from the base
branch, unless you are already on it.

### Step 2: Test thinking first

Create behavioral test names BEFORE any implementation:

1. **Take test names from the card** (Verification).
2. **Refine if needed**, based on codebase patterns.
3. **Write test stubs**: signatures with a one-line description, no implementation yet.

```
test should_create_order_with_valid_data
  When valid customer and items are provided, the order is created and returned.

test should_reject_duplicate_order_reference
  When an order with the same reference exists, a duplicate error is raised.
```

**Rules:**

- Names describe behavior: `should_[behavior]`, adapted to the project's test naming.
- Match the project's existing test patterns (fixtures, helpers, test client).
- Think about success scenarios, failure scenarios, edge cases and missing scenarios.

**Checkpoint** (`stubs_and_diff`, `every_step`): present the Step 1 summary and the stubs together. STOP
and wait for approval. The human validates the understanding of the task and the behavioral contract
before implementation starts.

### Step 3: Build the execution plan

Plan the generation steps: small, logical, incremental.

```
Execution plan:
  1. [what] - [files touched] - [~size]
  2. [what] - [files touched] - [~size]
  3. Tests - [test files] - [~size]
```

**Rules:**

- Each step builds on the previous one and is one reviewable, revertible change, about 50-150 lines.
- Each step is small enough to verify quickly and easy to regenerate if rejected.
- Do not generate all the code at once.

Show the plan FYI as you start generating. With `every_step`, present it and ⏸ wait for approval.

### Step 4: Incremental code generation

The source of truth is the card's Verification plus the feature doc's invariants.

**There are exactly two kinds of tests**: behavior scenarios (the feature doc's test plan) and unit
tests (the card's Verification). The feature doc's test-plan rows this card covers are coded **here**,
as ordinary tests.

```
For each step in the execution plan:
  1. Generate the code for this step
  2. Run the quick check on the changed files
  3. Fix failures immediately
  4. Continue to the next step
```

With `every_step`, also present each chunk and ⏸ wait for confirmation.

**After EVERY step, ask yourself:**

- Behavior correct? Does it match the card's Behavior?
- Scope still correct? Within the card's Excluded?
- Edge cases covered? From the card's Verification?
- Tests meaningful? Not just testing implementation details?
- Overengineering? Building more than the card requires?

**If any answer is no → stop, report, adjust.**

**When the contract turns out wrong**, fix the artifact at the altitude of the lie, **in this branch**,
and keep going:

| Finding about | Fix | Then |
|---|---|---|
| a decision (a rejected alternative came back) | the feature doc's decisions block | continue |
| a state, invariant or test-plan scenario | the feature doc's states section | continue |
| a field, method or wire format | the card in `_wip/`, or the code directly | continue |
| *how* inside a unit | the code | continue |

No "for now" workarounds in the code.

**The exception worth stopping for**: a **domain** change (a new entity or state). Write it into the
feature doc's states section, `docs/domain.md` and `docs/domain_glossary.md` first, then code.

**The card is mis-sized** → re-cut it in the `_wip/` plan, agree the new boundaries with the user,
resume from Step 1. No "I'll finish the rest in the next card".

**Code generation rules:**

- Use the strictest typing the language and project support.
- Follow existing project patterns: naming, structure, imports, style.
- Do not introduce new patterns unless discussed.
- Do not add features not in the card.
- Prefer simple over clever.

### Step 5: Final review

**⏸ One diff review.** Run the check command first. Only when it is green, present the full diff against
the checklist:

| Check | How | Status |
|---|---|---|
| Format, lint, types, tests, coverage (whichever the project has) | machine | ☐ |
| Behavior correct (card Behavior) | human | ☐ |
| Scope respected (card Excluded) | human | ☐ |
| Edge cases covered (card Verification) | human | ☐ |
| Code understandable | human | ☐ |

If the machine checks fail, fix them before requesting human review. This is a self-review: the author
against their own card.

**Contract drift is the point of attention.** The agent just wrote this code, so it is no judge of its
own drift from intent, which is why the human reads. Drift in *how* (private implementation) is normal.
Drift in *what* (new behavior, a changed contract) → fix the feature doc **in this branch**. A silent
patch of *what* creates two sources of truth.

### Step 6: Close the test-plan rows (no pause)

Open the feature doc's "States, Invariants and Test Plan" section and **go through the rows this card
closes**: `⏳` → the test file path, in the same commit as the code.

The test plan is a contract, not a wish. A row left `⏳` after the card that should cover it is merged
is **visible debt**. A row quietly left `⏳` when the test exists makes the contract lie.

A scenario turned out **wrong** (it described behavior that must not exist) → fix the row, do not
silently drop it.

**Output:**

```
[Card] complete
  Behavior: [confirmed working]
  Tests: [X passed, 0 failed]
  Check command: [passed]
  Test plan: [rows #N, #M → paths; still ⏳: #K]
  Files changed: [list]
  Boundaries: [respected / any concerns]

Next: [next card of the plan] | `review`
```

## CORE PRINCIPLES

| Principle | Not |
|---|---|
| Behavior first | layers |
| Verification first | blind coding |
| Small slices | giant tasks |
| Incremental verification | massive generation |
| AI assists thinking | AI replaces thinking |

Small verified behavioral slices beat giant intelligent architectures.

## RULES

1. **The card is law**: do not add features not in the card.
2. **Stop where `code_pauses` says**; between stops, autonomous but internally incremental.
3. **Propose `every_step`** for migrations, auth or sessions, data deletion, transactional logic and
   cross-cutting refactors.
4. **Match patterns**: follow the project's existing conventions exactly.
5. **Tests first**: write test stubs before the implementation.
6. **Refuse blocked cards**: 🚧 BLOCKED → STOP, report, do not code until cleared.
7. **No scope creep**: a needed change outside Scope → note it, do not implement it.
8. **Verify every chunk**: the quick check after each increment. Never accumulate unverified code.
9. **The contract is fixed in place**: drift in *what* → the feature doc in this branch; a new state or
   entity → the doc first, then the code.
10. **Close the test plan** (Step 6): `⏳` → test path, in the same commit.
