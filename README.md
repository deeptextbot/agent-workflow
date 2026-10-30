# agent-workflow

A minimal spec-first workflow for building software with a coding agent. Four skills, plain Markdown,
no dependence on a specific agent, language or hosting platform.

```
idea → feature → plan → code → review → merge
```

| Skill | Takes | Produces |
|---|---|---|
| `feature` | a raw idea | a feature doc: flows, states, invariants, manual test scenarios, decisions |
| `plan` | one flow | an ephemeral plan with 1-2 cards and their failure modes |
| `code` | one card | working code, tests, and closed test-plan rows |
| `review` | the branch diff | findings ranked by severity, checked against the feature doc |

[`protocol.md`](protocol.md) explains why the process has this shape. The skills do not need it at run
time.

## Install

```sh
./install.sh /path/to/project
```

This creates:

```
.agents/skills/{feature,plan,code,review}/SKILL.md
.agents/workflow.yaml     # kept on re-install
.agents/protocol.md
docs/features/            # permanent feature docs
docs/_wip/                # ephemeral plans, added to .gitignore
```

Each skill is a folder with a `SKILL.md`: `name` and `description` in the frontmatter, instructions
below. If your agent discovers skills in a different folder, symlink that folder to `.agents/skills`.
If it has no skill support, ask it to read the `SKILL.md` and follow it.

## Using it

Ask for a skill by name, with the flow or card and any settings:

```
feature
plan F1
code "Card 2"
review
```

Every skill states its resolved settings in one line before it starts.

## Rigor

Set the speed-versus-care trade-off in `.agents/workflow.yaml`:

```yaml
rigor: fast
```

| Setting | `fast` | `standard` | `strict` | Controls |
|---|---|---|---|---|
| `domain_detail` | `brief` | `full` | `full` | domain model depth |
| `blind_gates` | `invariants` | `all` | `all` | where the human writes before the agent |
| `top_scenarios` | 3 | 5 | 7 | exact number of step-by-step manual scenarios |
| `extra_scenarios` | 3 | 10 | 15 | limit of one-line manual scenarios |
| `min_failure_modes` | 1 | 2 | 3 | failure modes named per card |
| `code_pauses` | `diff` | `stubs_and_diff` | `every_step` | where `code` stops for the human |
| `review_nits` | 0 | 3 | 3 | style findings reported per review |
| `rereview` | `fixes` | `full` | `full` | what is re-read after fixes |

Use `fast` for prototypes, `standard` for normal work and `strict` for code where a mistake is costly.

Tune any single value in the file:

```yaml
rigor: fast
overrides:
  top_scenarios: 4
```

Or for one run:

```
feature rigor=fast top_scenarios=4
plan F2 min_failure_modes=3
```

Run arguments win over `overrides`, and `overrides` win over the preset. With no file, skills use the
`standard` values.

These hold at every rigor:

- The domain is agreed before flows.
- Every feature has a feature doc with invariants and scenarios.
- Code ships with tests and a green check command.
- A wrong contract is fixed in place, in the same branch.
- `code` proposes `every_step` for migrations, auth, data deletion, transactional logic and
  cross-cutting refactors.

To harden a prototype later, re-run `feature` on its doc at a higher rigor. It asks only for what is
missing.

## Documents

| File | Lifetime | Holds |
|---|---|---|
| `docs/features/{feature}.md` | permanent | intent, flows, states, invariants, test plan, decisions |
| `docs/domain.md` | permanent | entities, legal states, boundaries |
| `docs/domain_glossary.md` | permanent | canonical names, deliberate non-entities |
| `docs/_wip/{feature}_{flow}.md` | until merge | cards, wire drafts |
