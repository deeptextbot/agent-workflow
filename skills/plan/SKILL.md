---
name: plan
description: >
  Phase 1: take one flow from a feature doc and prepare it for coding, in a single ephemeral plan file
  under docs/_wip/ (outside git). Loads the domain and the feature doc's flow, invariants and decisions,
  raises questions, slices the flow into 1-2 cards authored inline, and runs the failure-modes gate.
  Use when the user names a flow to plan (for example "plan F1"), asks to prepare a flow for coding, or
  picks up a flow to implement.
---

# plan: flow → ephemeral plan with cards (Phase 1)

**Goal**: one flow from the feature doc → `docs/_wip/{feature}_{flow}.md` with detailed transitions,
**1-2 inline cards** and failure modes → ready for `code`.

The output is **ephemeral**: `docs/_wip/` is in `.gitignore`. After merge nobody cares about the file.
Everything worth remembering lives in the feature doc (intent, states, invariants, test plan) and in
the code (implementation).

One branch per flow, one merge request.

## SETTINGS

Resolve settings first: invocation arguments (`plan F1 rigor=fast`), then `overrides` in
`.agents/workflow.yaml`, then its active preset. With no file, use the defaults below. State the
resolved values in one line before starting.

| Setting | Default | Used in |
|---|---|---|
| `blind_gates` | `all` | Step 3b, 3c |
| `min_failure_modes` | `2` | Step 3c |

Failure modes are blind only when `blind_gates: all`. With `invariants` or `none`, draft them yourself
against the invariants and have the user edit.

## ALTITUDE RULE

`plan` answers: **"what exactly gets coded in this flow, in which units, and what proves it"**.

- **Intent, states and invariants are already in the feature doc.** `plan` **reads** them, it does not
  invent them.
- The contract is wrong or incomplete (a missing transition, invariant or state) → **fix the feature
  doc in this branch** and continue. Exception: for a **new state or entity**, write the states section
  of the feature doc first, then continue, or the code sprawls under an unrecorded state.
- **The card stays thin**: Behavior · Scope · Verification. **Do NOT map the execution structure**
  (files, methods, data flow). `code` re-derives it. A stale pre-map is worse than none.

## INTERACTION MODE

**Manual at every rigor.** There is no auto mode. Slicing and failure modes are decisions, not
derivations. If asked for auto, decline in one line.

### Pause budget (⏸)

Questions (optional) + slicing (1) + **Verification per card (1-2)** ≈ **2-3 pauses** per flow.

Behavior and Scope are generated **inline with no pause**, because they derive from the slicing row.
All human attention goes to Verification.

## INPUT

- `plan F1`: plans flow F1 from `docs/features/{feature}.md`.
- `plan`: determines the flow from the current branch or context.

### Pre-flight: is the flow ready?

| Check | Ready | Not ready → action |
|---|---|---|
| The flow is described in the feature doc (trigger + result) | yes | missing → run `feature` first |
| The states and invariants section covers this flow | transitions and invariants exist | empty → finish `feature`: Verification has nothing to grow from |
| The test plan has scenarios touching this flow | yes | missing → add them to the feature doc (the human's point, do not generate them when scenarios are blind) |

Not ready → one message saying what to finish. Planning against an unfinished contract is wasted work.

---

## PROCEDURE

### Step 0: Context load

Read **selectively**:

1. **`docs/features/{feature}.md`**: the flow, the states and invariants and test plan section, and the
   decisions block (rejected alternatives, so you do not propose them again).
2. **`docs/domain.md`**: the epic's section: entities, legal states, boundaries.
3. **`docs/domain_glossary.md`**: canonical names to use in cards and test names.
4. **The code**: existing modules this flow touches and patterns to follow.

### Step 1: Questions (optional, ⏸ if any)

Collect the unknowns, classify them and act **right away**:

| Question class | Action |
|---|---|
| touches a state, invariant or decision | fix the feature doc **in this branch**, continue |
| wording is unclear, contract intact | fix the doc, continue |
| local, affects nothing outside the flow | decide on the spot, mention in the plan in one line |

A new **state or entity** → the states section of the feature doc first, then continue.

Show "question → class → what I propose". Wait for triage.

### Step 2: Slice into 1-2 cards (⏸ one pause)

**One rule: 1-2 cards per flow.**

- **3+** → the flow is too big: cut it in two in the feature doc, or you are slicing too fine.
- **Half a card** → merge it with a neighboring flow.

Each card:

- has **one behavioral focus**, stated in its outcome ("System validates…", "User views…");
- has an **observable outcome** that maps directly to a `should_[behavior]` test;
- is independently verifiable, about 2-4 hours of coding, readable in a minute.

**UI is backend-first.** If there are UI steps, the backend contract is the first card and the UI goes
on top in the second. A read flow gets its read-only UI too.

**Self-check before pausing:**

- every transition of this flow from the feature doc is covered by cards;
- nothing atomic is split across cards (one transaction, one card);
- a property (idempotency, validation, atomicity) is **not** its own card, it is tests of its owner;
- "create the table" is a layer, not a behavior → attach it to the card that uses it;
- the feature doc declared UI → there is a UI part.

Show the slicing (1-2 lines per card) and the order. Wait for confirmation.

### Step 3: Per-card authoring (⏸ ONE PAUSE PER CARD)

For **each** card in turn. Never batch.

#### 3a. Behavior and Scope: inline, no pause

- **Domain focus**: only the entities and states directly involved.
- **Changes**: what changes in state or behavior.
- **Observable result**: what can be seen afterward, plus the new capability, 2-3 lines.
- **Scope · Excluded**: what is NOT included. This is the only scope fence `code` relies on, so always
  keep it, even as one line.

Be specific: "System now validates duplicates before saving", **not** "duplicate check added". Do not
copy decision text: `(D#)` links only, in Verification.

#### 3b. Entering Verification: the role switch (when failure modes are blind)

Announce: **"[Card] · Verification: you write first; I stay silent until you name at least
`min_failure_modes`."**

This is the point of maximum concentration. A missed `should_…` is not "fewer tests", it is a hole in
the contract that returns as a bug at the most expensive point.

#### 3c. The Verification gates

An active gate is never softened. Rigor sets gate 1 and the count in gate 2; gates 3-5 hold at every
rigor.

1. **Blind elicitation.** Show **ONLY** the card's identity (name + outcome) **and the quoted invariants
   and transitions from the feature doc**. Do not generate or show any failure mode or `should_…` until
   the user has entered theirs. AI going first is anchoring: the human confirms the list instead of
   thinking.
2. **Count gate (at least `min_failure_modes` per card).** Fewer → **refuse to continue** and ask for
   more. A hard requirement, not advice.
3. **Per-card loop.** Once **per card**. Never collect failure modes for all cards in one batch: batch
   fatigue kills attention.
4. **Invariant seed, not behavior seed.** Point at **the feature doc's invariants**: "imagine the
   sequence after which this invariant breaks". **Not** at the Behavior you just generated, which
   anchors on the happy path.
5. **Gap-check-only output.** After they submit, show **ONLY what is missing** against the invariants,
   labeled **gap-check**. Never show a full replacement list first.

When failure modes are not blind (gate 1 off), present your draft with the invariant it attacks and
have the user edit. Gates 2-4 still apply.

**The feature doc's manual scenarios are input, not a substitute.** They are high-level actor actions;
here they become concrete `should_…` against this card. Mark covered scenarios in the feature doc's
automated-test column.

#### 3d. Verification format (these are **unit tests**, the plan's only test level)

| Test | Invariant / transition | What is checked |
|---|---|---|
| `should_[behavior]` | *"quote from the feature doc's states section" (`D#`)* | a concrete assert |
| `should_reject_[condition]` | *"the invariant being protected"* | what is checked |

- **The middle column is why the test exists.** Without it, a test is code with no context.
- **Behavioral naming**: `should_create_order`, **not** `test_post_endpoint`.
- **Merge rule**: several `should_…` that are facets of **one call** (same setup and action) → one test
  with several asserts. A separate test only for a different input or scenario.

Unit tests are **not** copied to the feature doc; they are already in the test suite.

#### 3e. Reference (optional)

One line, **only if the precedent is not obvious**: name the class or file to follow. If the pattern is
greppable, skip it. **Never** list units, methods, deps or data flow.

#### 3f. Blocker

A dependent task is not merged, or required infrastructure truly does not exist → stamp under the card
title: `> 🚧 BLOCKED by: <what> (<why>).` `code` refuses to run on such a card. Baseline tooling is
**never** a blocker.

---

## OUTPUT: `docs/_wip/{feature}_{flow}.md`

One file. Cards are **inline**.

```markdown
# Plan: {FEATURE} {FLOW} - {name}

> Ephemeral. Source of truth: `docs/features/{feature}.md` (intent, states, invariants) plus code.
> Not needed after merge.

## Transitions of this flow
[extract from the feature doc plus detail too low-level for it: step sequence, order of operations,
 where the transaction boundary sits]

## Action sequence
1. ...
2. ...

## Flow test plan (from the feature doc)
[copied scenarios: what we must prove]

## Cards

### Card 1 - {name}
> 🚧 BLOCKED by: ...   ← only if there is a blocker

**1. Behavior**
- Domain focus: ...
- Changes: ...
- Observable result: ...

**2. Scope**
- Excluded: ...

**3. Verification**

| Test | Invariant / transition | What is checked |
|---|---|---|
| `should_...` | *"..." (`D#`)* | ... |

*(optional) Reference: `ExistingClass`, same pattern*

### Card 2 - {name}
[same format]

## Order
[1-2 lines: where to start and why]

## Wire (draft)
[exact fields, schemas, endpoints if already known; they live here, NOT in the feature doc]
```

## FORBIDDEN in a card

- An execution structure: pre-mapped files, methods, deps or data flow
- A prerequisites checklist (only the blocker stamp exists)
- Boundaries with start and end (derivable)
- A copy of decision text (`D#` links only)

**Reason**: `code` re-derives the structure, and a stale pre-map is worse than none.

## What moves up to the feature doc (same branch, before the merge request)

| Found while planning | Goes to |
|---|---|
| a new or changed invariant, a new state | the feature doc's states section |
| a new "how to break it" scenario | the feature doc's test plan |
| a rejected alternative that would come back | the feature doc's decisions block, if it passes the filter |
| a new entity or canonical name | `docs/domain.md`, `docs/domain_glossary.md` |
| exact fields, wire format, method names | stays in `_wip/`: code level |

## RULES

1. **The feature doc is the source, not a draft.** Read states and invariants; do not invent a parallel
   version.
2. **1-2 cards per flow.** 3+ means the flow is too big.
3. **Failure modes per card, at least `min_failure_modes`, gap-check only**, human first when blind.
4. **The card is thin.** `code` re-derives the execution structure.
5. **The contract is fixed in place**, in the same branch. Exception: a new state or entity goes in the
   feature doc first.
6. **The output is ephemeral.** `docs/_wip/` is outside git and nothing valuable stays there.
7. **Low-noise style**: minimal and sufficient, no filler, bold for domain emphasis.

---
Next: `code` on the plan's first card.
