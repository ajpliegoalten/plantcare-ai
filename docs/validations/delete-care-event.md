# Independent validation — delete-care-event

## Verdict: REVISE

One High verification finding (H1) prevents acceptance. No product/security defect is inferred solely from this gate failure. Parent must not persist accepted/commit acceptance yet.

## Review target / authority

Validator: `openai/gpt-6.1-sol`, feature-validator + local ios-clean-mvvm guide. Exclusive worktree `delete-care-event`, base `ac94624`, branch `feature/delete-care-event`. Current feature status `passing` means focused self-verification, not acceptance. Spec `docs/specs/delete-care-event.md` SHA256 `f1c2930c28ba76771b69ce4257999b0f1152ee41e5b634178e6c60e072f2ae62` independently verified byte-intact. Its historical BORRADOR/no-approval statements are superseded by the explicit integral approval in the parent context/PROGRESS; no edits to the contract.

## Review completed

- All 14 acceptance scenarios mapped to code and persistence/VM/UI tests. Separate care/additional snapshots, own plant membership, literal comparison and discriminated identities prevent cross-entity deletion. Domain rejects initial before dispatch; Data only deletes matching additional rows/canonical AdditionalPhotos references. No schema or Plant/CareSheet/cover changes.
- LocalPlantRepository actor: validation before mutation; synchronous delete/seam/save, rollback before success; photo metadata commits before best-effort JPEG cleanup. Reopen tests validate exact own/other metadata/JPEG, missing/corrupt images and global metadata validation before orphan cleanup. NotFound/conflict/readFailure do not masquerade as rollback or fabricated idempotent success.
- Presentation: native alert, explicit abandonment/retry snapshot, duplicate guard, no optimistic deletion/toast, protected back/gesture only during commit. Canonical callback once after commit; generation cancellation/deferred refresh rejects stale metadata. Retained real detail/card watering consumers invalidate only their plant; retained pager receives deletion while suspended, purges cache, preserves surviving selection or falls back to initial, then reconciles on return.
- Timeline photo purge removes demand/owners/queue/tokens/geometry/cache and rejects late read/decode. Cancelled work continues counting until drained: cache3/concurrency2 remain intact. VStack mounts lightweight metadata/frames O(n), not JPEG originals; viewport-only IO remains. This is a justified bounded repair of the observed LazyStack estimation loop, not a new scale/virtualization guarantee. Historical failed candidates/runner incidents remain in the handoff.
- Dependency direction `Presentation → Domain ← Data`, Foundation-only new Domain use cases/contracts, same actor composed after Debug overrides, weak callbacks/detail references; no Data adapters in feature views or new ContentView screen. Scope remains care/additional deletion, not plant deletion/analysis/network.
- Durable architecture/design/constraints/brief/domain/risks/testing docs and ADR012 reflect the approved behavior and tradeoff; old evidence explicitly remains historical. AGENTS/init unchanged. Other feature records compare exactly to HEAD. No new dependencies.
- Feature-scoped security checklist: no relevant blocking issues. Inputs are typed UUID/snapshots, Data validates canonical own references before the file sink, no path strings from Presentation, no new outbound calls/auth scope/secrets/logging. Explicit destructive confirmation and initial protection have negative tests. Logical deletion is not secure physical erasure/backups or multiprocess coordination.

## Verification evidence

New standard final gate: **FAILED exit65**, build-for-testing SUCCEEDED, parallel TEST EXECUTE FAILED. Original bundle `DerivedData/TestResults/20261013-025901-65540/parallel.xcresult`; parallel 2026-10-13 02:59:03.895–03:14:21.556+0200. Summary/tree/log corroborate **290 distinct cases once:289Passed=218unit+71UI,1unitFailed**, zero skipped/expected failures. All seven DeleteCareEventUITests and six PlantTimelineUITests passed. **Photos serial was NOT executed** because init exits on the failed parallel phase. No partial acceptance or inherited Photos result. Original initPID65540 awaited via kqueue NOTE_EXIT, no polling/relaunch/focused reruns/retries. Test-details explicitly confirms one run of the failed test; summary insight “7 runs” is not seven agent executions (tree contains seven timeout messages in that single run).

Before/after156 input hashes exact; spec intact. No xcodebuild/xctest/simctl/XCTRunner process remains at closure. No runner crash/RequestDenied/FBProcessExit marker found in the new gate log; this does not erase the historical related-regressions worker incident. Gallery completion is missing by gate failure, not reported as passed.

Command: `caffeinate -dius ./init.sh` (default5 workers, screenshots0), once on final156 public inputs. Evidence directory: `DerivedData/evidence/delete-care-event/validator/`, command/preflight/devices/inputs-before/gate.log/gate.exit. Ready manifest SHA256 `515d3aecd6f79188d26987b1de2e3aff3596c1d405d37d7850879771848b7a72`; every156 input independently matches. No secret config read/hashed/copied/overwritten; existing required ignored config checked for existence only. CLI fallback because catalog lacks XcodeBuildMCP; no tooling configuration changes.

Preflight fail-closed: no competing xcodebuild/xctest/simctl/XCTRunner; exact init selector/root Booted `00BBB7EC-8DF7-400C-A08A-9D3C8818D886` iPhone17Pro iOS26.2/23C54, Xcode26.2/17C52, macOS26.5.1/25F80. Read-only `simctl ui <root> appearance` returns `light`, `content_size` returns `large` (normal). No ProMax/other-device manipulation, expanded matrices, retries/iterations or focused reruns. The earlier setter timeout is preserved, not attributed as successful.

Reused focused evidence independently corroborated: all108 selected IDs =92unit+16UI individually matched exactly once with Passed in their original xcresult trees (unit1/2/3/4, ui8, pager-visible-final, visual-regressions, related-regressions). Reuse is per final selected mapping/input impact, not aggregate old builds attributed to new sources. related-regressions RequestDenied/FBProcessExit64 worker incident remains historical, not claimed runner-error-free. The new full gate must stand on its own.

Static new checks pass: git diff--check, PBX plutil, bash syntax, JSON unique keys, original localization entries exact. Existing final Release binary independently checked with nm/strings for absence of HistoryDeletionTestFixture/--deletion-fixture/PlantTimelineFixtureLoad and Info IdentificationAPI keys; no Release rebuild or private settings inspection.

Ten existing final affected-screen PNGs actually opened independently, no capture/test rerun: ui8 E596C9… care alert,62C2AB… photo alert,0D07AA… care error,B43557… photo error,124198… busy/back hidden,9DFF96… only initial/no trash; pager-final439644… loaded initial fallback and32B292… surviving additional/caption2de8; visual-regressions069D9C… stress bottom and7C4EDF… full-note endpoint/prealta footer. They show native confirmation, differentiated intact-data errors, reachable controls, protected origin and actual pager bitmaps. Implementer's14 opened PNG claim is not represented as fourteen newly opened by validator.

## Handoff / manual smoke suggestion

No human smoke outside XCTest performed by this validator; instrumental persistent UI coverage and actual screenshot inspection are distinct. Suggested user smoke: open A→historial; cancel care and additional deletion, then confirm a fresh intent; ensure initial has no trash. Delete latest/last watering and return to retained detail/card; check remaining maximum/absence. Delete selected and nonselected additional photos, return to pager (initial fallback/surviving identity), relaunch without reseed, compare B. No API real required.

Status remains passing; only parent persists accepted after final accept and authorized LOCAL commit. No validator source/test/spec/harness/status/stage/commit/GitHub edits. No push/PR/merge. Expanded matrices/physical camera/iCloud are outside routine, not unrequested acceptance blockers. Residual limits: metadata hierarchy O(n), original-media memory not constant, single writer/store, logical best-effort cleanup and no guaranteed backup/physical recovery.


## H1 — Loader regression failed; complete final gate unavailable

- Severity: **High**.
- Evidence: `PlantTimelinePhotoViewModelTests/testDemandDedupTwoInFlightBoundedLRUFailureRetryOwnIdentityAndNoReloadLoop()` failed once in the original final bundle (20.734s). Tree points to wait timeout line52, line72 `failed != loaded`, missing requests3/4/5 at303, waitCount timeout307, cache2 !=3 at78, failed !=idle at79, count4 !=5 at80. Details/summary/tree retained under validator evidence.
- Why it matters: cache3/concurrency2, own failure/retry and no hot-loop are directly supporting preserved feature requirements; a failed full gate cannot be accepted, and serial Photos is uncovered in this final state.
- Required change: diagnose the exact failed scenario and repair the actual defect or nondeterministic test boundary without weakening image identity/cache/concurrency/retry assertions, deleting coverage or increasing retries/timeouts for green.
- Concrete diagnostic hypothesis (not confirmed root cause): `TimelineImageGate.read(_ id)` ignores the supplied identity and appends continuations by arrival order. Test starts two asynchronous read tasks and assumes `finish(0)` is values[0], `finish(1)` values[1]. Arrival order is not guaranteed; the observed values[0] failed at72 while the wait for values[1] failure timed out is consistent with those first arrivals swapping. Loader schedules tasks in order, but that does not establish actor-read arrival order. This is stronger evidence than generic “simulator flake”; do not reset devices or change product spec based on it.
- Suggested implementation:
  1. Preserve the FAILED bundle/report, current source manifest and single-run failure. Run only this case for a stated identity-order diagnostic; instrument the synthetic gate to record identity/request token (no private payloads/network). A nonreproducing diagnostic does not invalidate the original failure or count as final gate acceptance.
  2. If confirmed, make gate completions identity-addressed/token-addressed with explicit registration waits, or synchronize first identity registration before issuing the second, preserving the simultaneous two-in-flight assertion. Fail closed on unknown/double completion and preserve cancellation continuations. Do not constrain production asynchronous order to satisfy numeric test indexing.
  3. Audit other TimelineImageGate callers, especially newly added purge/decode/draining scenarios, for the same arrival-index assumptions; repair only affected boundaries. If identity evidence contradicts the hypothesis, diagnose state/token/running transition first instead of applying speculative product fixes.
- Verification after fix: build as needed; first run failed case plus complete PlantTimelinePhotoViewModelTests affected class (same standard root/destination), add deterministic reordered-arrival evidence where appropriate. Preserve all failed historical evidence. After any executable test/product fix invalidates this gate's input state, hand off final inputs and focused results to independent validator for a justified **new single full `caffeinate -dius ./init.sh`** covering both parallel and Photos serial. No retries/iterations/extra matrices.

## Implementation Repair Brief

Goal: restore trustworthy deterministic loader regression and a valid complete final gate.

Do:
1. Diagnose H1 with identity/continuation mapping in the synthetic TimelineImageGate; start from only failed test and stated arrival-order hypothesis.
2. Repair confirmed test seam ordering or real loader defect minimally; maintain exact cache3/concurrency2/own retry/no reload-loop assertions and all persistent UI coverage.
3. Audit/revalidate affected gate callers and loader class, including purge/cache/read/decode/draining/viewport/session cases.
4. Update handoff/PROGRESS with exact commands, outputs, new final input manifest and preserved FAILED gate; return for independent final gate after relevant input change.

Do not: change approved spec bytes, loosen assertions/timeouts, add retries, delete tests, change simulator settings/reset unrelated devices, implement adjacent features, stage/commit/push/PR/merge or mark accepted.

Run: focused `-only-testing:PlantCareAITests/PlantTimelinePhotoViewModelTests/testDemandDedupTwoInFlightBoundedLRUFailureRetryOwnIdentityAndNoReloadLoop`, then affected class using the same project/scheme/standard UDID and final products. Validator subsequently owns justified new full gate (both phases).

Update: `docs/handoffs/delete-care-event.md`, `PROGRESS.md`, feature evidence while retaining passing as self-verification only; preserve this report and original Failed artifacts. Parent may commit LOCAL only after later independent accept. No acceptance repair implemented by this validator.
