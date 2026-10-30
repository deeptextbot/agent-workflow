# Protocol: how we build

One developer plus an agent. Production is far away and the vision forms along the way, so this
protocol optimizes for **speed of changing a decision**, not for protecting a team from mistakes.

The skills carry every rule they need. This document explains why the process has this shape.

**Few permanent artifacts.** The more documents exist, the higher the tax on every change: cascading
syncs, rot, and an agent pulled to the wrong altitude, reading implementation details where it should
read intent.

| Level | Source of truth | Lifetime |
|---|---|---|
| **What and why** (intent, boundaries, contract) | `docs/features/{feature}.md` | permanent |
| **Entities and names** | `docs/domain.md`, `docs/domain_glossary.md` | permanent |
| **How** (implementation, exact fields, wire format) | **code and tests** | permanent |
| Work plan (slicing, cards, wire drafts) | `docs/_wip/*.md` | until merge, then forgotten |

Code is not a secondary source. It is more precise than any document and does not rot. Documents stay
only where code is silent: intent, rejected alternatives, the behavioral contract.

## Pipeline

```
idea → feature ──→ plan F# ──→ code ──→ review → merge
       (flows,     (ephemeral   (1-2 cards
        invariants, plan with    from the
        scenarios)  cards)       plan)
```

One branch per flow, one merge request per branch.

## Slicing is mechanical

- A **feature** is a finished logical block of functionality. It can ship and makes sense on its own.
- A **flow** is sized to yield **1-2 cards**. Four cards means the flow is too big: cut it in two. Half
  a card means it belongs with its neighbor.

## Where the human thinks first

Where the agent physically cannot know the answer, the human generates first, before the agent offers
anything. Otherwise anchoring takes over: the human confirms the agent's list instead of thinking, and
the point of thinking dies while formally still existing.

1. **Domain: entities, states, boundaries.** The agent does not know which entities are real or where
   the product ends. This is the most expensive mistake, since everything downstream inherits it.
2. **Invariants.** They require imagining the sequence after which correctness breaks. The agent sees
   the happy path and does not attack its own model. An unnamed invariant is a class of bugs no test
   will catch, because tests derive from what was named.
3. **Manual scenarios.** The same invariants turned into actions.
4. **Contract drift**, after the diff. The agent just wrote this code, so it is no judge of its own
   drift from intent.

The agent is free, with the human sanity-checking, on slicing, cards, stubs, tests and refactors. A
miss there is caught cheaply further down the pipeline or in review.

## Rigor is a dial

Prototypes and production code deserve different effort, so ceremony is set in
`.agents/workflow.yaml` as `fast`, `standard` or `strict`, with per-run overrides. See the README for
the table.

The dial changes how much is written, how many gates are blind and how often the agent stops. These
do not move with it:

- The domain is agreed before flows.
- Every feature has a feature doc with invariants and scenarios.
- Code ships with tests and a green check command.
- A wrong contract is fixed in place.

Raising rigor later is cheap: re-run `feature` on the existing doc and it asks only for the gap.

## Feature doc

The permanent artifact. Sections: business value, actors, domain and read/write set, flows, states and
invariants and test plan, boundaries, UI screens, decisions.

Rejected alternatives live in the decisions block of the feature they belong to. A decision is written
down **only if all three hold**:

1. Without it, the agent or you a month later will propose an already rejected alternative again.
2. It cannot be seen from the code in 30 seconds.
3. It concerns the feature or system level, not one module.

A changed decision **rewrites its row**. History is in git.

## Exactly two kinds of tests

| Kind | Declared in | Lifetime | Author |
|---|---|---|---|
| **Manual scenarios** | feature doc | **permanent**, part of the contract | human (blind gate) |
| **Unit tests** | card in the plan | **ephemeral**, then just code | human names failure modes, agent gap-checks |

Scenarios are coded into automated tests during `code`. A scenario that has not become a test stays
marked `⏳`, which keeps the debt visible in the contract itself.

## Ephemeral plan

One file per flow: `docs/_wip/{feature}_{flow}.md`, outside git. It holds everything needed to code
and nothing worth remembering afterward: detailed transitions, an action sequence, 1-2 inline cards,
and the flow's scenarios.

New invariants, states, scenarios or boundary changes found while planning move up to the feature doc
in the same branch. Implementation details do not: they are already in the code.

## When the contract turns out wrong

> Fix the artifact at the altitude of the lie, in the same branch, and keep going.

| Finding about | Fix | Then |
|---|---|---|
| a decision (a rejected alternative came back) | decisions block of the feature doc | continue |
| a state, invariant or scenario | states section of the feature doc | continue |
| a field, method or wire format | the plan in `_wip/`, or the code directly | continue |
| *how* inside a unit | the code | continue |

The litmus test is "what or how?": *what* goes in the feature doc, *how* stays in the code.

The one case worth stopping for is a **domain** change mid-coding, a new entity or state. Write it
down first, then code, or the code sprawls under an unrecorded state.
