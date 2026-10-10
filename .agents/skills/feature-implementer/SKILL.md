---
name: feature-implementer
description: Implement exactly one planned feature from a feature spec file under docs/specs. Use when the user asks to implement a feature spec, execute the selected feature, act as the generator/implementer in a planner-generator-validator workflow, or turn a feature implementation spec into code. The skill self-verifies the work, updates progress/evidence, and updates durable documentation when required, but it does not perform final independent validation.
---

# Feature Implementer

Use this skill to implement one already-planned feature. The implementer writes code, runs the required checks, records evidence, and leaves the repository ready for an independent validator.

## Role Boundary

You are the implementer/generator, not the planner and not the final validator.

- Do implement the selected feature.
- Do self-verify with impact-selected checks under `../../../AGENTS.md`; the validator owns the full final gate.
- Do update status, progress, evidence, and required durable docs.
- Do not broaden the feature scope.
- Do not silently redesign the spec. If the spec is wrong or blocked, update the spec with findings or mark the feature blocked instead of improvising.
- Do not declare final acceptance. Leave that for `feature-validator`.
- Treat `passing` as "implemented and self-verified, ready for independent validation", not as final acceptance.
- Never set a feature to `accepted`; only the main orchestrator may persist `accepted` after an independent validator returns `accept`.

## Inputs To Read First

1. `../../../AGENTS.md`
2. `../../../PROGRESS.md`
3. `feature_list.json`
4. Selected feature spec: `../../../docs/specs/<feature-id>.md`
5. Durable docs if present and relevant:
   - `../../../ARCHITECTURE.md`
   - `../../../CONSTRAINTS.md`
   - `../../../DESIGN.md` when the spec has UI or visual behavior
   - relevant docs under `docs/`
6. Existing application files named in the spec's repository research and expected file changes.

If no feature id is provided, choose the feature that is currently `in_progress`; otherwise choose the first feature in `feature_list.json` order whose status is neither `passing` nor `accepted`, whose `depends_on` prerequisites are satisfied, and that already has `../../../docs/specs/<feature-id>.md`.

A dependency is satisfied when the referenced feature id exists and has status `accepted`. For legacy feature lists, a dependency with status `passing` may be treated as satisfied only when durable evidence shows independent validator acceptance. If `depends_on` is absent in an older feature list, treat it as `[]` for backward compatibility.

If no spec exists for the selected feature, stop and ask the user to run the planner/spec step first.

## Workflow

### 1. Confirm The Contract

Read the selected spec and identify:

- goal and non-goals,
- acceptance scenarios,
- expected file changes,
- durable documentation impact,
- implementation tasks,
- verification plan,
- evidence to capture,
- validator checklist.

If the spec is too vague for implementation, stop with a concise blocker and recommend revising the spec.

### 2. Set Feature State

Before code changes, ensure `feature_list.json` reflects one active feature:

- mark the selected feature `in_progress` if it is not already,
- keep all unrelated unfinished features `not_started`,
- do not mark anything `passing` before verification evidence exists.

### 3. Implement Only This Feature

Make the smallest coherent set of changes needed to satisfy the spec.

Rules:

- Follow existing repository patterns.
- Keep WIP=1.
- Do not implement adjacent features from `feature_list.json`.
- Add regression/unit/integration/smoke tests when they fit the feature and current repo maturity.
- If the repo has a persistent E2E command such as `pnpm test:e2e` and the selected feature changes user-visible behavior, authentication, authorization, routing, or API flows, add or update focused E2E coverage unless the spec explicitly justifies not doing so.
- Use `references/implementation-rules.md` for durable documentation rules.

### 4. Self-Verify

Apply the verification policy in `../../../AGENTS.md`, including when an older spec assigns a full gate to the implementer. Do not rewrite an approved spec to apply this policy.

- Analyze the actual diff, changed contracts and affected callers. Record a compact changes → risks → selected tests mapping and exact commands, including directly related regressions. Shared persistence/composition/navigation/resources may warrant a broader selection; justify it instead of automatically selecting everything.
- Run affected static checks, focused unit/integration/UI tests and basic visual inspection for affected screens. Build as needed, but do not run the full standard gate or an automatic full baseline before/after implementation. Reuse valid baseline evidence for the same relevant source/environment state; if absent or broken, diagnose with build/focused checks first.
- After a failure, repair and rerun the failing scenario plus checks affected by the repair, not every suite. Never enable repeated-test iterations/retries to obtain green; diagnostic repetitions require a stated hypothesis and preserve failures.
- Hand off focused evidence, its source/environment state and any coverage gaps. The full final gate belongs to the validator; its deliberate deferral is not a blocker for `passing`. If an implementer full run is exceptionally needed, state the concrete reason so the validator can reuse valid evidence rather than duplicate it.
- If a required focused check cannot run, document exactly why and what is missing; do not claim it passed.

If the feature creates or updates `init.sh`, make it an executable non-blocking gate: it should run the standard verification checks for the current repo state and must not start long-running dev servers. A script that only prints the checks is not enough unless the spec explicitly says this repository is still pre-bootstrap.

Self-verification should include the applicable levels for the impacted scope, not all repository tests:

1. static/syntax checks,
2. tests and runtime/startup checks,
3. persistent E2E checks when the repo has them and the feature affects an observable user/API flow,
4. manual user-flow or smoke checks when persistent E2E is not yet available or cannot cover the case.

If any required check fails, fix it or leave the feature non-passing with a clear blocker. Do not hide failures.

### 5. Update Harness State

After verification:

- update `feature_list.json` for the selected feature only,
- record exact evidence for checks that passed,
- update `../../../PROGRESS.md` with what changed, what ran, what failed, and the next best step,
- update the session handoff note if it exists or if the session leaves meaningful incomplete state,
- update durable docs required by the spec or discovered during implementation.

CONSTRAINTS.md rule: read `../../../CONSTRAINTS.md` before implementing (see Inputs To Read First). When implementation or verification reveals a durable operational constraint (a MUST/MUST NOT rule future features have to respect), append it to `../../../CONSTRAINTS.md` with a short reason. Do not add speculative rules or restate what the spec, `../../../AGENTS.md`, or `../../../ARCHITECTURE.md` already cover; follow the durable documentation rules in `references/implementation-rules.md`.

Status rule:

- `passing` means impact-selected self-verification passed and evidence is recorded; the full gate may still be pending with the validator and must be labelled as such.
- `passing` does not mean independently accepted. It means the implementer believes the feature is ready for `feature-validator`.
- `accepted` means an independent validator returned `accept` and the main orchestrator persisted that acceptance.
- `blocked` means implementation cannot continue and the reason is durable in `../../../PROGRESS.md` and/or the feature entry.
- If implementation is partial or unverified, leave `in_progress` or `blocked`, not `passing`.

### 6. Leave Validator-Ready State

Before finishing, ensure a fresh validator can review without this chat:

- source changes are saved,
- generated temporary files are removed,
- checks/evidence are recorded,
- docs and harness state are consistent,
- final response lists changed files and verification run.

## Output Summary

Report:

- selected feature id and spec path,
- what was implemented,
- verification commands/checks and results,
- files changed,
- harness/docs updated,
- whether the feature is ready for independent validation.
