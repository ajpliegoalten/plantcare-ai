# Independent validation — delete-care-event photo hit-testing

## Verdict: REVISE

H2 High — required final gate failed in care commit/dismissal regression. No static blocker specific to the new hit-region repair; all four new portrait UI cases pass. Parent must not persist this round accepted or commit acceptance yet.

Same feature/worktree/branch; accepted base commit `9db921d`. This is the user's explicit post-accept repair and extension to plant photographs, not a next feature. User reported that the second additional photo's trash did not act, then authorized auditing all photo surfaces while preserving clickable cells. User later confirmed manual checks correct: **reported human evidence**, not agent smoke or independent gate acceptance.

Approved spec `docs/specs/delete-care-event.md` remains byte-identical to HEAD SHA256 `f1c2930c28ba76771b69ce4257999b0f1152ee41e5b634178e6c60e072f2ae62`; original REVISE/V2 reports and historic Failed/Accepted gates preserved. Historic294 does not cover these new sources. Feature active_round remains passing until parent records this round accepted after independent verdict.

## Review / security / architecture

Diff is narrow Presentation hit geometry, opt-in Debug Simulator synthetic fixtures, persistent UI coverage and durable constraints/testing/handoff evidence. No ViewModel/Domain/product Data/storage/delete/identity/cache/pager selection contracts changed. Clean MVVM `Presentation → Domain ← Data` and composition are preserved. No dependencies/new screen/backend/API/secrets; scoped security checklist has no relevant blocking findings. Fixture stores require opt-in UUID from existing composition and use locally drawn synthetic JPEGs, not user stores or uploads. UI prints only synthetic button/image geometry, no private data.

All `Image(uiImage:)`/scaledToFill/scaledToFit/UIImageView sources searched: six actual renderers:

- Timeline: contentShape(Rectangle) applied **after** explicit crop frame; scaledToFill's visual clipping alone previously left overflow intercepting the trash header. Limits hit region without changing crop/layout/actions/initial protection. Tests use real center coordinates, loaded bitmap/frame/hittable/enabled preconditions, second visual photo, both cancel/confirm/delete and all5photo/care headers after scrolling.
- Card: shape on loaded bitmap after frame; enclosing NavigationLink's rectangular shape remains. No allowsHitTesting(false) on navigable content: photo and metadata whitespace both tested to correct plant UUID. Card retry remains outside link and active.
- Pager: shape on bitmap and page after frame/clipping; TabView selection/swipe gestures and external previous/next controls intact. Actual gesture starts on image, identities/edge enablement/crop4:3 checked, read-error/image retry covered by persistent regressions.
- Detail nil-pager fallback: Group frame/shape bounds image/loading/error only; separate retry unaffected. **Static source/build assessment only** of nil branch; real composition installs pager, no nil-runtime UI claim or invented coverage.
- PlantFormHeader: allowsHitTesting(false) only decorative already-accessibilityHidden thumbnail/placeholder, not HStack/text/form/controls. Shared Edit/Care/Add headers retain active fields, buttons and source controls.
- Shared PhotoSelectionPreview (Identification/Add): unchanged scaledToFit fits container; no overflow modifier needed, accessible preview/dimensions preserved. Additional portrait preview/source controls tested; no new focused identification/real-camera claim. Full gate covers normal existing identification and PhotosPicker separately.

No accessibility labels/values/IDs, ≥44 action assertions, retry/Native NavigationLink/TabView gestures disabled or tests removed. No matrices were requested/performed. Durable CONSTRAINTS adds precise clipping-vs-hit-bounds rule with interactive-parent exception; docs/testing-ui and handoff describe real new/reused evidence. ARCHITECTURE needs no new boundary/ADR because this repairs layout hit geometry, not architecture. Prior O(n)metadata/viewport/cache3/concurrency2/logical cleanup limits remain.

## Independent corroboration / verification

Final156 public input manifest `photo-audit/inputs-final.json` SHA256 `381423c7c4863cb9ad3839c2b8bcb3d5bb823dda7fe19cece9bbe4f97d369f85` matched every current file before gate. No secret config content read/hash/copy/overwrite, existence only. Static git diff--check/PBX plutil pass. No stage/commit/source repairs by validator.

39 selected distinct focused IDs independently matched Passed once in original xcresult trees: **15new=9UI+6unit;24reusedunit**. Provenance `photo-audit/selected-final-results.json`, original direct-portrait2, affected-regressions12, fixture-thumbnail1 and manual-hit/unit-callers25 (24 relevant reused, prior thumbnail excluded). No separate focused reruns. Fixture.plant/events/photo metadata unchanged, reused VM cases do not call altered fixture JPEG; thumbnail caller re-executed. Old manual trash2 methods executed again for changed pager, not counted twice; older timeline UI not attributed as new coverage. Historic diagnostics Failed, harness geometric correction and external timeout interruption remain in handoff, never aggregate approved.

Seven existing affected-screen PNGs actually opened by validator: photo-audit78E31D37(card),9B69B424(pager crop/controls),7F53A4B6(Edit field/keyboard),9BC58F04(additional preview/camera fallback/controls); manual-hitE61AD33F(second crop/adjacent headers),4DCD739C(native photo alert),9B0540BA(first/second separated headers). Earlier manual timeline captures reused only for unchanged timeline renderer/layout; no claim older full UI run validates changed card/pager. No new screenshot tests/capture matrix.

New **single original `caffeinate -dius ./init.sh`**, default5workers/screenshots0, required by executable photo renderer/fixture/UI changes; both parallel+Photos serial required. **FAILED exit65**, build-for-testing SUCCEEDED, parallel TEST EXECUTE FAILED. Original bundle `DerivedData/TestResults/20261013-094141-99745/parallel.xcresult`;09:41:44.001–09:57:33.688+0200 (2026-10-13). Original summary/tree/log corroborate296distinct once: **295Passed=221unit+74UI;1UIFailed**, zero skipped/expected failures. All11DeleteCareEventUITests including four new portrait scenarios and6PlantTimelineUITests pass. **Photos serial NOT executed** because set-e stops at parallel failure. No acceptance from partial results, user's manual confirmation or historic294. Original initPID99745 awaited kqueueNOTE_EXIT/completion notification, no polling/retries/iterations/second gate/focused reruns. No runner crash/RequestDenied/FBProcessExit marker found in current gate log (not a universal environment guarantee).

Before/after156 exact inputs, catalog8cdcf… unchanged; spec/original reports rechecked HEAD exact. No xcodebuild/xctest/simctl/XCTRunner process active at closure. Evidence `DerivedData/evidence/delete-care-event/validator-photo-hit/` command/preflight/devices/inputs/log/exit/corroboration. CLI fallback because available tools lack MCP, no tool configuration/permissions changes.

Fail-closed preflight: exact init algorithm selects Booted00BBB7EC-8DF7-400C-A08A-9D3C8818D886; read-only ui queries light/large(normal), no competitors xcodebuild/xctest/simctl/XCTRunner. iPhone17Pro/iOS26.2/23C54/Xcode26.2/17C52/macOS26.5.1/25F80. No other simulator/ProMax reset/settings manipulation, API real, expanded matrices, retries/iterations/timeouts-to-green or extra gate.

## Unrelated catalog / commit boundary

`PlantCareAI/Localizable.xcstrings` is unrelated, preserved without edit/revert/stage: current SHA256 `8cdcf42429d0664cf73eed1f0c92fd1d60d343a9c01fa286f429fc1654986dd8`. Parsed comparison vs HEAD: sourceLanguage/version unchanged, all202 existing keys and translation/localization content exact;18 entries gain extractionState=stale metadata, and a whitespace-only key `" "` with empty object is added. Formatting/extraction bookkeeping changes explain diff, no changed display translation. The source Text(" ") is already present in unchanged deletion accessible label; missing localization falls back to that same whitespace.

**Parent may exclude this unrelated catalog from the repair commit while preserving relevant runtime text/behavior evidence**, based on the explicit semantic assessment. The new gate runs CURRENT catalog bytes, not HEAD bytes: do not assert HEAD-byte test identity, compiled-resource byte identity or having run a second HEAD build. Exclusion relies on unchanged localization semantics for this repair, not fabricated executable-byte equivalence. Leave unrelated worktree catalog untouched and unstaged. A comparison script initially stripped extractionState asymmetrically and asserted incorrectly; corrected symmetrical comparison passes without changing files/repeating tests (recorded in catalog-assessment).

## Handoff / manual

Parent persists round accepted and authorized LOCAL repair commit only after accept, excluding unrelated catalog; no push/PR/merge, no new gate for docs/role only. Validator only new report/PROGRESS/evidence, no product/tests/spec/harness/feature status/Git deliverable edits.

Human confirmation is user-provided, no manual smoke by agent. Suggested optional smoke on consented fixture/duplicate: card photo AND metadata whitespace open correct detail; swipe pager portrait then previous/next; Edit/Care/Add header fields/source controls remain reachable; history two portrait photos→second trash Cancelar then fresh confirm, initial no trash, retain other cares/other plant and relaunch. No extra test required just for manual suggestion. Fallback nil UI/physical camera/iCloud/expanded accessibility matrices not executed, not unrequested blockers.


## H2 — Care busy sheet did not close after commit gesture

- Severity: **High**.
- Evidence: `CareEventsUITests/testBusyBlocksFieldsCancelAndGestureWithMissingPhoto()` failed **once41.478s**, `PlantCareAIUITests.swift:1764` expects `Registrar cuidado` navigation bar to disappear within10s. Original tree/details/activity JSON retained in validator-photo-hit evidence. Details confirms one run; no retries. Build/remaining295Passed are not a valid final gate; serial Photos uncovered.
- Observed: save tap1791877423.655, careSaving query1791877424.760 and existing1755busy spinner/1756–1759disabled-button assertions all pass. Native bar drag1791877426.044; wait-for-bar-absence1791877428.567 ends with failure1791877440.710. Test aborts before careConfirmation/persistence verify. Thus this is not missing initial busy state or demonstrated inability to select/save through the header. No post-save screenshot/state/payload proves commit/error/dismiss cause from these artifacts. Failure attachment export reports no matching attachments; activities have hierarchy titles but no attached hierarchy content exposed, no invented visual diagnosis.
- Why it matters: keeping controls/cancel/gesture safely protected during real commit and restored/dismissed after completion is a shared affected-form regression. A failed required gate blocks this round regardless of new portrait cases passing.
- Required change: determine whether commit completed/error or native gesture/dismiss transition remained blocked, and repair the demonstrated cause minimally; preserve exact busy/disabled/commit/confirmation/persistence assertions. Do not increase timeout/fixture delay, add retries or call it environment flake without evidence.
- Suggested diagnostic steps:
  1. Preserve original Failed bundle/current inputs/report. Run only failed case with focal screenshot/available synthetic state or lifecycle instrumentation, explicitly distinguishing `.saving → .saved/.error`, fixture dispatched/completed and native sheet dismissal around drag. Existing busy fixture sleeps12s; keep original duration/assertions and track timeline instead of stretching waits. No private data/API/settings/reset.
  2. Diagnose interaction of precommit-lock/state-onChange dismiss with native drag; alternatively validate error/save publication if state never resolves. The changed shared header only disables decorative placeholder hit-testing, not parent/actions; do not assume that modifier caused failure or revert it speculatively. Product CareEvents VM/writer are unchanged from accepted base.
  3. If test targets invalid timing/gesture observation, repair synchronization using explicit deterministic busy/completion signals without relaxing product contract. If real commit/dismiss state defect, repair the narrow lifecycle cause and protect other CareEvents/Add/Edit callers. A nonreproducing diagnostic cannot erase the old failure.
- Verification after fix: failed scenario first, then CareEvents busy/save/cancel and directly affected header/sheet callers; static checks and new manifest/handoff. New full independent gate only when executable repair invalidates this failed evidence, once on final inputs, both parallel+Photos serial. No iterations/retries/matrices for green.

## Implementation Repair Brief

Goal: diagnose/repair H2 and produce complete trustworthy final gate, retaining successful photo hit-region behavior.

Do:
1. Instrument/observe only the failed busy-care gesture case in the isolated synthetic UUID store (state/fixture completion/native dismissal); conserve original failure.
2. Repair the demonstrated narrow test synchronization or product lifecycle cause; preserve all busy, disabled, cancel/gesture, confirmation and disk-verification assertions and12s fixture.
3. Revalidate failed case plus affected care/header/modal regressions by impact; do not repeat unrelated focal suite. Publish new input manifest and handoff with actual results.
4. Return to validator for justified new single full gate after executable input change; both phases mandatory.

Do not: stage/commit/mark roundaccepted yet; edit original approved spec/reports/catalog, relax assertions/timeouts/retries, reset ProMax/other stores/settings, add adjacent feature work/API/matrices. Keep catalog unrelated and preserved. Update PROGRESS/handoff/feature evidence preserving histories. Parent commit LOCAL after later accept only; no push/PR/merge.
