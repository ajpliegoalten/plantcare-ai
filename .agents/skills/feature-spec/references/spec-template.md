# Feature Implementation Spec Template

Use this structure for `../../../../docs/specs/<feature-id>.md`.

```md
# Feature Implementation Spec: <feature title>

## Source Feature

- `id`: <feature-id>
- `area`: <area>
- `depends_on`: <feature ids this feature depends on>
- `status`: <status at planning time>
- `source`: `feature_list.json`

## Goal

<One or two paragraphs describing the outcome this feature must enable.>

## Non-Goals

- <Behavior or technical work explicitly outside this slice.>
- <Adjacent feature that must not be pulled in.>

## Job Story

When <situation/context>,
I want to <motivation/action>,
so I can <expected outcome>.

## Users And Permissions

- <Actor/role>: <allowed behavior and constraints>

## Acceptance Scenarios

### Scenario 1: <happy path name>

Given <initial state>
When <user/system action>
Then <observable result>

### Scenario 2: <edge/error path name>

Given <initial state>
When <user/system action>
Then <observable result>

## Repository Research

### Files Inspected

- `<path>` — <why it matters>

### Existing Patterns To Follow

- <Pattern, convention, command, or architectural choice found in the repo.>

### Current Gaps

- <Missing app infrastructure, missing command, missing table, unknown integration, etc.>

## Technical Approach

<Describe the implementation strategy at a high enough level that another agent can execute it without re-planning.>

## Expected File Changes

- `<path>` — create/modify; <reason>
- `<path>` — create/modify; <reason>

If paths are provisional because the app is not bootstrapped yet, say so explicitly.

## Visual Design Impact

- UI involved: yes/no
- Design source: `../../../../DESIGN.md` / existing design asset / not applicable
- Screens or states affected: <list>
- New design artifact required: yes/no — <reason>

If UI is involved, follow `../../../../DESIGN.md` and identify any feature-specific visual states the implementer must handle. If `../../../../DESIGN.md` is missing but needed, mark it as a planning gap rather than letting the implementer invent a visual style.

## Durable Documentation Impact

- `../../../../ARCHITECTURE.md`: create/update/not needed — <reason>
- `../../../../CONSTRAINTS.md`: create/update/not needed — <reason>
- `../../../../AGENTS.md`: update/not needed — <reason>
- Other docs: <path or none> — <reason>

Use these rules:

- Update `../../../../AGENTS.md` only when the agent workflow, startup path, or repo-wide operating rules change.
- Create or update `../../../../ARCHITECTURE.md` when this feature establishes or changes domains, layers, runtime surfaces, dependency direction, adapters/providers, or other architectural boundaries.
- Create or update `../../../../CONSTRAINTS.md` when this feature introduces a durable MUST/MUST NOT rule that future agents must obey.
- Avoid duplicating product behavior already captured in discovery docs unless the implemented behavior changes the source of truth.

## Implementation Plan

1. <First implementation step.>
2. <Second implementation step.>
3. <Final integration/update step.>

## Implementation Tasks

- [ ] <Small executable task.>
- [ ] <Small executable task.>
- [ ] <Small executable task.>

## Verification Plan

Follow `../../../../AGENTS.md` for verification ownership and evidence reuse.

### Implementer — impact-selected checks

- <Changed files/contracts → risks/affected callers → focused tests and directly related regressions.>
- <Exact targeted command or manual scenario and expected result.>
- <Valid baseline evidence to reuse, or focused diagnosis/build if it is unavailable. No automatic full baseline/final gate.>
- <After a failure: rerun the failing scenario and repair-affected checks; preserve failures and explain diagnostic repetitions.>
- If the repo has a persistent E2E command such as `pnpm test:e2e` and this feature changes user-visible behavior, authentication, authorization, routing, or API flows, add or update focused E2E coverage and include the E2E command here. If E2E is not appropriate, state why.

### Validator — final gate

- <One full standard gate on final sources, or corroborated valid evidence of the same relevant source/environment state.>
- <Coverage gaps requiring extra checks, if any; do not repeat focused tests already covered by the gate without a reason.>
- <Conditions that invalidate full-gate evidence after repair and justify another run.>
- Documentation/instruction-only changes without executable impact need consistency/static review, not an iOS suite run.

For `init.sh`, be explicit:

- `./init.sh` should execute the non-blocking standard gate for the current repo state.
- `./init.sh` must not start long-running processes such as `pnpm dev`.
- It may print manual follow-up commands after the non-blocking checks pass.

## Evidence To Capture

- <Command output, screenshot, test name, log line, or manual result to record in `feature_list.json` or `../../../../PROGRESS.md`.>
- <Test selection/reason, source/environment state, newly run vs reused results, and full gate pending with validator.>

## Validator Checklist

- [ ] Implementation stays within this feature's scope.
- [ ] Acceptance scenarios pass.
- [ ] Verification evidence is present.
- [ ] Persistent E2E coverage was added/updated when the feature has an observable user/API flow and an E2E harness exists, or the spec explains why it is not needed.
- [ ] `feature_list.json` and `../../../../PROGRESS.md` were updated correctly.
- [ ] No unrelated product behavior or extra feature work was added.
```
