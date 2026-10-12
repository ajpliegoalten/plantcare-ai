# other-care-events — implementer handoff

## Current follow-up after independent revise

See `docs/handoffs/other-care-events-repair.md` for H1 repair/current116-source manifest and seven final caller scenarios Passed. Independent gate FAILED190/192/Photos absent remains preserved in `docs/validations/other-care-events.md`; not approved. Only UI helper changed to enforce post-focus unobscured native selection geometry. Historical failure not reproduced in initial unchanged diagnostic; no UDID causal claim. Current state passing repair, not accepted; same validator must new full gate justified by test source change, with exact agreed destination/fail-closed bootstatus and Photos serial. Original manifest/verification claims below refer to pre-repair sources, unchanged115 product/harness inputs reusable; no assertion that previous gate passed.

## Contract and role

Spec `docs/specs/other-care-events.md` approved byte-intact SHA256 `33c919f05ea6e42cb95a8e1456e98ff06f854277fb88f3432dab6870eb5f844b`. Exclusive worktree/branch feature/other-care-events, base a2fe57f751bf9324f85814ce1fc9d0b175e3b7b1. Parent authorization supersedes the preserved planner wording; Issue #32 belongs to parent. No staging/commit/publication/delegation or final acceptance by implementer.

feature-implementer and project ios-clean-mvvm instructions loaded. Installed XcodeBuildMCP skill read denied external_directory; no MCP tools available/called. CLI fallback. Existing planner history preserved. Config prepared only if absent from this worktree's public example, never copied from another checkout/read private values. No API calls.

## Implementation

- Features/CareEvents replaces QuickWatering, layers and explicit target references; five stable raws, same seven-field Foundation entity/rules.
- One RegisterCare form/session, nil/exclusive/toggle selection, guard/canSave, invalidate retry on kind/date/note edits; immutable retry/canonical callback/busy lock.
- Native grid/icons/TextEditor and Spanish resources/IDs. Header snapshot56 care/default48 editor, no photo IO. Detail/list/app injection and generic real-commit feedback; unchanged static substrate advice/six-care sheet/editor behavior.
- Same PersistedCareEvent model/properties/schema V2, actor/context/store, rollback/dedup/order/unknown raw failure. No migration V3/reset/history/recommendations/last-date/IA.
- Fixture Debug only captures dispatch7 and independently matches kind/note/day expectations for confirmed events; discarded failed intentions not treated as committed. A/B Plant/JPEG comparisons via storage-verify.
- ADR009, ARCHITECTURE, DESIGN, domain/testing/risk docs updated; ADR008/specs historical intact. No new operational constraint beyond existing contracts.

## Changes → risks → selected verification

| Changes | Risks | Selected tests |
|---|---|---|
| Domain rename/kinds | Temporal/UTF8 invariants, callers | RegisterCareEventTests entire, retaining DST/omitted/future/prealta/zones/5k notes; five-kind shared rules |
| VM/form | nil guard/toggle/busy/retry/new kind/zone/day/callback | RegisterCareViewModelTests entire; CareEventsUITests seven functional scenarios, visual captures only affected screens |
| String mapping/shared writer/fixture | V1/V2 compatibility, unknown/conflict/order/rollback/JPEG | LocalCareEventRepositoryTests and LocalPlantRepositoryTests entire |
| Detail/list/app/header | Session UUID/confirmation/photo cache, edit/alta/navigation/localization | PlantDetailViewModelTests, PlantListViewModelTests, EditPlantViewModelTests; EditPlantUITests, StoredCollectionUITests, SavePlantUITests, LocalizationUITests, PlantCardsUITests/testPhotoFailureKeepsCardsAndNavigation |

Actor/composition refactor justifies related storage/alta regressions; unrelated transport/consent/photo-identification suites and real PhotosPicker deferred to validator gate. Dependency accepted185/185 is historical, not reused as execution on refactored sources. No automatic baseline/full gate, iterations or retries.

## Environment/evidence

Xcode26.2/17C52, macOS26.5.1/25F80; sole standard iPhone17Pro iOS26.2 UDID00BBB7EC-8DF7-400C-A08A-9D3C8818D886, normal text/light, XCTest isolated clones up to5. Process/simulator coordination before build: no competing xcodebuild/xctest/init; agreed base simulator booted. caffeinate for commands. No expanded matrix requested/run.

Evidence directory `DerivedData/evidence/other-care-events`; dedicated products `DerivedData/OtherCareEvents`. build-command.txt/log/start/end/exit record initial TEST BUILD SUCCEEDED exit0. Sources manifest, command scripts/log/exit files and xcresult bundles record exact states/selections (closure below). All failures, if any, must remain historical. Static initial plist/JSON/diff-check/spec hash passed; final checks/results recorded at closure.

## Historical intermediate checkpoints (superseded by final closure below)

At the initial checkpoint focal unit/integration/UI and Release/audit/visual inspection were pending, status in_progress. Final closure is below. Validator owns one final `caffeinate -dius ./init.sh` on final executable inputs; PhotosPicker serial required. Parent handles validator/local commit, no subagent publication.

### Intermediate evidence (not completion)

Original focused invocation completed53/53=46unit+7UI, exit0, zero failures/skips/expected failures. However actual screenshots AE0C312E/B63C940B/7AC71E44/57BC8CB9 inspected show raw kind keys, a real visual failure not caught by initial labels assertions. Do not count as completed visual approval. Hypothesis confirmed: interpolated LocalizedStringKey creates format key, not literal full key. Repair uses Presentation switch of literal keys; open-form assertions now require all five Spanish titles and English fallback scenario extended. DatePicker explicitly compact/es_ES per spec. Final Care UI repair plus related regressions required; unchanged unit/Data/VM evidence reusable by exact inputs. Native calendar diagnostic discovers public accessibility tree to complete previous/future selection coverage, not production logs/private data. Original bundle/captures preserved. Original process awaited via Darwin kqueue NOTE_EXIT, no polling/rerun/competing test.

Release generic Simulator `caffeinate -dius xcodebuild -project PlantCareAI.xcodeproj -scheme PlantCareAI -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/DerivedData/OtherCareEventsRelease" build` BUILD SUCCEEDED exit0; release.log/start/end/exit. Generic compilation uses no simulator or test runner; it ran while the sole focused test invocation was active, not a second test process. release-audit.log: nm/strings confirms CareEventTestFixture/new fixture/verify/expectation flags/CareExpected.json absent; release Info.plist excludes exact five keys read from public Config/IdentificationDebugInfo.plist. No private config inspection. Source-public.json116 SHA256 d0e498080d69245f04633207b1bb345b48f7fee2e5243e3cfdbd0ed02f5865cd; no drift after both builds. source-build.json115 is the initial subset, includes all Swift/catalog/project/assets/scheme/public example/harness; source-public adds tracked public plist. Parse modified Swift/Domain Foundation typecheck/plist/JSON/diff pass. Existing token contrast computed: PrimaryAction/white6.58:1, PrimaryAction/CareMint5.08:1, TextSecondary/SurfaceMuted8.47:1; not a substitute for pending real screenshot inspection. Focused log contains exact invocation/selection; screenshots1 only CareEvents affected flows. No full gate launched.

## Final closure — passing, ready for independent validator (not accepted)

63 distinct selected scenarios=46unit+17UI, all current selected results Passed with zero test failures/skips/expected failures. `selected-evidence.json` SHA256 fd070ae0f0b733e74770fade7cc2b152cfa9038e410a2d375c862b48e0d44cac enumerates exact IDs, bundle and reuse. No sum of repeated executions. Source manifest `ready-source-hashes.json`116 public executable/config inputs SHA256 ed20eb9e1daef0a78426cf0696c2d853591f8317b611b1512576cb9e315cd49b, equal to source-ui-repair.json and root across final Care UI, regressions and final Release. Compared to original116 only four inputs changed: RegisterCareView.swift, PlantDetailView.swift, Localizable.xcstrings, UI test file. Therefore original46 unit/Domain/Data/VM/callers evidence reused by unchanged relevant implementation/test inputs; original7 Care UI replaced by final8. No product/test/source edits after final verification, only docs/status/evidence.

### Runs actually executed

All commands run from this exclusive root, caffeinate, sole agreed standard destination. Exact xcodebuild invocations in corresponding logs; selector discovery/summary JSON and start/end/exit artifacts alongside.

| Run | Selection/result | Source and purpose |
|---|---|---|
| build | build-for-testing, exit0 TEST BUILD SUCCEEDED,11:12:09–11:12:22+0200 | Initial public sources; no full baseline |
| focused | Seven unit classes above +CareEvents7; exit0 Passed53/53,11:15:03–11:21:45 | Preserve original visual failure separately; only46 unit cases retained as current evidence |
| release | Generic Release build/audit exit0,11:17:22–11:17:32 | Initial evidence superseded for changed production view/catalog by release-final |
| build-repair/calendar-discovery | Debug build exit0; diagnostic calendar1/1 exit0,11:23:41–11:24:50 | Discovered public UIKit calendar day labels and disabled future/next-month controls. Not completed acceptance scenario nor extra coverage. Console get-log unsupported; legacy activity log contains fixture-only diagnostic tree. Print removed from final tests. |
| build-ui-final/ui-repair | Debug build exit0; final CareEvents8/8 exit0,11:27:27–11:34:36 | Literal kind keys, explicit compact/es_ES picker, registrationTitle unique key; label assertions, complete native previous/future/calendar payload case. Captures1 only affected CareEvents. |
| regressions | EditPlant2+StoredCollection2+Localization1+SavePlant3+photo-failure1; exit0 Passed9/9,11:34:50–11:39:44 | Final sources, captures0. All scenarios actually executed once, including new five-title English fallback. Runner environment event below disclosed. |
| release-final | Generic Release build/audit exit0,11:41:15–11:41:26 | Necessary new build due changed production view/catalog; nm/strings renamed fixture/flags/sidecar absent, exact five public Debug bridge keys absent from Release plist. No simulator execution/API. |

`RUN` is `DerivedData/OtherCareEvents/Build/Products/PlantCareAI_iphonesimulator26.2-arm64-x86_64.xctestrun`; scripts/configure-ui-test-environment.py sets1 for Care UI,0 for regressions. Every test command uses `-xctestrun "$RUN" -destination 'platform=iOS Simulator,id=00BBB7EC-8DF7-400C-A08A-9D3C8818D886' -parallel-testing-enabled YES -parallel-testing-worker-count 5 -maximum-concurrent-test-simulator-destinations 5 … -resultBundlePath "$E/<run>.xcresult" test-without-building`. Exact -only-testing lists are in logs, with no retries/iterations. Builds use the approved project/scheme/destination/DD; generic Release has separate DD. Reuse products only for same source state. No init/full gate or real PhotosPicker executed by implementer.

### Repair findings and preserved environment event

Raw kind labels were a real failure despite green53: interpolated LocalizedStringKey constructs a format key. Presentation now returns literal keys via switch; open form asserts five localized titles and fallback English test enters form. Distinct header key `detail.care.registrationTitle` avoids collision with existing `detail.care.title` (six-care heading unchanged). JSON duplicate-key checker now passes and prior translations outside retired watering UI preserved. Native calendar test computes live dates (not hardcoded), uses actual Spanish accessibility day labels, checks future disabled/current month or nextMonth at boundary, selects yesterday through DatePicker, checks chips and verifies pruning/null-note/day independently after reopen.

Regression log11:38:10 records Clone4 UDID8F515257-C56B-4C24-9822-8C9693AA054A runner launch RequestDenied/FBProcessExit64. This is **not** represented as a scenario failure in xcresult: summary Passed9/9, testFailures empty, and tests tree/log show each expected scenario once in clones1–3. Do not claim runner-error-free; underlying launch cause is not established. No automatic/manual test repetitions enabled or additional run performed to hide event. No missing scenario/gap to justify rerunning passed cases. Validator must review/diagnose any final gate runner errors; this focal run does not certify final gate environment. No reset/reboot of another session's device.

### Actual visual inspection

Opened ten **final** PNGs under ui-repair-attachments (not just filenames/assertions):

- 186C68F7… empty: own photo/name/subtitle, five real Spanish labels/icons, grid widths/Otro left, Today selected and no type.
- F032DD49… Abonado: exclusive green border/check/mint, legible accent and all unselected types.
- 410F950B… error: retained Riego/date/empty note, complete local error and green Reintentar reachable.
- E0BCDB23… photo placeholder: leaf visible/name/ownership and controls intact.
- C62B49ED… busy: controls/cancel disabled, spinner/Guardando cuidado and neutral disabled CTA.
- 3C2399FF… long keyboard and E4CD1F1D… scroll: native TextEditor scroll retains full payload asserted/persisted, Done removes keyboard, CTA reachable, no horizontal overflow.
- 6DEF9B46… detail confirmation: own identity/photo, Cuidados/Registrar cuidado and Cuidado registrado only after commit; six-care heading/static substrate advice preserved, no last-date/Deshacer.
- 8D9C8519… native calendar: selected live date, future days/nextMonth disabled, Spanish compact popover.
- 7238A831… editor: unchanged48 own snapshot, long name/location intact, same fields/Guardar reachable.

Original raw-key images/bundle retained, not approved retroactively. Basic standard/light/normal-text inspection only; SE/Dynamic Type enlarged/VoiceOver/appearance matrices outside routine, not requested/run. No equivalence pixel-perfect to inaccessible HTML asserted.

### Static/documentation consistency and delivery

Final Swift parse, Foundation-only Domain typecheck, project plutil, JSON/unique catalog keys, preservation of unrelated translations, git diff--check and approved spec hash pass; final-static.log records executed checks. Target registers moved sources/tests; no QuickWatering wrappers/callers or new schema/Plant/JPEG fields. No new operational constraints required; existing ADR008 temporal/actor contracts retained and ADR009 documents delta. ARCHITECTURE/DESIGN/domain/testing/risks/PROGRESS/feature_list updated; historical specs/ADR008/acceptance evidence untouched. Private config and DerivedData ignored. No active test/build processes at closure. No stage/commit/push/PR/merge/delegation/API/private configuration reads.

Next: parent launches independent validator, who runs **one** final `caffeinate -dius ./init.sh` on these final sources, checks parallel unit/UI and PhotosPicker serial bundles, reviews scenario/spec/architecture/docs/security and accepts or requests repair. Focused evidence/Release reusable after corroboration; do not repeat covered focal tests without concrete gap. Parent alone may persist accepted/authorized local commit. Chronology/last-watering/add-photo/delete remain separate future features, not implemented.
