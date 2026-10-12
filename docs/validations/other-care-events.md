# other-care-events — independent validation, 2026-10-12

## Verdict: revise

Feature `other-care-events`; approved spec `docs/specs/other-care-events.md`, SHA256 `33c919f05ea6e42cb95a8e1456e98ff06f854277fb88f3432dab6870eb5f844b`, unchanged. Root exclusive worktree other-care-events, branch feature/other-care-events, HEAD/base `a2fe57f751bf9324f85814ce1fc9d0b175e3b7b1`. Independent model openai/gpt-6.1-sol; feature-validator and project ios-clean-mvvm instructions plus validation/security checklists applied. Parent's authorization supersedes preserved planner-only language in approved spec; spec not edited.

No feature-product blocker found in contract/code review. Acceptance is prevented by the final gate's two actual UI failures and absence of its serial PhotosPicker phase. Eight CareEvents UI and all new unit/integration tests passed **inside a failed gate**, not independent acceptance. Feature remains passing (implementer self-verification); accepted/state transition and delivery belong to parent. No product/test/harness/spec changes, staging/commit/push/PR/merge/API/secret inspection by validator.

## New gate — original execution, preserved failure

Command from this worktree: `caffeinate -dius ./init.sh`, exactly once. Started `2026-10-12T11:47:35.033438+02:00`, finished `2026-10-12T11:58:08.994296+02:00`, exit **65**. BUILD SUCCEEDED, parallel TEST EXECUTE FAILED. Parallel session 11:47:48.621–11:58:08.443 +0200: **192 distinct cases:146/146 unit Passed,44/46 UI Passed,2 UI Failed**, zero skipped/expected failures. No runner launch error markers found in gate log, no infrastructure failure in summary; this does not guarantee elimination of historical launcher faults. Console and test tree independently show all192 cases once, no duplicates/omissions. `init.sh` set-e prevents gallery after failure: **gallery not executed, no gallery.xcresult**, no complete gate pass.

Exact bundle: `DerivedData/TestResults/20261012-114735-36572/parallel.xcresult`.
Evidence: `DerivedData/evidence/other-care-events-validator/{gate.log,gate.exit,gate-command.txt,gate-start.txt,gate-end.txt,parallel-summary.json,parallel-tests.json,parallel-root.json,discovery.txt}`. Failed test activities/details and exported attachments are in the same directory. `--only-failures` attachment export produced an empty manifest; export by individual test ID retrieved the retained hierarchies/recordings (43/41 attachments), not evidence of missing failures. No retry/iteration/focused rerun/second gate was launched. Original process awaited with Darwin kqueue NOTE_EXIT, caffeinate PID36573, and original background completion notification.

### Validator preparation deviation (not implementer fault)

No competing xcodebuild/xctest/init process before launch.116 public inputs matched ready manifest. However **no iPhone was Booted** in `devices-before.json`. The preflight Python expected agreed UDID00BBB7EC and raised AssertionError; the surrounding shell lacked `set -e` and incorrectly continued to launch the single original gate. `init.sh` consequently chose first available `B52F5194-6A81-4FAA-B094-B0D248084877`, local name **Edit Plant Recovery**, still **iPhone17Pro iOS26.2/23C54**, not agreed00BBB7EC. Log and xcresult corroborate actual destination. This is explicitly a validator coordination/preflight defect, not a claimed execution on00BBB7EC, not grounds to silently replace/discard the failed gate. It does not establish causality for the two failures.

Xcode26.2/17C52/macOS26.5.1/25F80 corroborated in version artifacts; default5workers, screenshots0, one model/runtime, XCTest-managed isolated clones. No text-size/appearance matrix or settings changes; normal/light handoff screenshots reused. Appearance/text settings on the mistakenly selected base were **not independently certified** before execution. A subsequent justified gate must boot/bootstatus/check agreed00BBB7EC, fail closed on destination mismatch, use one normal/light standard destination, and never run simultaneous tests or reset others' devices.

Sources before/after: all116 public executable/config inputs byte-identical to `DerivedData/evidence/other-care-events/ready-source-hashes.json`, manifest SHA256 `ed20eb9e1daef0a78426cf0696c2d853591f8317b611b1512576cb9e315cd49b`. `source-before.json`/`source-after.json` record equality; no catalog drift. Config only existence checked; public empty example would be copied if absent, existing ignored worktree file never read/copied/overwritten. No private config or xcuserdata inspection, no real API request.

## Findings preventing acceptance

### H1 High — native manual-field selection unavailable in two regressions

- Evidence: `ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterErrorRecovery()` and `testManualUnconfirmedDraftDiscardedAfterInsufficientEvidence()` fail once each. Legacy issue source reference line506; current helper `selectAllAndDelete` line507 is `XCTAssertTrue(selectAll.waitForExistence(timeout: 3))`. Activities show native long-press, unsuccessful Next lookup and missing Seleccionar todo/Select All. Failure happens during replacement of existing manual text, before rest of discard flow; no evidence of care-event write failure.
- Retained failure hierarchies: `error-recovery-attachments/8B0E59F4-0747-45CE-9769-087C35C762B0.txt` and `insufficient-attachments/BCDD902F-46AE-4B35-B2F3-38D07A337570.txt`. Both show manualSpeciesName **Potus, Keyboard Focused**, field frame y507...529, keyboard accessory Toolbar y491...539, no selection menu. This supports **keyboard/accessory occlusion or gesture targeting** as a concrete diagnostic hypothesis, not a proven root cause. Same app PIDs39327/39489 in failure snapshots; do not infer crash/dismiss/SIGKILL. Runtime warning Invalid frame dimension is present, not demonstrated causal.
- Why: standard final gate fails and two existing user-flow regressions are unverified; passing CareEvents alone cannot accept the feature.
- Required change: diagnose failed scenarios first; minimally make existing native manual-field replacement interaction reliable without editing product state or weakening empty/final-exact/discard/precarga/selection assertions.
- Suggested steps: inspect the retained recordings and activity/AX geometry; run only these failed scenarios on explicitly booted agreed standard destination with focused captures and stated occlusion hypothesis; if confirmed, fix reveal/keyboard-safe target/menu interaction only. Preserve native selection verification and fail-closed empty/final equality. Diagnose deeper product behavior only if evidence shows it, not from warning alone.
- Verification after fix: both failures, directly affected typeManual/selectAllAndDelete callers (ManualSpecies, CareSheet direct-manual, SavePlant automatic-manual) and editor paragraph callers if shared branch changes. Keep scenarios distinct/no repeated iterations/retries. After executable repair invalidates failed gate, validator owns one new complete gate including parallel and PhotosPicker serial. Old failure remains historical, never retroactively green.

### V1 High verification gap — final gate incomplete / preparation did not fail closed

- Evidence: exit65 and no gallery phase, plus preflight assertion continued into wrong UDID.
- Required outcome: a valid full gate on final relevant sources with both phases and real discovery, after diagnosis/repair; fail-closed launch coordination on agreed simulator. Validator/orchestrator wrapper correction only; **do not modify init.sh/product to conceal this failure**, remove assertions, or rerun unchanged full suite merely because a different UDID may be green.
- Verification: archive failed result above, coordinate no competing processes, explicit base boot/bootstatus/effective init-selection check, wrapper `set -e` or single checked Python runner before launch. If repair changes tests/resources/config, explain gate invalidation and run one final gate; first run failed/affected scenarios per H1.

## Spec / quality / scope review

| Contract | Independently inspected implementation and evidence |
|---|---|
| 1 empty/exclusive/toggle/guard | nil selectedKind; canSave and programmatic save guard; reversible selection preserves date/note, invalidates retry; eight E2E and six VM methods; loaded-only Detail factory/failing-photo availability tests |
| 2 five types/commit/isolated UUID | five stable raws; one sheet/module, generic canonical commit callback; two legitimate same-day UUIDs; independent kind/note/day expectations and full dispatch7 verify, both Plant/JPEG unchanged |
| 3 date/note/zone | unchanged Foundation temporal rules after rename; Gregorian/IANA/finitude/start-of-day/prealta/DST/omitted day/future/UTF8 tests retained; snapshot preserves7 on retry/travel; actual native calendar previous-day/future disabled E2E passes |
| 4 busy/error/retry/cancel | busy guard before suspension; UI fields/types/cancel/dismiss locked; success not discarded after late cancellation; rollback on disk; same snapshot retry/new UUID on edits; local error text and spinner inspected |
| 5 compatibility/conflict | @Model class/properties/schema V2 unchanged byte-equivalent after type rename; real V1 and V2 literal-watering stores reopen; every kind nil/notes/order/filter; kind/zone/UTF8 conflict not upsert; unknown raw errors before cleanup |
| 6 UI/regressions | literal localized switch avoids historical raw keys; shared header default48/care56/no IO; TextEditor/grid/icons/traits/check/scroll; editor and collection/fallback/alta related tests pass; two manual harness regressions prevent overall acceptance |

Architecture: Presentation → Domain ← Data; app composition uses same actor after overrides, no view creates adapter, Domain Foundation-only, ContentView unchanged. LocalPlantRepository changes only rule references, writer/rollback/dedup/order intact; no new entity/migration/reset/JPEG field. Module move is spec-authorized capacity refactor, not scope creep. No parallel QuickWatering wrapper/form, history/last-date/undo/recommendations/account/backend/new permission/network/footer. Parent issue#32 and future features untouched. Tests replaced by renamed/expanded versions, not removed coverage: historical five quick-watering scenarios retain authorized three-tap delta; new tests increase discovered suite.

Security checklist scoped to feature: **no relevant blocking security issue**. Inputs are local enum/date/note validated at Domain/Data boundary, SwiftData model operations no SQL/string-path interpolation from note. Plant/event UUID ownership explicit; unknown data fails before cleanup. No outbound service or new credential/dependency/privacy permission. Generic local errors do not expose note/JPEG/paths; fixture logs/sidecars only opt-in Debug Simulator and Release exclusion corroborated. No auth roles apply to single-user local prototype. Historical botany/API risks not recertified here.

Docs: ARCHITECTURE/DESIGN/domain/ADR009/testing/risk delta describe implemented behavior; approved spec/ADR008/history preserved. AGENTS/CONSTRAINTS need no new rule. Preserved planner text and historical pending notes are explicitly overridden by dated current sections, not rewritten as evidence. Handoff/state correctly distinguish passing from acceptance; parent must add failure/repair chronology, not claim full gate190 green.

## Reused evidence, independently corroborated (no executions repeated)

- Original focused.xcresult summary53/53, ui-repair8/8, regressions9/9 extracted again with xcresulttool summary/tests; all63 selected IDs confirmed Passed in original trees (46 unchanged unit +8 final Care UI +9 related UI). Original7 Care UI superseded after raw-key visual failure. Initial/final116 manifests differ only four presentation/catalog/UItest paths, substantiating unchanged-unit reuse. Historical regression Clone4 launch event disclosed, not runner-error-free; no omitted scenario inferred from9/9 and one console execution each. Original visual failure remains a failure of initial visual presentation despite green53.
- Existing final Release BUILD SUCCEEDED exit0 corroborated. Independently ran nm/strings against final Release binary: CareEventTestFixture/--care-fixture/--care-verify/--care-expectations-base64/CareExpected.json absent. All five keys in **public** IdentificationDebugInfo.plist absent from Release Info.plist. No rebuild/private config read.
- New static: plutil project, bash -n init, git diff --check, feature JSON, unique catalog keys and unchanged unrelated translations pass. Domain rules/PersistedCareEvent/repository contract compared with HEAD after mechanical rename, preserving previously accepted implementation. Gate compiled all new sources/test targets; explicit project registration inspected.
- Ten final existing PNGs opened independently in `DerivedData/evidence/other-care-events/ui-repair-attachments`:186C68F7(empty),F032DD49(Abonado),410F950B(error),C62B49ED(busy),E0BCDB23(placeholder),3C2399FF(keyboard),E4CD1F1D(scroll CTA),7238A831(editor),6DEF9B46(real confirmation),8D9C8519(calendar). Full filenames in source handoff. Labels/icons/check/grid intact, no raw keys/horizontal clipping; CTA reached by scrolling, editor identity/layout intact. No new interactive manual walkthrough claimed; gestures executed by original XCUITest. No pixel-perfect inaccessible HTML claim.

## Implementation Repair Brief

1. Preserve this FAILED gate, original failures/attachments and all previous evidence; no accepted/commit yet.
2. Correct validator launch preflight to abort on any check failure; coordinate and explicitly boot agreed00BBB7EC iPhone17Pro/iOS26.2, normal/light5workers. Do not reset other devices/change matrices.
3. Diagnose **only both failed ManualSpecies scenarios** first with occluded manual field/menu hypothesis and native interaction evidence. No full baseline/gate as diagnostic.
4. Repair minimum verified helper cause, retaining all assertions and native selection; run failed tests and relevant callers once on final repair, editor callers only if their shared behavior changed. Product care-event code requires no speculative repair.
5. Update repair handoff/source hashes/status/evidence. New complete validator gate justified only by relevant executable changes or evidenced environment/config repair invalidating previous gate; do not simply retry unchanged failures for green. Both phases required. Parent controls final accepted and authorized local commit; no push/PR.

Suggested diagnostic command after coordinated boot and build-for-testing/configure helper if sources changed:

```sh
caffeinate -dius xcodebuild -xctestrun "$RUN" \
  -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' \
  -parallel-testing-enabled NO \
  -only-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterErrorRecovery \
  -only-testing:PlantCareAIUITests/ManualSpeciesUITests/testManualUnconfirmedDraftDiscardedAfterInsufficientEvidence \
  -resultBundlePath "$NEW_DIAGNOSTIC_BUNDLE" test-without-building
```

No diagnostic execution above was run by validator; parent/implementer owns repair. Expanded SE/text-size/VoiceOver/appearance/device/camera matrices outside habitual, not executed or automatic blockers. No new real API test needed for local event feature. Downgrade/multiprocess/physical corruption/draft recovery not promised.

## Local user smoke after acceptance (not acceptance evidence)

Open PlantCareAI.xcodeproj in Xcode and run on standard iPhone Simulator. In any saved plant: Registrar cuidado → confirm no type and disabled Guardar → Abonado → Poda → tap Poda again, no selection → choose Otro, Ayer and optional multiline note → Guardar cuidado. Expect Cuidado registrado only after commit; reopen fresh nil/Today/empty draft. Cancel another draft and confirm no feedback/write; check Editar still works. Relaunch preserves store, but **visible history is intentionally absent**; runtime persistence is covered instrumentally, not by a nonexistent timeline. No credential/network needed for registering care on an existing plant. Current verdict revise means fix/gate first, not handoff as accepted.

---

# Resumed independent validation V2 — current verdict: accept (2026-10-12)

**This dated closure is the current verdict.** The original REVISE/FAILED190/192, preparation deviation, hypotheses and repair brief above remain historical, not overwritten or reinterpreted. H1 and V1 are closed for acceptance by scoped repair evidence and the genuine final full gate below; no remaining repair brief applies. `feature_list.json` stays passing until parent persists accepted/authorized local delivery. No stage/commit/accepted/publication by validator.

## Repair independently reviewed

Read complete `docs/handoffs/other-care-events-repair.md` and PROGRESS, resumed same independent validation/runtime. Only changed executable input since failed gate is UItest file SHA256 `063fb0fda9521833d650d3caf2a30e812e6fcc5454ee361dabc343e7fb9bfbbf`.115 other public executable/config inputs unchanged, so original product/Domain/Data/schema/caller/security/design review and Release remain valid; no rebuild/repeated audit/focused product runs required for this test-only change.

Mechanically removing only new private `revealFocusedManual` plus its post-focus call/comment reproduces **exact old tested UI hash**70c77935e0a70731da7ff5d6052d2a3976050d7f58318480d86029ccaf2cfd6e; stored corroboration `repair-review.txt`. Native selection/long-press/menuNext/one delete/empty/final-exact/discard/precarga/relaunch assertions and paragraph editor branch remain byte-identical. New helper recomputes top and keyboard/Done bottom bounds after focus, uses bounded content-gutter drags when needed, asserts whole field unobscured/hittable before selection, no sleeps/test retries/direct product-state mutation. This directly addresses the missing post-focus geometric precondition identified by original overlapping AX; no speculative care product fix/scope expansion.

Unchanged diagnostic **2/2 Passed** does not reproduce original failure or establish definite root cause. Old AX/recordings prove overlap and missing-menu failure; exact absent-menu causality remains unproven, neither blamed on UDID nor warning. Final repaired2/2 plus five other callers5/5 corroborated independently with xcresulttool summary/tests (seven distinct scenarios, diagnostic not added). Destination00BBB7EC/iPhone17Pro26.2/23C54 and zero failures/skips/expected failures corroborated. Original bundles preserved in `DerivedData/evidence/other-care-events/repair-H1`; independent extraction under validator-V2 `reused-{diagnostic,repaired,callers}-{summary,tests}.json`. No reruns by validator.

Three final repair PNGs actually opened independently:6796DFB1-CD83-4B1A-BEDE-262D3A6D2954(target unobscured),88B39E05-0BEE-49DF-B0BB-A83018C0D5A8 and C5F2B34C-F7D7-4B76-A883-6ECC2AA58671(selected full Potus with native handles/menu). Product design inspection of ten final CareEvents/editor PNGs from first review remains valid by unchanged product inputs. No new manual interactive walkthrough or universal harness reliability claim.

## Corrected preflight — failure closed, outside product/init

Outer launcher `set -e`, checked Python subprocesses/assertions stop before gate if any validation fails. No xcodebuild/xctest competitors at launch. Agreed base `00BBB7EC-8DF7-400C-A08A-9D3C8818D886` model iPhone17Pro/runtime26.2 explicitly verified, boot if needed, `xcrun simctl bootstatus <UDID> -b`; no other device reset/shutdown. `simctl ui <UDID> appearance light` followed by queried **light**; `content_size large` followed by queried **large** (normal iOS text size, not enlarged/accessibility matrix). Exact init selection algorithm applied to current available devices, first Booted iPhone==00BBB7EC asserted before invocation. Gate log and both xcresults confirm same actual destination.

Xcode26.2/17C52; macOS26.5.1/25F80. One standard/light/normal destination,5 XCTest workers/clones for parallel, serial real PhotosPicker. `TEST_WORKERS=5 UI_TEST_SCREENSHOTS=0` explicit. Existing ignored config existence only, never contents read/copied/overwritten; no secrets/API/private xcuserdata. `init.sh` and product unchanged.

Evidence directory **`DerivedData/evidence/other-care-events-validator-V2`**: preflight.txt, bootstatus.log, devices-before/effective.json, appearance.txt, content-size.txt, xcode.txt, os.txt, original.pid, event-wait.txt, command.txt/log/start/end/exit and source-before/after.json. Corrected wrapper not part of product/init or a source change. First gate remains genuine failed evidence on its actual destination; V2 is justified by the relevant UI helper change, not retrying identical sources for green.

## New final gate — complete and Passed

Command **`caffeinate -dius ./init.sh`**, once on repaired final state. Whole invocation **12:28:30.539969–12:40:34.295396 +0200**, exit **0**, BUILD SUCCEEDED and **both TEST EXECUTE SUCCEEDED**.

- Parallel session **12:28:41.639–12:39:42.446 +0200**: **192/192 =146 unit+46 UI** Passed.
- Real PhotosPicker serial session **12:39:50.862–12:40:34.240 +0200**: **1/1** SystemGalleryUITests/testRealGalleryPickerSelectReplaceCancelAndReselect Passed.
- Total **193/193 distinct cases**, zero failures/skips/expected failures, no runner launch-error markers found. Both H1 scenarios, all typeManual callers,8CareEventsUI and editor regressions passed. Both summaries/tree identifiers and console execution records independently corroborated:192 parallel each once plus one serial gallery once, no duplicate/omitted test. Discovery is actual, not assumed from old185 count.
- Build-for-testing once; both phases test-without-building, default5workers parallel and serial Photos media seed/selection on base. No retry/iteration/repeated focused test/new baseline or second V2 gate.
- Waited **original** caffeinate PID43874 using kqueue NOTE_EXIT and its background completion event; no polling/relaunch, did not return while gate running.

Exact original bundles:

```
DerivedData/TestResults/20261012-122831-43874/parallel.xcresult
DerivedData/TestResults/20261012-122831-43874/gallery.xcresult
```

Independently extracted `parallel-{summary,tests}.json`, `gallery-{summary,tests}.json`, bundles.json/discovery.txt under validator-V2. A first postprocessing regex mistakenly included command-prefix text while extracting paths; assertion aborted that read-only parsing, corrected whitespace-bounded parser extracted the two real paths. This was **not a test failure, source change or gate rerun**; original runtime evidence unaffected.

Sources116 before/after equal `repair-H1/source-final.json`, SHA256 **`b4b98e3bdd2bddda70c8cebf2a78d0e8f00ddf7347cb196f2c962f1bed184d1f`**, no drift. Approved spec SHA25633c919f05ea6e42cb95a8e1456e98ff06f854277fb88f3432dab6870eb5f844b intact. Independent new plutil/bash syntax/git diff--check/spec hash pass before gate; source correspondence also checked after. Product115/Release and prior architecture/security/docs/design evidence reused, not falsely attributed to new test executable.

## Final assessment and parent handoff

**accept**: spec's six scenario groups met with product review/compatibility/instrumental persistence/E2E/visual evidence and now valid complete standard gate. Scoped security checklist no relevant blockers; no new external service/permission/dependency/secret. Durable docs/harness consistent, original failures and cause limits preserved. No unresolved acceptance finding; original exact absent-menu cause not universally proven, and no universal guarantee against future simulator faults.

Parent may persist **accepted** and authorized **local** commit, including approved untracked spec unchanged and validation/repair handoffs; no need to rerun gate for status/docs/role-only changes. No push/PR/merge by validator. No future feature started. Local user smoke remains above: select/toggle types, optional note/Ayer, commit confirmation, fresh reopening/cancel, Editar preserved; history deliberately absent, persistence proved instrumentally. Registering care requires no API. Physical device/camera/downgrade/multiprocess/damage/draft restoration and expanded SE/text/VoiceOver/appearance matrices not claimed or automatic blockers.
