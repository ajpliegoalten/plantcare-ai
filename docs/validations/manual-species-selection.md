# Validation — manual-species-selection

## Verdict: revise

Independent validator `openai/gpt-6.1-sol`, interaction **validator-manual-species-selection-20261011-V1**, 2026-10-11. Feature `manual-species`, active spec `docs/specs/manual-species-selection.md`, HEAD `ab008ddc6df58719c4116ccbd5ce8d4b7619255e`. Product/round left **passing**; not accepted.

## One final gate, failed

Executed exactly once from repository root:

```sh
caffeinate -dius "$PWD/DerivedData/validator-manual-species-selection-20261011-V1-public/init.sh"   > "$PWD/DerivedData/evidence/validator-manual-species-selection-20261011-V1/gate.log" 2>&1
```

Unmodified `init.sh` changes into sandbox and runs its normal build, public photo seeding, simulator readiness, and serial full `xcodebuild ... -parallel-testing-enabled NO test`. No separate focused tests, retries, repeated suites, second gate, or implementation/harness fixes. Background shell `sh_12a5b0541001UxLcqMueFB3ArK`; existing caffeinate PID 91191 and testing xcodebuild PID 91535. Awaited original process via macOS kqueue NOTE_EXIT, followed by background completion notification; no replacement test process.

- Gate 11:46:10–12:19:56 +0200, **2026 seconds (33m46s)**; **exit 65**. Build succeeded; test failed.
- xcresult: **128 tests, 126 passed, 2 failed, 0 skipped/expected failures**. **100/100 unit**, **26/28 UI**; log records **10 failed assertions/actions** across those two UI scenarios, not 10 failed tests.
- xcresult test interval 11:46:21.961–12:19:52.583 +0200 (~2010.622 seconds); test observer elapsed 2005.206 seconds. UI execution 1975.653 seconds.
- Preserved bundle: `DerivedData/validator-manual-species-selection-20261011-V1-public/DerivedData/Logs/Test/Test-PlantCareAI-2026.10.11_11-46-21-+0200.xcresult`.
- Preserved evidence directory: `DerivedData/evidence/validator-manual-species-selection-20261011-V1/`: gate.log, gate.exit, gate-start/end.txt, gate-summary.json, gate-tests.json, await-process.json, sources-before.json, sources-after-comparison.json, corroborated-{unit,prepared,repair}.json. Bundled attachments remain in xcresult; no tests rerun to diagnose.

## High finding: full-gate editor UI regressions

Evidence in `PlantCareAIUITests/PlantCareAIUITests.swift` and preserved gate log:

1. `testCancelGestureValidationAndOptionalLocationWithMissingPhoto`: first failure line **913**, `replace` expected empty field, actually **"Ventan"**. Subsequent failures lines 999/1001: location remains and card says `Fixture 1, Monstera deliciosa, Ventan` rather than absent location.
2. `testEditPersistsAndRefreshesOnlySelectedPlant`: first failure line **913**, expected **"Salón"**, actually **"VentanaSalón"**. Subsequent failures lines 944, 955, 956, 888, 21 and unmatched plant-card tap cascade after incorrect editor state.

Why it matters: the required final gate is failed, so focused feature passes cannot establish independent acceptance. These scenarios/helper are unchanged in this delta; the evidence does not prove a product regression caused by manual selection. Nevertheless, they prevent full-gate acceptance. The immediate diagnostic hypothesis is that native triple-tap in `replace` did not select the whole current value before delete/type (partial deletion or append). This is a hypothesis, not an assertion that simulator noise or product correctness has been established.

Required change: make text replacement deterministic, or repair editor behavior if attachment/keyboard/focus inspection shows a real product fault, retaining exact field/card/persistence assertions and all scenarios. No weakening assertions or retries to mask failures.

## Implementation Repair Brief (next interaction only)

1. Inspect the two failed scenario activities/screenshots in the preserved xcresult and helper `replace` lines 896–913. Determine focus, selection and keyboard state when replacing `Ventana`; distinguish partial selection from binding/product behavior.
2. Correct only the diagnosed replacement mechanism or actual editor fault. Preserve empty optional location, exact `Salón`, selected-plant-only refresh, both plants/JPEG isolation and relaunch assertions. Do not modify manual selection, fixture semantics, scheme Debug executable, secrets, or optimize `init.sh`.
3. Under separately authorized implementer work, verify the two failed scenarios first plus directly affected editor regressions, serial on the same standard simulator. Record original failures, diagnosis, exact changes and new evidence without reclassifying V1 as passing.
4. A later independent gate requires separate authorization/interaction and changed relevant sources that invalidate this evidence. No further execution in V1.
5. Update handoff/PROGRESS with the repair and source comparisons. Parent must not persist accepted until independent acceptance.

## Independent review and corroboration

- Loaded feature-validator and project ios-clean-mvvm instructions; reviewed rubric/security checklist, spec, handoff, git diff/status, architecture/design/context/product/domain/risk docs and changed Swift/tests/resources.
- Selection is reversible/exclusive; manual draft discarded on deselection or IA selection; confirmed manual editing preloads identity and explicit cancel preserves prior state. Explicit confirmation remains separate.
- Manual admission uses validated result/revision/current photo/error-free state plus existing busy/closed/camera guards. Reidentification clears before consent/config checks; new successful photo clears; zero-candidate insufficientEvidence is valid success. Invalid results/errors/unavailable/cancelled operations cannot open manual editor. Generation/session guards prevent stale callbacks.
- View layout keeps field below selected badge inside outer manual card, editor sibling of selection button, headline option titles, callout categories. Uncertainty/proposal indicators removed only from Presentation, not Domain/API validation. No new IO, persistence, care, save, dependencies or cross-layer adapters.
- Independently read focused xcresults: 22/22 unit, prepared **FAILED 10/11**, repaired **1/1 passed**. Earlier sandbox build failure (missing public Debug plist) and prepared assertion failures remain preserved at `DerivedData/selection-ui-public-ebmlh7b1/focused-ui*`. Original repaired assertion matches process-scoped fixture invocation behavior; first-error negative coverage retained. No old failed bundle relabelled passing.
- Independently inspected reused screenshots `3146E1AF-70E0-4F30-A6CD-8335FB6EB2E4` (manual editor/CTA) and `2C0F0CF9-68F5-41DF-9B42-B20EE3137004` (options): readable normal-text/light hierarchy, card/badge/input containment and no IA/uncertainty notices. No claimed additional manual interactive smoke run.
- Static checks: git diff --check, project/public plist plutil lint, public JSON decoding, bash -n init.sh: passed.

## Environment, sources, security and documents

Fresh public sandbox includes **85 public files** (implementer manifest 84 plus `scripts/seed-identification-photos.swift`), all app/unit/UI/project/shared scheme/resources/init/public example/Debug plist inputs. SHA256 equality **root=before=sandbox=after for all 85**; six original/inline specs/handoffs/validation reports unchanged. User catalog stale extractionState/EOF diff retained byte-for-byte. Debug executable setting/shared scheme and harness preserved.

Only synthetic sandbox `Config/IdentificationSecrets.xcconfig` copied from public `.example` (empty key, reserved invalid host); never read/copied private config, xcuserdata or real secrets. No real API/photo sends or extra permissions. No security issues relevant to delta found: human text remains untrusted local display/domain value, empty trimmed input rejected, no new network/storage/injection sink, existing consent boundary intact. Botanical accuracy and future prompt trust remain limitations, not certified by tests.

Xcode **26.2/17C52**, macOS **26.5.1**, arm64 standard **iPhone 17 Pro iOS 26.2/23C54**, UDID **00BBB7EC-8DF7-400C-A08A-9D3C8818D886**. Single booted iPhone selected by unchanged init.sh, normal default text (no size override), light, serial UI, caffeinate, clamshell open; no existing xcodebuild/xctest/caffeinate processes before launch. No SE, larger text, VoiceOver, accessibility matrices, device/real camera/Release/API verification; outside routine scope, not automatic acceptance blockers.

Durable architecture/design/domain/brief updates correctly state current delta precedence over historical availability. Historical artifacts unchanged. Harness executes real build/tests and propagates failure; not optimized/modified. Only this validation report and appended PROGRESS evidence written; no feature state edit, stage/commit/push/PR or other feature.
