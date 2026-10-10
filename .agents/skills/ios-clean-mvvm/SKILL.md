---
name: ios-clean-mvvm
description: Plan, implement or review a Swift/SwiftUI iPhone feature in PlantCare AI following the repository's Clean Architecture + MVVM decision. Use for new iOS features, Swift refactors, persistence or API adapters, ViewModels, navigation and architecture reviews; consult ARCHITECTURE.md rather than redefining project rules here.
---

# iOS Clean Architecture + MVVM

Apply this workflow to **one selected feature**. This skill complements `feature-spec`, `feature-implementer` and `feature-validator`; it does not replace their role boundaries, status transitions, verification or commit rules. Do not start another feature just to fill an architectural layer.

## Read first

1. `AGENTS.md`, `ARCHITECTURE.md` (source of truth for structure and dependency direction), `PROGRESS.md` and the selected feature's entry in `feature_list.json`.
2. The selected `docs/specs/<feature-id>.md` when present; `DESIGN.md` for UI, and relevant product/domain/privacy docs. Check `docs/adr/` when an applicable decision exists.
3. The existing implementation in `PlantCareAI/`, `PlantCareAI.xcodeproj/project.pbxproj` and relevant tests. Inspect the actual worktree and preserve unrelated changes.

If a requested approach conflicts with `ARCHITECTURE.md`, a product constraint or the accepted spec, flag the conflict before coding; agree on the decision, then update the appropriate durable document. Do not silently override it inside this skill.

## Plan the feature

- Identify the user-visible behavior, non-goals, prerequisites, failure states and data ownership **per plant**, then map the minimum necessary types to `Features/<FeatureName>/Presentation`, `Domain` and `Data`.
- State the concrete dependency flow: View → ViewModel → injected use case → repository protocol → Data adapter, wired at the app's composition root. Identify which layer owns each transformation and side effect. Keep `ContentView` as a thin entry point, not a feature screen.
- Specify what each layer does **now**. A temporary adapter must explicitly admit its limitations; never claim persistence, AI success, network data or a real user action from an empty/stub implementation. Plan removal or replacement in the feature that owns it.
- For new contracts (storage, errors, concurrency, cross-feature reuse), describe real callers and test seams. If the decision affects multiple features or changes a previous contract, propose a short ADR in `docs/adr/` with context, decision, consequences and migration; keep `ARCHITECTURE.md` aligned after approval. Avoid a new protocol per type when no boundary or behavior needs it.
- Include exact Swift files, Xcode project registration, verification commands, focused functional tests and basic visual inspection on one standard iPhone Simulator at normal text size. Follow the verification policy in `AGENTS.md`; expanded checks must be explicitly requested by the user. Do not take on an adjacent feature to make a diagram look complete.

## Implement within the selected scope

- Presentation owns SwiftUI layout, accessibility, navigation intent and observable UI state. Views do not instantiate Data adapters or implement persistence/network rules; ViewModels depend on Domain contracts, not concrete adapters. Keep UI state explicit when loading or failure can occur: an error must not masquerade as an empty collection.
- Domain owns plant identity, business rules, use cases and repository contracts without SwiftUI, persistence framework or provider imports. Data implements those contracts and maps external/local representations; no Data types in Domain or feature views. Wire concrete adapters only at the composition root.
- Keep the iOS 17 SwiftUI conventions, semantic color and localization resources, Dynamic Type and VoiceOver behavior defined by `DESIGN.md`. Do not mistake an HTML reference or an external example for an iOS implementation requirement.
- If SwiftData, camera, concurrency or an API requires unfamiliar framework behavior, consult current official documentation; use Context7 only if connected and relevant. Documentation informs API usage, not the project's architectural decisions. Never configure MCP, introduce a dependency or store a credential just to complete this skill.
- Add Swift sources to the app/test target in `PlantCareAI.xcodeproj/project.pbxproj` (this project does **not** auto-discover source files). Avoid unrelated localization, resource or project-file rewrites.

## Verify / review

- Check dependency direction and composition in the actual diff; explain any cross-layer exception and its approved decision. Exercise a real/useful boundary with a focused test when behavior warrants one. Preserve or extend existing UI tests for observable behavior; do not delete passing assertions merely to ease a refactor.
- Follow `AGENTS.md` role-specific verification: implementer maps the diff/dependencies to risks and affected unit/integration/UI tests plus directly related regressions; build as needed and reuse valid baseline evidence, without automatic full-suite runs. Validator owns one final `./init.sh` gate (build + all unit/functional UI tests), reusing a corroborated valid gate of the same source/environment state instead of duplicating it. Diagnose/repair failures with focused checks first; repeat the full gate only when changes invalidate its evidence. Do not repeat tests already included in the gate without a concrete gap. Documentation-only work needs consistency/static review, not iOS tests without executable impact.
- For UI changes perform basic visual inspection on one standard iPhone Simulator, normal text size, one appearance. Small-screen/iPhone SE, increased/maximum Dynamic Type, VoiceOver/Accessibility Inspector and additional appearance matrices are outside routine verification: run them only on explicit user request, not merely when available. Preserve accessibility support and all functional tests/assertions. Report unrequested expanded checks as outside routine verification, not passed or mandatory pending work; preserve historical evidence. Coordinate with the active worktree session and do not duplicate or overlap simulator test runs. `plutil -lint PlantCareAI.xcodeproj/project.pbxproj`, JSON validation when files change and `git diff --check` are helpful static checks but not substitutes for running the affected behavior.
- Before reporting, update `ARCHITECTURE.md` only if the architecture actually changed; document major new tradeoffs in an ADR, user-visible rules in the relevant product/domain docs, and real evidence and residual risks in `PROGRESS.md`/`feature_list.json` according to the role workflow. Never mark `accepted` without independent validator acceptance; do not push unless asked.

## Handoff checklist

Report the feature and role, files and layers touched, concrete dependency path, tests actually run, user-visible result, remaining stubs or risks, and the next feature that owns their replacement. The independent validator should check these claims against code and evidence, not just the summary.
