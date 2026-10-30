---
name: feature
description: >
  Phase 0: define one feature as a contract: business value, actors, domain, flows, state
  transitions, invariants, manual test scenarios, boundaries and decisions. Interviews the user one
  decision at a time and agrees the domain first. Use when the user wants to plan, discuss, challenge
  or validate a new feature or epic, or to raise the rigor of an existing feature doc.
---

# feature: the feature as a contract (Phase 0)

**Goal**: raw idea → (epic split) → one feature with value, flows, **states, invariants and a test
plan**.

The feature doc is the **permanent high-level source of truth**. It outlives plans, cards and
refactors. It holds what the code does not: intent, boundaries, named invariants, "how to break it"
scenarios and rejected alternatives.

**A feature is a finished logical block of functionality**: it can ship and makes sense on its own.
Each flow is sized to yield **1-2 cards** in `plan`.

## SETTINGS

Resolve settings first: invocation arguments (`feature rigor=fast top_scenarios=4`), then `overrides`
in `.agents/workflow.yaml`, then its active preset. With no file, use the defaults below. State the
resolved values in one line before starting.

| Setting | Default | Used in |
|---|---|---|
| `domain_detail` | `full` | Step 2 |
| `blind_gates` | `all` | Step 4b, 4c |
| `top_scenarios` | `5` | Step 4c |
| `extra_scenarios` | `10` | Step 4c |

The value of `blind_gates` is one of `all`, `invariants`, `none`:

- **Blind** step: the human writes first and the agent says nothing until they have, then gap-checks.
- **Non-blind** step: the agent drafts and the human edits.
- `all` makes 4b and 4c blind. `invariants` makes only 4b blind. `none` makes neither blind.

**An existing doc at higher rigor**: when the feature doc already exists and the settings ask for more
than it has, ask only for the gap (the missing scenarios, the blind pass that was skipped), then
update its `Rigor` line.

## INTERACTION MODE

**Manual and user-led at every rigor.** There is no auto mode. If asked for one, decline in one line:
the interview is the work, because decisions about the problem domain are made, not derived from text.

- Do not generate the final doc right away.
- Ask questions **one at a time**, wait for the answer, then pick the next dependency.
- Give **your recommendation and why** with each question, as a practical default.
- If the code or docs can answer a question, **go look instead of asking**.
- Do not write code and do not cut cards.

Question format:

```markdown
Question: [one concrete decision or ambiguity]
Recommended: [practical default]
Why: [short reason]
```

### Decision tree discipline

- An answer changes scope → update IN/OUT **before** the next question.
- An answer creates a prerequisite → record it immediately.
- An answer reveals a separate feature → OUT OF SCOPE plus a stub, unless the user expands the epic.
- A vague answer → one sharper follow-up. Do not accept ambiguity.
- A branch with no product impact → close it and move on.

---

## PROCEDURE

### Step 0: Scope altitude and epic split ⏸

Before any brainstorming, sketch the rough flows:

- **≤4 flows** → one feature, continue.
- **>4 flows, or ≥2 actors with separate journeys, or an explicit value chain with stages** → an epic,
  cut it.

**Seams for the cut**, in priority order:

1. **Domain**: separate entity clusters or ownership planes.
2. **Value-chain stage**: the output of one is the input of the next (ingest → transform → publish).
   Cut at the artifact handoff.
3. **Actor journey**: system pipeline vs operator CRUD vs admin.
4. **Failure isolation**: a fallback path big enough to have its own flows.

Show the candidate list **without detail**. The user picks **one** for full planning. The rest become
stubs in OUT OF SCOPE of the feature doc written in this run. A stub is not a plan: no domain, no
decisions, no flows.

If the idea really is one feature, say so in one line and continue. Do not invent cuts for show.

### Step 1: Value and actors (interactive)

Draw out through conversation: the **value** (what problem this solves), the **actors**, the **vision
of the result**, **business edge cases**, **prerequisites and gaps**. Ask questions that attack weak
assumptions: "what if the upstream source is two days late?", "who owns the final correction when
automation conflicts with a manual edit?"

### Step 2: Domain gate ⏸ (the most expensive point)

**Structure first: flows derive from the domain, so the domain is agreed FIRST, at every rigor.**

Show **only** the draft domain model and nothing else, then wait for explicit confirmation:

- `domain_detail: brief`: entities and legal states.
- `domain_detail: full`: entities, legal states, ownership boundaries and an ER diagram.

A mistake here costs the most: every flow, card and test inherits this structure. The agent does not
know which entities are real or where the product ends, so **the human decides this**.

The agreed domain goes to `docs/domain.md`, under the epic's section, **not** in the feature doc.

**Canonical names.** Give each entity its full name (`OrderLineItem`) and use it consistently
everywhere. A bare alias ("item", "line") is forbidden unless glossed at first mention, because
downstream skills inherit these names. **Maintain `docs/domain_glossary.md`**: a new entity gets a
row; a deliberate non-entity (computed, transient) goes under "Non-entities".

### Step 3: Flow extraction ⏸

Split the feature into **behavioral flows**: end-to-end scenarios with a trigger and an observable
result.

Good: "User manually uploads a missing file", "System fetches sources on a schedule", "Handling
invalid input".
Bad: "Create the tables", "Add the API endpoints".

**Flow size is mechanical**: each flow must yield **1-2 cards** in `plan`. Estimating 4+ → cut the flow
in two. Estimating half a card → merge it with a neighbor.

Wait for confirmation of the flow list.

### Step 4: States and invariants ⏸

The core of the doc, in three parts.

#### 4a. Transition table: together

`object · transition · guard/invariant · owning flow`. Built from the domain: every legal transition
has **exactly one** owning flow. A transition with no owner is a hole in the feature. A flow with no
transition and no read model is noise (mark **read-flow** explicitly).

The flow column is the coverage check. No separate matrix is needed.

#### 4b. Cross-cutting invariants: blind unless `blind_gates: none`

Announce: **"Invariants: you write first; I stay silent until you name yours."**

**Gate**: show no invariant until the user has entered their own. An invariant requires imagining the
sequence after which correctness breaks. The agent sees the happy path and does not attack its own
model. An unnamed invariant is a class of bugs **no test will catch**, because tests derive from what
was named.

After they submit, **gap-check only**: show only what is missing, labeled as a gap-check. Typical
gap-check categories: atomicity (what must share a transaction), idempotency (a repeated call),
concurrency (two actors or ticks), ordering (what must strictly follow what), ownership (who alone
writes this field).

#### 4c. Test plan, manual scenarios: blind when `blind_gates: all`

Announce: **"Scenarios: you write first; I stay silent until you name yours."**

Same gate. **A scenario is an invariant turned into an action**, so write these right after the
invariants, while they are still in mind. When this step is not blind, draft them yourself and have
the user edit.

**Two tiers, both manual, both part of the contract:**

**Tier 1: top scenarios (high-ROI), step by step.** The `top_scenarios` scenarios whose failure costs
the most, each broken into actor or system steps with an expected result:

```markdown
| # | Actions (actor / system) | Expected | Automated test |
|---|---|---|---|
| 1 | 1. Order is `paid`, `attempts=3`<br>2. User edits the address and saves<br>3. System regenerates the invoice | `shipping_address` overwritten; `status` and `attempts` **untouched**, in the same transaction | `tests/...` or ⏳ |
```

Tier 1 is for data loss, silent state overwrites, atomicity violations, races between two actors and
holes in guards. Field validation and the happy path are **not**: they go to tier 2 or to unit tests.

**Tier 2: extra manual scenarios, compact.** One line each, no steps, still action → expected, up to
`extra_scenarios`:

```markdown
| # | Scenario (action) | Expected | Automated test |
|---|---|---|---|
| 6 | Re-run on an item whose parent is finished | works (an explicit user action is not gated by status) | ⏳ |
```

This is not "coverage". It is what is worth exercising by hand; the rest is proven by unit tests. Use
fewer than the limit when fewer are worth it.

**Unit tests are NOT declared here.** They live in the card at `plan` and then as code.

**Count gate: tier 1 is exactly `top_scenarios`.** Fewer → refuse to continue and ask for more. More →
that is blurred selection, not extra importance: the surplus moves to tier 2.

### Step 5: Boundaries and decisions

IN / OUT / assumptions / prerequisites. Open gaps must close before `plan`.

**The decisions block is not an interview log.** A decision goes in **only if all three hold**:

1. Without it, the agent or you a month later will propose an **already rejected** alternative again.
2. It cannot be seen from the code in 30 seconds.
3. It concerns the feature or system level, not one module.

Otherwise it is not written. A constant, a module name, an env variable, a library choice or a field
schema is code-level.

A changed decision **rewrites the same row**. History is in git. IDs (`D1`, `D2`) are stable, gaps
after removal are fine.

---

## OUTPUT

| What | Where |
|---|---|
| Domain model | `docs/domain.md` → `## [Epic]` |
| Canonical names | `docs/domain_glossary.md` |
| Everything else, decisions included | `docs/features/{feature}.md` |

The domain is **not** copied into the feature doc, only linked.

### `docs/features/{feature}.md`

```markdown
# Feature: [Name]

> Rigor: [fast | standard | strict]

## 1. Business Value (Why)
[problem + value, 3-5 lines]

## 2. Actors
- **[Actor]**: [role/goal]

## 3. Domain *(links, not a copy)*
- **Domain model** → `docs/domain.md` → `## [Epic]`
- **Read/write set**: [what this feature reads and mutates]

## 4. Behavioral Flows
### F1: [name]
- **Trigger**: [what starts it]
- **Outcome**: [result, 2-3 lines; decisions as `(D#)` only]

## 5. States, Invariants and Test Plan

### State transitions
| Object | Transition | Guard / invariant | Flow |
|---|---|---|---|

### Cross-cutting invariants
- **[name]**: [what it holds and what breaks without it]

### Test plan: top scenarios
| # | Actions (actor / system) | Expected | Automated test |
|---|---|---|---|
| 1 | 1. ...<br>2. ... | ... | `tests/...` or ⏳ |

### Test plan: extra manual scenarios
| # | Scenario (action) | Expected | Automated test |
|---|---|---|---|

## 6. Boundaries and Prerequisites
- **IN SCOPE** / **OUT OF SCOPE** / **Assumptions** / **Prerequisites**

## 7. UI Screens
[which screen, what the actor sees and presses; no layout or components]

## 8. Decisions
| ID | Decision | Rejected alternative | Why |
|---|---|---|---|
```

### `docs/domain_glossary.md`

```markdown
# Domain glossary

| Name | Meaning | Epic |
|---|---|---|

## Non-entities
| Name | What it is instead (computed, transient) |
|---|---|
```

### Stubs (from an epic split)

A stub lives in the feature doc of **its epic**, under Boundaries → **OUT OF SCOPE**, as its own block.
There is no central list of stubs. Pick the first home that applies:

1. **The epic already has a feature doc** → put the stub there.
2. **No doc yet, but this run creates one** → put the stub in **this** doc. The epic's anchor doc hosts
   its siblings' stubs.
3. **No doc and none coming** (the user planned nothing) → **create nothing**. Name the stub in your
   output and say plainly it was **not saved**. `feature` can raise it from scratch when needed, which
   is cheaper than an orphan list nobody reads.

```markdown
### {feature_name} *(stub)*
- **Value**: [one line]
- **Parent epic**: [name] · **seam**: [domain|value-chain|actor|failure]
- **Rough flows**: [N] - [names without detail]
- **Depends on**: [-]
- **Status**: not planned; `feature` expands it into its own doc
```

---

## RULES

1. **Act as a PM**: WHAT and WHY, not HOW.
2. **Size before depth**: a feature is about 2-4 flows, each flow 1-2 cards. More than 4 flows is an
   epic: stubs plus one detailed feature.
3. **Domain gate first** (Step 2): flows derive from the domain, not the reverse.
4. **Human first where `blind_gates` says so** (Steps 4b, 4c): blind, gap-check only. Rigor can turn a
   gate off, but an active gate is never softened.
5. **Decisions have a filter, not a log** (Step 5): the three conditions; a change rewrites the row.
6. **Exactly two kinds of tests**: manual scenarios here (permanent, contract) and unit tests at `plan`
   (ephemeral, then code).
7. **Flows are scenarios** with a trigger and an observable result.
8. **Low-noise style**: minimal and sufficient, no filler, bold for domain emphasis.

---
Next: `plan F1`, the first flow into an ephemeral plan with cards.
