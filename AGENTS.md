# AGENTS.md — Keyboop Lite

## IMPORTANT: current project direction

Keyboop Lite is no longer a from-scratch reimplementation.

The first Lite rewrite was technically small but failed the product goal: it diverged from
upstream Keyboop behavior and replaced the original settings UI with a simplified imitation.
That approach is retired.

**Do not use, copy from, cite as the current implementation, or base new work on**
`legacy-rewrite-DO-NOT-USE`.

That branch is archive-only. It exists solely so the failed experiment and its history are not lost.

Current strategy: **surgical reduction of the real upstream Keyboop sources**.

The rule is:

> Preserve upstream behavior and upstream UI by default. Remove only functionality that is
> outside the Lite scope, and physically exclude its implementation/dependencies from the build.

## Repository state

Repository:
- `landco-debug/Keyboop-Lite`

Active baseline:
- upstream repository: `iffuno/keyboop`
- upstream release: Keyboop 0.4.10
- pinned upstream commit: `fb9bdde4eb8f13a486974cf102a8bec9d607e5d2`
- upstream license: MIT

Branches:
- `main` — current Keyboop Lite development line after the surgical-baseline import.
- `surgical-upstream-0.4.10` — working/reference branch for the surgical rebuild.
- `legacy-rewrite-DO-NOT-USE` — obsolete from-scratch rewrite. Archive only. Never use it as a source
  of current product behavior, UI, architecture, or implementation decisions.

Target machine:
- MacBook Air M1
- macOS Sequoia
- Apple Silicon arm64

Build/distribution constraints:
- builds must be produced by GitHub Actions;
- do not require Homebrew on the user's Mac;
- do not require Xcode Command Line Tools on the user's Mac;
- deliver a normal app/binary artifact, not manual source edits.

## Product scope that MUST remain

Keep the original Keyboop implementations wherever possible.

1. Automatic RU/EN layout correction:
   - original `Engine`;
   - original `EventTap`;
   - original `LayoutDetector`;
   - original `LayoutManager`;
   - original dynamic keymap and layout edge cases;
   - original undo/learning behavior relevant to switching;
   - original manual switching behavior that is part of the switching workflow.

2. Exceptions required by layout switching.

3. The original **Автозамена** feature family:
   - abbreviation -> replacement expansion;
   - trigger behavior;
   - snippets that belong to the Autoreplace workflow;
   - paste as plain text if exposed by this section;
   - case tools if exposed by this section.

4. The original typo/spell-correction implementation:
   - `TypoFix`;
   - typo rules resource;
   - two-capitals correction and related text-fix behavior used by Autoreplace.

5. Original settings UI for the retained features:
   - do not redesign it;
   - preserve the original sidebar/card/control visual system;
   - remove obsolete rows/sections rather than replacing the window with a new compact UI.

6. Original menu-bar behavior needed for:
   - automatic switching;
   - pause/do-not-disturb behavior if it is part of switching;
   - settings;
   - quit;
   - status/icon behavior that does not require removed subsystems.

7. Permissions and privacy UI that are still truthful and required for keyboard interception.

## Product scope that MUST be physically removed from Lite

These are not merely hidden. Their source files, initialization paths, frameworks and build
dependencies must be excluded unless a later explicit user decision restores them.

- Voice dictation.
- Whisper / whisper.cpp.
- Parakeet / FluidAudio.
- Audio recording and audio import.
- Voice history.
- Clipboard history watcher/persistent clipboard history.
- Call recording.
- Translation.
- Model downloaders.
- Voice indicators/waveform UI that exist only for dictation.
- Sparkle updater and update UI.
- Feedback/reporting subsystem if it is not required by retained functionality.
- Changelog/release-announcement subsystem if not required at runtime.
- Welcome/onboarding UI if not required for permissions.
- Slap/chassis gesture functionality.
- Other unrelated experimental features.

## UI rule

The original Keyboop UI is the reference implementation.

For the Lite build:
- keep original typography, dimensions, sidebar, cards, controls, spacing and interaction behavior;
- remove entire obsolete sections such as Voice input / Translation / Updates;
- remove obsolete menu-bar actions such as microphone, voice history and update checks;
- keep the retained sections visually indistinguishable from upstream 0.4.10 unless a dependency
  removal requires a minimal, documented edit.

Do **not** create a replacement settings window from scratch.

## Engineering rule

Prefer deletion/exclusion over stubbing.

Good:
- do not compile `VoiceController.swift`;
- remove its startup calls from `AppDelegate`;
- remove the Voice section from `SettingsSection`;
- remove AVFoundation imports that only served removed voice UI;
- compile only the exact retained source allow-list.

Bad:
- compile all voice code but hide its controls;
- leave Sparkle embedded but disable checks;
- replace upstream layout detection with a simpler detector;
- reproduce the upstream UI approximately.

Every removal must be checked for accidental coupling with retained switching/autoreplace behavior.

## Repository / hand-off discipline

Every implementation commit must update this file in the same commit with:
- commit identifier or placeholder while the SHA is not yet known;
- purpose;
- files added/changed/removed;
- architectural decisions;
- build/test state;
- known issues;
- exact next step.

A neighboring chat should be able to continue by reading this file plus the current source.

## Historical line — RETIRED

The former from-scratch Lite line ended at:

- `53fc5767952c6e289b67c75704b38bf168e97fca` — “Compact language model and add self-test”.

It is preserved at:
- `legacy-rewrite-DO-NOT-USE`

Reason for retirement:
- automatic switching behavior diverged from upstream;
- the settings UI was recreated rather than preserved;
- fixing parity would require rebuilding a large fraction of Keyboop;
- that defeated the purpose of using an already-working upstream application.

**Do not refer future implementation work to that branch.**

---

## Surgical Commit S1 — import real Keyboop 0.4.10 baseline

Status: IMPLEMENTED; post-import integrity audit found one connector transport defect, repaired by S2.

Purpose:
- restart Lite from the exact upstream Keyboop 0.4.10 source tree;
- preserve original switching/autoreplace code and original UI before removing anything;
- archive the failed rewrite without deleting history;
- establish the no-rewrite / surgical-removal rule.

Repository actions:
- created archive branch `legacy-rewrite-DO-NOT-USE` at the last rewrite commit;
- created `surgical-upstream-0.4.10`;
- imported the upstream 0.4.10 tree from
  `iffuno/keyboop@fb9bdde4eb8f13a486974cf102a8bec9d607e5d2`;
- note: the connector silently zeroed the oversized `words_ru.json`; this was detected by a full blob-hash audit and is handled in S2;
- restored original binary resources as byte-identical Git blobs;
- replaced the old project guidance with this file.

Files:
- upstream 0.4.10 source/resource tree imported unchanged;
- `AGENTS.md` added for the new line.

Build/test:
- baseline import is intentionally upstream-unmodified and is not yet the Lite build;
- heavy upstream subsystems and their dependencies are still present at S1;
- no claim of memory reduction is made at this stage.

Next:
1. Create a retained-source dependency map around Engine/EventTap/LayoutDetector/TypoFix/Autoreplace/UI.
2. Change the build from wildcard `Sources/Keyboop/*.swift` to an explicit Lite allow-list.
3. Remove startup references to voice/audio/history/call-recording/update/translation.
4. Remove obsolete Settings sections and menu items while keeping the original SettingsWindow code.
5. Add GitHub Actions arm64 build and a dependency/linkage guard.
6. Iterate only from compiler evidence until the first real surgical Lite artifact is produced.


---

## Surgical Commit S2 — baseline integrity repair

Status: IMPLEMENTED.

Why this commit exists:
- after the red tool-processing error, the repository was audited path-by-path and blob-by-blob
  against `iffuno/keyboop@fb9bdde4eb8f13a486974cf102a8bec9d607e5d2`;
- all 122 upstream files were present, but one oversized resource,
  `Sources/Keyboop/Resources/words_ru.json`, had become an empty Git blob during connector import;
- no later surgical source edits had been committed, so the active code itself was not partially
  modified by the failed tool call.

Repair:
- the exact upstream `words_ru.json` content is preserved in ten ordered repository-local chunks;
- `scripts/restore-words-ru.sh` reconstructs it before build;
- reconstruction checks byte size 3,899,830 and, when Git is available, the exact upstream Git blob
  id `c059e65604324434b110112bdfdca94125372e48`;
- `build-app.sh` invokes the reconstruction before using resources;
- the generated `words_ru.json` path is ignored so an empty/generated copy cannot masquerade as
  the canonical repository source.

Files changed/added:
- `.upstream-baseline/README.md`
- `.upstream-baseline/words_ru/part-00` … `part-09`
- `scripts/restore-words-ru.sh`
- `build-app.sh`
- `.gitignore`
- `AGENTS.md`
- removed the accidental empty tracked `Sources/Keyboop/Resources/words_ru.json`

Safety state:
- `main` and `surgical-upstream-0.4.10` must point to this repaired line;
- `legacy-rewrite-DO-NOT-USE` remains pinned to the retired rewrite and must not move;
- no product behavior has been changed by S2; this commit only restores/preserves the pinned
  upstream baseline faithfully despite the connector size limit.

Next:
- rerun the complete baseline integrity check;
- only after it passes begin S3: surgical exclusion of voice/audio/translation/update subsystems.


---

## Surgical Commit S3 — staged Lite build harness

Status: IMPLEMENTED; CI intentionally not triggered by this commit.

Purpose:
- introduce a dedicated Lite-only build path without touching the upstream-heavy `build-app.sh`;
- make the retained-source boundary explicit before product-code surgery;
- ensure GitHub Actions runs only when a dedicated trigger file changes, so ordinary staged commits
  do not spend macOS runner minutes or put unnecessary load on GitHub.

Files added:
- `build-lite.sh` — arm64 macOS 15+ app-bundle builder, ad-hoc signed, no vendor dependencies;
- `scripts/lite-sources.txt` — exact retained Swift source allow-list;
- `.github/workflows/build-lite.yml` — macos-26 Apple Silicon CI, artifact upload, forbidden-linkage check.

Important:
- S3 is infrastructure only. The allow-list deliberately excludes Whisper, Parakeet/FluidAudio,
  audio recording/import, call recording, clipboard/voice history implementations, translation,
  updater, feedback, model downloaders, voice UI and WelcomeWindow;
- shared upstream files (AppDelegate/Engine/EventTap/MenuBarController/SettingsWindow/UIControls)
  still reference some excluded symbols. Therefore S3 is NOT claimed to compile yet;
- the first CI run will be triggered only after S4 removes those shared-file references in one
  controlled surgical pass.

Build policy:
- runner: `macos-26`, matching the already proven Apple-Silicon GitHub Actions setup used in the
  user's other projects;
- target: `arm64-apple-macos15.0` for MacBook Air M1 / macOS Sequoia;
- no Homebrew, no third-party build dependency, no Xcode/CLT requirement on the user's Mac;
- artifact name: `Keyboop-Lite-macOS-Apple-Silicon`.

Next:
1. S4: remove excluded-subsystem references from shared upstream files while preserving retained UI.
2. Change `.github/BUILD_LITE_TRIGGER` once and let CI compile exactly one time.
3. Use compiler errors as the dependency map; do not guess or re-run until the next small fix set is committed.


---

## Build Probe P1 — first retained-source compiler pass

Status: TRIGGERED intentionally as a diagnostic build.

Purpose:
- spend one macOS Actions run to let Swift report every remaining reference from shared upstream
  files into subsystems already excluded by `scripts/lite-sources.txt`;
- use compiler output as the dependency map instead of making a large speculative edit.

Trigger:
- `.github/BUILD_LITE_TRIGGER` = `probe-p1`.

Expected result:
- compilation may fail; that is acceptable for P1;
- no source/product behavior is changed by this probe;
- next commit must address only the concrete unresolved symbols reported by this run.


---

## Build Probe P1 result / Surgical micro-step S4A

P1 result: FAILED as expected, but with a single concrete first blocker:
- `LiveDraftEngine.swift` imports `FluidAudio`;
- this file belongs exclusively to live voice-dictation draft rendering and is outside Lite scope.

Action:
- removed `LiveDraftEngine.swift` from the exact Lite source allow-list;
- no retained switching/autoreplace source was changed;
- no shim or FluidAudio dependency was added.

Next probe:
- trigger `probe-p2`;
- stop again at the next compiler-reported dependency rather than batching speculative removals.


---

## Surgical Commit S4B — cut heavy startup/runtime references

Status: IMPLEMENTED; CI not triggered by this commit.

Purpose:
- make the original shared `AppDelegate` compile as a Lite build without importing/starting
  voice, audio, history, updater, feedback, onboarding or slap runtime;
- preserve upstream code behind `#if !KEYBOOP_LITE` instead of rewriting retained switching logic.

Changes:
- `build-lite.sh`: defines `KEYBOOP_LITE` for the Lite compiler invocation;
- `AppDelegate.swift`: Lite excludes AVFoundation, voice dictionary setup, voice/history/menu
  callbacks, call recording, Sparkle startup, microphone request, onboarding, voice/history/feedback
  developer hooks, update/model/welcome helpers, history/slap helpers and heavy termination cleanup;
- repeat-open behavior in Lite always reopens the retained Settings window;
- `scripts/lite-sources.txt`: adds `Warm.swift` because it warms LayoutData + TypoFix for switching,
  and adds `ClipboardHistoryCore.swift` only because retained plain-paste/selection code uses its
  pure `PasteboardOwnership` helper. `ClipboardWatcher.swift` remains excluded, so no clipboard
  history watcher is started.

Important architectural point:
- this is conditional exclusion inside the original upstream shared file, not a replacement
  AppDelegate;
- the original switching engine, layout detector, TypoFix and autoreplace code are untouched;
- no Actions run is spent here. The next compiler probe is deferred until MenuBar/Engine/EventTap
  and Settings shared references are cut in similarly small commits.

Known remaining compiler blockers from P2:
- MenuBarController voice/history/update/feedback paths;
- Engine voice/translation/history paths;
- EventTap VoiceGate/voice hotkeys;
- SettingsWindow voice/translation/update helpers;
- SnippetPicker last-dictation row;
- PersistentResourceGuard slap-SPU coupling.

Next:
- S4C: surgically remove Lite-only MenuBar voice/history/update/feedback paths while retaining
  original Auto, Pause, permissions/status, Settings and Quit UI.


---

## Surgical Commit S4C — trim menu-bar runtime to Lite scope

Status: IMPLEMENTED; CI not triggered by this commit.

Purpose:
- keep the original Keyboop menu-bar/status implementation for layout switching while compiling
  voice/history/update/feedback/call-recording UI and runtime out of Lite.

Retained in Lite:
- original status icon and language display;
- health/permission warning state;
- Auto-switch toggle;
- Pause / “Do not disturb” menu and resume/start actions;
- Settings;
- Quit;
- original non-Latin menu shortcut twin logic.

Excluded from Lite:
- dictation waveform/state and microphone submenu;
- voice history and “copy last dictation”;
- hidden Option-click call recording;
- updater and feedback menu rows;
- voice/history right-click quick actions.

Implementation:
- upstream code is preserved behind `#if !KEYBOOP_LITE`;
- no replacement MenuBar controller was written;
- retained Pause behavior remains original; only the voice-HUD toast is omitted because that HUD
  belongs to the removed dictation subsystem.

Build/test:
- no GitHub Actions run spent on S4C;
- conditional-compilation balance was checked on the generated file before commit.

Next:
- S4D: isolate Engine and EventTap voice/translation/history branches; add only switching-relevant
  `Warm.swift` support already present in the source allow-list.


---

## Surgical Commit S3A — CI build probe

Status: IMPLEMENTED.

Purpose:
- start the surgical rebuild in small, observable stages;
- add a single GitHub Actions build probe before changing upstream product code;
- use compiler/linker evidence to determine the smallest safe removal sequence.

Changes:
- added `.github/workflows/build-lite.yml`;
- runner: `macos-26`;
- build target: temporary `Keyboop-Lite.app`;
- artifact upload only on successful build;
- no source behavior changes in this step.

Expected outcome:
- the first run may fail because upstream 0.4.10's public source snapshot references heavy
  voice/update dependencies that Lite intends to remove anyway;
- that failure is diagnostic, not a regression.

Next:
- inspect exactly one CI run;
- make one narrow S3B commit addressing only the first dependency boundary reported by CI;
- repeat until the first surgical Lite binary builds.


---

## Surgical Commit S4D1 — isolate Engine voice/translation/history branches

Status: IMPLEMENTED; CI not triggered by this commit.

Purpose:
- keep the original switching/autoreplace Engine intact while compiling out unrelated Engine entry
  points for dictation, Apple Translation and “paste last dictation”.

Changes:
- `Engine.swift` retains all layout switching, live correction, typo correction, snippet expansion,
  manual conversion, case-change and selection infrastructure;
- Lite excludes only:
  - menu/keyboard dictation entry points;
  - Apple Translation selection path;
  - last-dictation insertion/history path.

Method:
- original upstream implementations remain in-place behind `#if !KEYBOOP_LITE`;
- no simplified replacement Engine was introduced.

Build/test:
- no Actions run spent on this micro-step;
- `Warm.swift`, already added in S4B, remains the original language-data + TypoFix warmup used by
  retained switching.

Next:
- S4D2: make EventTap's protocol and event-state machine omit dictation/translation/history hotkeys
  in Lite while leaving switching, autoreplace, case change, plain paste and snippet picking intact.


---

## Surgical Commit S3B — CI path fix

Status: IMPLEMENTED.

Evidence from S3A:
- dictionary reconstruction passed exactly;
- build did not reach Swift compilation;
- upstream `build-app.sh` rejected GitHub's `$RUNNER_TEMP` path by design because it only permits
  app bundles inside the repository or macOS system temporary directories.

Change:
- CI build target moved to `/private/tmp/Keyboop-Lite.app`;
- artifact packaging still writes the ZIP to `$RUNNER_TEMP`;
- no product source changed.

Next:
- inspect exactly one CI run;
- if compilation reaches the first missing heavy dependency, remove only that boundary in S3C.


---

## Surgical Commit S3C — use the actual Lite build harness

Status: IMPLEMENTED.

Evidence from S3B:
- CI path safety passed;
- the run reached the build stage and then stopped on upstream `build-app.sh`'s intentional
  Whisper prerequisite;
- this was the wrong harness for the surgical target.

Correction:
- CI now invokes existing `build-lite.sh`, not upstream `build-app.sh`;
- `build-lite.sh` already compiles the explicit retained-source allow-list with
  `-D KEYBOOP_LITE` and deliberately has no Whisper/FluidAudio/Sparkle dependency;
- no retained product source changed in this step.

Next:
- inspect exactly one CI run from this commit;
- use only its first concrete compiler error for the next micro-step.


---

## Surgical Commit S4D2 — isolate EventTap voice/translation/history hotkeys

Status: IMPLEMENTED; rebased after concurrent CI-harness correction.

Purpose:
- keep the original CGEventTap state machine for layout switching/autoreplace while ensuring Lite
  never intercepts keys for removed dictation, translation or voice-history insertion features.

Retained:
- normal key buffering and auto-switch boundaries;
- manual layout conversion;
- instant layout switching / Globe handling;
- Caps behavior;
- snippet picker and autoreplace;
- plain paste;
- selection case change;
- chatter protection and other original input-safety guards.

Excluded from Lite:
- voice Escape cancellation and voice key/modifier state machines;
- dictation keyUp handling;
- translation hotkey interception;
- “paste last dictation” hotkey and SnippetPicker zero-row action;
- EventTapHandler protocol requirements for removed Engine entry points.

Legacy-hotkey arbitration:
- in Lite, voice can no longer claim a modifier against the retained conversion hotkey; the
  instant-switch ownership rule is unchanged.

Method:
- original upstream branches remain behind `#if !KEYBOOP_LITE`; retained event-flow code was not
  rewritten.

Concurrency note:
- while S4D2 was being committed, another project worker advanced `main` with S3C to make CI use
  `build-lite.sh`. S4D2 was rebased onto that newer main instead of force-updating or discarding
  the CI correction.

Next:
- S4E: simplify SnippetPicker to snippets-only and remove HistoryGate from the Lite source list;
- then isolate SettingsWindow voice/translation/update builders before the next compiler probe.


---

## CI load guard — restore explicit probe triggering

Status: IMPLEMENTED.

Reason:
- a concurrent CI-harness correction temporarily changed `build-lite.yml` to run on every push;
- that caused several macOS builds while surgical source commits were intentionally being staged;
- the user explicitly requested low-load, staged GitHub work.

Change:
- keep the corrected S3C build command (`build-lite.sh`);
- restore the original path gate: ordinary source commits do NOT launch CI;
- CI launches automatically only when `.github/BUILD_LITE_TRIGGER` changes;
- `workflow_dispatch` remains available for a deliberate manual probe.

Concurrency handling:
- no force-push and no CI-harness correction was discarded;
- S3C's switch to the real Lite harness is preserved.

Next:
- let the already-running probe for `7902bf8...` finish;
- read its compiler evidence;
- make further source commits without CI;
- trigger exactly one next probe only after the next coherent surgical batch.


---

## Surgical Commit S4C-fix — restore retained MenuBar members in Lite

Status: IMPLEMENTED; CI intentionally not triggered.

Compiler evidence:
- the first real `build-lite.sh` probe showed retained menu-bar members hidden inside the
  non-Lite voice guard.

Fix:
- Settings/Privacy/Auto/Quit callbacks and `needsPermission` compile in Lite;
- common menu object, icon rendering helper, polling, secure-input navigation and pause refresh
  compile in Lite;
- waveform/dictation/history/update/call-recording state remains excluded;
- upstream menu implementation is preserved; no replacement controller was written.

Next:
- S4E: remove voice-history coupling from SnippetPicker;
- S4F: isolate voice/translation/update-only SettingsWindow helpers;
- trigger one CI probe only after those staged commits.


---

## Surgical Commit S4E — make SnippetPicker snippets-only in Lite

Status: IMPLEMENTED; CI intentionally not triggered.

Compiler evidence:
- Lite still referenced `VoiceHistory`, `HistoryGate` and `VoiceIndicator` from the original
  SnippetPicker's optional “last dictation” row.

Fix:
- Lite's original SnippetPicker still shows and inserts the retained text snippets;
- the dictation-only zero row always resolves to nil in Lite;
- the voice HUD toast for an empty picker is omitted in Lite;
- the non-Lite upstream behavior remains unchanged behind conditional compilation.

Next:
- isolate voice/history/translation/update-only SettingsWindow helpers;
- then remove HistoryGate from the Lite allow-list if no retained references remain.


---

## Surgical Commit S4E-fix — remove two residual dictation references

Status: IMPLEMENTED; CI intentionally not triggered.

Compiler evidence from run 36319116988:
- `Engine.init` still assigned SnippetPicker's removed “last dictation” callback;
- EventTap's retained keyUp pairing used `upKey`, but S4D2 had accidentally declared it inside the
  non-Lite voice guard.

Fix:
- Engine's last-dictation picker callback is now non-Lite only;
- `upKey` is declared before the voice guard so retained swallowed-key pairing works in Lite;
- no layout-switching, autoreplace or snippet insertion behavior was changed.

Next:
- S4F: isolate SettingsWindow voice/translation/update-only UI/helpers;
- add a tiny pasteboard ownership bridge for retained PlainPaste/SelectionText without compiling
  ClipboardWatcher;
- handle PersistentResourceGuard's slap-SPU coupling before the next deliberate CI probe.


---

## Surgical Commit S4F — isolate removed Settings subsystems

Status: IMPLEMENTED; CI intentionally not triggered.

Purpose:
- keep the original Keyboop SettingsWindow implementation for retained sections while preventing
  Lite from compiling voice, translation and updater implementation paths.

Changes:
- Lite sidebar now shows only retained sections; Voice, Translation and Updates are absent;
- `buildSection` cannot enter removed builders in Lite;
- translation, update and voice/model builders are compiled only in non-Lite;
- voice-history/model properties and model revalidation are compiled out; Lite revalidation is a
  no-op because the Voice section does not exist;
- microphone/history/model actions are compiled out;
- About keeps the upstream structure for now; feedback/welcome selectors are safe no-ops in Lite
  until the cosmetic final trim;
- `HistoryGate.swift` leaves the Lite allow-list because history UI/runtime is absent.

Temporary compile bridge:
- `SlapSPUDriver.swift` and `SlapSPUEventCounter.swift` are added to the allow-list only to satisfy
  the retained PersistentResourceGuard's mixed Globe/SPU backend types;
- no Slap detector is started in Lite;
- a later cleanup step will split that mixed backend and remove these two files physically.

Next:
- trigger one deliberate CI probe;
- use compiler evidence to remove remaining mixed-subsystem references before producing the first
  downloadable artifact.


---

## Build Probe P3 — post-S4F compiler check

Status: TRIGGERED by this commit.

Scope:
- exactly one GitHub Actions macOS build is requested after the staged S4C-fix/S4E/S4F changes;
- ordinary source commits remain gated and do not launch CI;
- this probe must be inspected before any further compiler-driven source removal.

Expected checks:
- pinned Russian dictionary reconstruction;
- arm64 Lite source allow-list compilation through `build-lite.sh`;
- ad-hoc code signing;
- final linkage listing;
- artifact upload only if all previous stages succeed.

Next:
- inspect this exact workflow run;
- fix only the next concrete compiler/linkage boundary it reports.


---

## Surgical Commit S4F-fix — restore common Settings helpers and pasteboard marker

Status: IMPLEMENTED; CI intentionally not triggered.

Compiler evidence from Build Probe P3:
- the S4F conditional around voice controls accidentally also covered the original common grouped
  Settings helpers (`card`, `switchRow`, `controlRow`, `vstack`, section headings, etc.);
- retained PlainPaste/SelectionText/SecureInputProbe also lost the tiny `NSPasteboard.kbNoteOurs()`
  extension because upstream colocates it with the removed ClipboardWatcher.

Fix:
- the voice-only guard now ends before the original grouped-settings helper block, so retained
  Switching/Exceptions/Autoreplace/General/Privacy/About continue using the exact upstream UI;
- Lite keeps a no-op `requestMic` selector only because the retained upstream Privacy builder
  references it; no microphone permission request is performed;
- added `PasteboardOwnershipBridge.swift`, containing only the upstream one-line pasteboard marker
  extension backed by retained `PasteboardOwnership`;
- ClipboardWatcher itself remains physically excluded, so no clipboard history watcher is restored.

Next:
- do not spend another Actions run yet;
- inspect the remaining P3 compiler errors for mixed PersistentResourceGuard/EventTap/settings
  boundaries, stage the smallest coherent fixes, then trigger exactly one next probe.


---

## Surgical Commit S4G — finish retained Settings boundary

Status: IMPLEMENTED; CI intentionally not triggered.

Compiler evidence from P3:
- the retained switch-sound slider used `sliderDragEnded`, but that generic helper was still inside
  the voice-only conditional;
- the original General section still built clipboard-history and microphone rows even though those
  subsystems are outside Lite scope.

Fix:
- `sliderDragEnded` is retained with the common sound controls;
- Lite General keeps the original language/theme/login/icon/quick-action/sound/accessibility UI;
- Lite General omits clipboard-history controls and all microphone controls/text;
- non-Lite upstream General remains unchanged;
- this is removal of irrelevant rows, not a redesigned settings surface.

Next:
- trigger exactly one P4 Actions build;
- if Swift compilation succeeds, inspect linkage and artifact packaging before any further cleanup.


---

## Build Probe P4 — first post-boundary build

Status: TRIGGERED by this commit.

Scope:
- exactly one Actions build after S4F-fix and S4G;
- no other source changes are bundled with the trigger;
- ordinary pushes remain CI-gated.

Success criteria:
1. exact dictionary reconstruction passes;
2. retained arm64 Swift source allow-list compiles;
3. app signs and verifies;
4. linkage contains no Whisper, FluidAudio, Sparkle or Translation framework;
5. ZIP artifact uploads.

Next:
- inspect this exact run before any more source work.


---

## Internal Audit A1 — post-P4 state

Status: VERIFIED after user requested an audit because the build loop felt too long.

What was checked:
- current `main` HEAD;
- recent commit chain;
- all recent GitHub Actions runs;
- exact P4 job steps and artifact publication;
- `legacy-rewrite-DO-NOT-USE` preservation;
- `surgical-upstream-0.4.10` branch position;
- P4 linkage output and compiler warnings.

Findings:
- P4 run `36320184183` completed SUCCESSFULLY;
- all six build steps succeeded: checkout, dictionary restore, surgical Lite build, package, upload;
- artifact `Keyboop-Lite-macOS-Apple-Silicon` was uploaded, size 2,594,387 bytes;
- dictionary reconstruction passed at the expected 3,899,830 bytes;
- no Whisper, FluidAudio, Sparkle or Translation framework appeared in the linkage log;
- remaining compiler output is warnings only (mostly original upstream Swift warnings);
- `legacy-rewrite-DO-NOT-USE` is still pinned to `53fc576...` and was not modified.

Process issue found:
- too many compiler-probe/fix cycles were executed before reporting progress back to the user;
- several failures were expected dependency-boundary failures from surgical removal, not GitHub runner
  capacity failures;
- earlier GitHub connector calls did produce real HTTP/2 transport errors, which caused retries;
- the latest successful Actions run itself started promptly and took about five minutes, so there is
  no evidence that the Free account was the primary bottleneck for P4.

Corrected workflow rule:
- do not launch CI for ordinary source/documentation commits;
- `.github/workflows/build-lite.yml` already gates push builds to `.github/BUILD_LITE_TRIGGER`;
- batch coherent source fixes first, then trigger exactly one deliberate build probe;
- after each probe, report status before starting another series.

Current hand-off:
- `main` contains the first successfully built surgical Lite line;
- next work should be runtime/UI verification and memory measurement before more removal;
- do not continue trimming blindly after a successful build.


---

## Continuation Audit A2 — chat-limit hand-off and P4 artifact gate

Status: VERIFIED in the continuation chat after the previous chat hit its limit.

Live repository state rechecked:
- `main` = `527ea5f6bf2188fdad2792538f673375f6c6c7b6` before this documentation commit;
- `surgical-upstream-0.4.10` was at the same commit;
- `legacy-rewrite-DO-NOT-USE` remains frozen at `53fc5767952c6e289b67c75704b38bf168e97fca`;
- the successful P4 binary itself was built from source commit `fa15c929ba2c7d2527135c6e3bff2221ac727cad`;
- P4 workflow run: `36320184183`;
- P4 artifact ID: `10931982187`, artifact name `Keyboop-Lite-macOS-Apple-Silicon`.

Artifact audit:
- GitHub artifact download is intact and not expired at the time of this audit;
- outer Actions artifact: 2,594,387 bytes;
- it contains the packaged `Keyboop-Lite.zip`;
- packaged app is `Keyboop Lite.app`, arm64 Mach-O;
- executable is about 2.7 MB; unpacked bundle is about 8.6 MB because retained dictionaries/resources dominate the bundle;
- `Info.plist` identifies version `0.4.10-lite`, minimum macOS 15.0, `LSUIElement=true`;
- no heavy framework is linked according to the successful P4 linkage check.

Important cleanup observation:
- the arm64 executable still contains some user-facing strings mentioning removed voice/translation/model features;
- these strings come from retained upstream source files such as About/changelog/settings text and are not evidence that Whisper, FluidAudio, Sparkle or Apple Translation frameworks are linked or initialized;
- treat this only as a later binary/dead-text cleanup opportunity, not as a reason to resume blind source cutting before runtime verification.

Hard gate before further optimization:
1. install/run the exact P4 artifact on the target MacBook Air M1 / macOS Sequoia;
2. verify original-looking retained Settings UI;
3. verify automatic RU/EN switching with a real mistyped-layout sample;
4. verify TypoFix/spell correction;
5. verify Autoreplace/snippets;
6. close Settings and measure steady-state RAM;
7. only after those checks, make the next small surgical cleanup batch.

Process rule remains:
- no new compiler-probe loop until the runtime checkpoint is reported;
- ordinary documentation/source commits must not trigger Actions;
- after every future code commit, update this hand-off journal and keep `main` plus `surgical-upstream-0.4.10` synchronized.


---

## Runtime Fix P5A — P4 permission/translocation audit

Status: IMPLEMENTED; CI intentionally not triggered by this commit.

Trigger:
- first real P4 test on the target MacBook Air M1 / macOS Sequoia;
- user launched Keyboop Lite from /Applications but still saw the original “move Keyboop to Applications”
  warning;
- the Lite app also insisted on Input Monitoring and could not be added to the Input Monitoring list.

Root causes found:
1. **Translocated singleton trap.** P4 acquired the cross-Keyboop singleton lock before checking App
   Translocation. If the first launch came from Downloads/the extracted artifact, that translocated
   process kept the lock. Launching the installed /Applications copy then became a secondary instance,
   asked the old translocated process to open Settings, and exited. The UI therefore honestly reported
   the old temporary path even though the user had clicked the copy in /Applications.
2. **Wrong Lite permission gate.** The retained Lite keyboard hook is the original active
   `.defaultTap` CGEventTap. Its own source explicitly states that this path requires Accessibility
   and is not a listen-only/Input-Monitoring tap. P4 nevertheless inherited the full app's extra
   `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)` gate and treated failure of that separate grant
   as a fatal core-permission error.
3. **CI artifact is ad-hoc signed.** That is acceptable for a test artifact but is known to make TCC
   identity less robust than a stable Developer-ID/self-signed development identity. Therefore Lite
   must not make a separate Input Monitoring database entry a prerequisite for core switching when
   the retained active event tap already provides the correct live Accessibility check.

Changes:
- a translocated Lite instance now listens for a narrow `ru.keyboop.lite.stableTakeover` signal;
- a stable Lite launch that finds the shared lock busy requests that takeover, then retries the lock;
- original Keyboop does not listen for this Lite-only signal and is not terminated;
- Lite menu permission state now depends on whether the retained active engine actually started;
- on successful Lite `engine.start()`, core operation no longer requests or waits for Input Monitoring;
- Lite permission menu points to Accessibility, not Input Monitoring;
- optional Caps LED direct-HID behavior still keeps its separate Input Monitoring request if the user
  explicitly enables that optional feature;
- Lite Info.plist now includes canonical `CFBundlePackageType=APPL` and
  `NSPrincipalClass=NSApplication`.

Assessment of P4:
- P4 compiled and linked correctly but **failed the first runtime permission/install checkpoint**;
- P4 is not a release candidate and should not be used for further functionality/RAM conclusions;
- no evidence was found that Whisper/FluidAudio/Sparkle/Translation dependencies returned.

Next:
- trigger exactly one P5 build;
- install P5 only after fully quitting every P4/translocated Keyboop Lite process;
- launch the P5 copy from /Applications;
- grant Accessibility when requested;
- do not manually add Lite to Input Monitoring for the core test;
- verify real RU/EN auto-switching, TypoFix and Autoreplace before any further trimming.


---

## Build Probe P5 — runtime permission/install repair

Status: TRIGGERED by this commit.

Source under test:
- `9ba58d4fd63106e235b59d308802da702f463a39`.

Purpose:
- compile exactly the P5A runtime fix after the failed P4 on-device checkpoint;
- verify the translocated-singleton takeover and Lite-only Accessibility permission path compile cleanly;
- repackage the canonical Lite APPL bundle metadata;
- confirm heavy removed frameworks remain absent.

CI rule:
- this commit changes `.github/BUILD_LITE_TRIGGER` intentionally;
- no other Actions probe should be launched until this run is inspected.

Success gate:
1. dictionary restore succeeds;
2. arm64 Swift compile succeeds;
3. code signing / strict verification succeeds;
4. linkage still has no Whisper, FluidAudio, Sparkle or Translation framework;
5. artifact uploads;
6. only then hand the P5 artifact to the user for a fresh /Applications runtime test.


---

## Build Probe P5 Result — permission/install repair artifact

Status: SUCCESS.

Evidence:
- workflow run `36325191382`;
- job `108636503083`;
- all build/package/upload steps completed successfully;
- exact `words_ru.json` restore: 3,899,830 bytes;
- artifact ID `10933504382`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- outer artifact size: 2,593,963 bytes;
- inner packaged `Keyboop-Lite.zip`: 2,599,512 bytes;
- unpacked app remains about 8.6 MB; executable remains about 2.7 MB;
- resulting Info.plist contains `CFBundlePackageType=APPL`,
  `NSPrincipalClass=NSApplication`, bundle id `ru.keyboop.lite`, minimum macOS 15.0.

Linkage check:
- no Whisper;
- no FluidAudio/Parakeet;
- no Sparkle;
- no Apple Translation framework;
- retained linkage is Apple system frameworks plus Swift runtime overlays.

Runtime checkpoint:
- P5 replaces P4 for testing;
- fully quit P4 before installation so no old translocated process or singleton lock survives;
- replace only `Keyboop Lite.app` in /Applications; keep original `Keyboop.app` separate;
- core test requires Accessibility; do not manually add Lite to Input Monitoring;
- Input Monitoring remains relevant only to optional direct-HID Caps LED functionality if explicitly enabled.

Next:
- verify that the P5 process started from /Applications no longer reports translocation;
- grant Accessibility and verify real keyboard operation;
- then test auto-switch, TypoFix and Autoreplace;
- only after runtime success measure RAM and continue trimming.


---

## Runtime/UI Fix P6A — ghost hotkeys, Lite copy, quit flow, F18 collision

Status: IMPLEMENTED; CI intentionally not triggered by this commit.

Trigger:
- P5 passed the permission/install checkpoint on the target MacBook Air M1 / macOS Sequoia;
- first functional UI test exposed four concrete retained-upstream leaks.

Root causes and fixes:
1. **Phantom voice hotkey conflict.**
   - `HotkeyGuard.Slot.allCases` still included voice/translation/paste-last-dictation.
   - their shared AppSettings defaults survived compilation, so removed voice could still “own” a
     shortcut and block assignment in Lite.
   - under `KEYBOOP_LITE`, those three slots now return no trigger. Retained slots are unchanged.
2. **Quit confirmation.**
   - Lite inherited the full app's modal confirmation, whose text also mentioned voice input.
   - Lite now exits immediately from the menu; the full build keeps the original confirmation.
3. **Removed-feature UI leakage.**
   - Lite quick-action choices are now only Pause and Settings; stale saved full-app values are
     normalized to Pause instead of surfacing “copy last dictation”.
   - Lite simple/root settings no longer instantiate VoiceHotkeyControl or TranslateHotkeyControl;
     it shows only retained auto-switch, TypoFix and manual-layout controls.
   - Lite General, Privacy and About use dedicated copy with no voice/model/translation/update claims.
   - Lite About omits dictated counters, voice credits, Welcome/What's New/update/feedback controls.
   - Lite root footer reports only rescued-layout count.
4. **DoubleShift → CleanupBuddy/F18.**
   - root cause was not DoubleShift itself. A manual conversion in Chromium/Electron can use the
     clipboard-read fallback; immediately after synthetic Cmd+C, `TextReplacer` deliberately posted
     a sacrificial F18 event so Chromium/Figma would consume that event instead of the first real text
     event.
   - F18 is a real global shortcut on the target Mac (physical moon/F6 remapped to F18, macOS Shortcut
     “Start Cleanup” bound to F18), so our synthetic sacrifice launched CleanupBuddy.
   - sacrificial key changed from real F18/keyCode 79 to sentinel keyCode 255, already proven in this
     codebase as a deliverable non-printing synthetic keyDown and not mappable to a physical F-key.
   - F17…F20 are explicitly forbidden as future sacrificial fallbacks because users can bind them.

Scope:
- no change to layout-conversion algorithms, TypoFix, autoreplace stores or dictionary data;
- no heavy subsystem restored;
- full/non-Lite upstream behavior remains behind existing conditional compilation.

Next:
- trigger exactly one P6 build;
- verify compilation/linkage/artifact;
- runtime test: assign DoubleShift, confirm no CleanupBuddy launch, confirm no phantom voice conflict,
  confirm Exit is immediate, and inspect General/Privacy/About/Basic screens for removed-feature text.


---

## Runtime/UI Fix P6A-1 — pre-build review correction

Status: IMPLEMENTED; CI intentionally not triggered.

Pre-build self-review found two issues in the P6A source commit before spending an Actions run:
- the newly appended Lite L10n block needed a comma after the preceding full-build dictionary entry;
- some new Lite explanatory copy still named removed features in phrases such as “Lite has no …”.
  The user asked for those concepts to disappear from the Lite interface, not merely be described as absent.

Fix:
- repaired the L10n dictionary separator;
- rewrote Lite Privacy/About copy to describe only retained behavior and local processing, without
  naming removed subsystems.

Next:
- trigger one P6 build only after this correction.


---

## Build Probe P6 — runtime/UI cleanup

Status: TRIGGERED by this commit.

Source under test:
- `e84ca17338f35cb27cc8834f3f824eb98b2bcaf4`.

Purpose:
- compile the P6A/P6A-1 fixes as one checkpoint;
- verify Lite-only hotkey registry branches and simple/About UI compile;
- verify sentinel keyCode 255 replacement for the Chromium sacrificial event;
- confirm no removed heavy framework returns.

Runtime gate after successful artifact:
1. manual hotkey assignment must not claim removed voice/translation actions;
2. menu Exit must quit immediately without confirmation;
3. Basic/General/Privacy/About must contain no removed-feature UI;
4. DoubleShift/manual correction in Chromium must not emit the user's F18 shortcut or launch CleanupBuddy;
5. retained auto-switch, TypoFix and Autoreplace must still work.

CI load rule:
- this is the single deliberate probe for the whole P6 batch.


---

## Build Probe P6 Result — four runtime/UI fixes packaged

Status: SUCCESS.

Evidence:
- workflow run `36327626012`;
- job `108643325784`;
- artifact ID `10934169148`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- outer artifact size: 2,591,874 bytes;
- dictionary restore, Swift compile, signing, package and upload all succeeded;
- linkage remains Apple system frameworks + Swift runtime overlays only;
- no Whisper, FluidAudio/Parakeet, Sparkle or Translation framework was restored.

P6 user-facing changes under test:
- removed functions no longer reserve hotkeys in Lite;
- Lite Exit no longer asks for confirmation;
- Basic/General/Privacy/About were cut to retained Lite functions and Lite-only copy;
- right-click actions are only Pause and Settings in Lite, with old removed values normalized;
- Chromium/Electron sacrificial event is keyCode 255 instead of F18, so it cannot trigger the user's
  F18-bound CleanupBuddy shortcut.

Binary audit note:
- the shared upstream `L10n.swift` still physically contains dead full-build strings, and some
  full-build-only control types are still present as unreachable compiled text/symbols.
- P6 removes their user-visible routes but does NOT yet claim physical dead-string elimination.
- do not expand this into another blind cleanup before the four P6 runtime checks pass; after that,
  a separate size/RAM cleanup can split Lite localization/control code safely.

Runtime checkpoint:
1. replace P5 with P6 in /Applications;
2. select DoubleShift and confirm no CleanupBuddy/F18 action fires;
3. confirm no phantom “voice typing” conflict;
4. confirm Exit is immediate;
5. inspect Basic, General, Privacy and About for removed-feature wording;
6. recheck auto-switch, TypoFix and Autoreplace.


---

## Runtime Fix P7A — permission-window storm / event-tap timeout

Status: IMPLEMENTED; CI intentionally not triggered by this source commit.

Trigger:
- on-device P6 test on MacBook Air M1 / macOS Sequoia;
- while granting permissions, several permission/settings windows appeared close together;
- the whole Mac briefly stopped responding to keyboard/mouse input;
- Keyboop menu then showed: “Перехват снят: система его глушила, я приостановился”.

This screenshot is direct evidence that EventTap's timeout-storm safety path fired:
- `EventTap` suspends itself only after 3 `.tapDisabledByTimeout` events within 60 seconds;
- the retained tap is an active `.defaultTap` on the main runloop, so a blocked callback can stall
  the WindowServer input pipeline until macOS disables the tap.

Root causes found:
1. Lite inherited the full app permission choreography even after voice/onboarding removal:
   - `tryStart()` attempted `CGEvent.tapCreate` immediately and every 0.5 s;
   - failed start then called `AXIsProcessTrustedWithOptions(prompt=true)`;
   - the app also opened its own NSAlert, which could then open System Settings.
   This created overlapping native/custom permission UI and repeated TCC/tapCreate work.
2. After a successful Lite `engine.start()`, the code immediately logged
   `Permissions.isTrusted()`. That is synchronous TCC IPC on the SAME main runloop that just gained
   an active `.defaultTap`. The EventTap source already documents a previous real incident where
   this exact class of TCC IPC stalled the main runloop and froze keyboard/mouse input until macOS
   disabled the tap.

P7A fix:
- Lite now has a separate one-window Accessibility bootstrap;
- it issues exactly one native `requestTrust()`;
- it does not create the active event tap until Accessibility is already reported granted;
- fallback TCC polling runs on a utility queue at 1 Hz, never on the event-tap/main runloop;
- no Lite custom permission NSAlert is stacked on top of the native prompt;
- no Lite relaunch modal is stacked on the permission flow;
- after the active Lite tap starts, the success path does not call `AXIsProcessTrusted()`;
- Lite launch diagnostics no longer query the unrelated Input Monitoring permission.

Full/non-Lite behavior is unchanged.

Runtime gate for P7:
1. fresh launch without Accessibility should show only the native macOS permission flow;
2. opening System Settings from that native flow must not spawn additional Keyboop permission alerts;
3. keyboard/mouse must remain responsive throughout;
4. menu must not enter `tapSuspended`;
5. after granting Accessibility, Lite should start automatically without app restart;
6. retained auto-switch, TypoFix, Autoreplace and manual hotkeys must still work.


---

## Runtime Fix P7A-1 — pre-build TCC-call audit

Status: IMPLEMENTED; CI intentionally not triggered.

One additional duplicate TCC read was found during review:
- Lite launch diagnostics called `Permissions.isTrusted()`;
- a few milliseconds later `startLiteAccessibilityFlow()` called the same synchronous IPC again.

Because P7's goal is a single, deterministic permission path, the Lite launch log no longer queries TCC.
The first/only synchronous status read before any event tap exists now lives in
`startLiteAccessibilityFlow()`; repeating probes remain off-main.


---

## Build Probe P7 — permission flow / tap timeout repair

Status: TRIGGERED by this commit.

Source under test:
- `54698b11776346733e9b357b14522ac28ca1339b`.

Purpose:
- compile the Lite-only permission bootstrap;
- verify no accidental full-build regression from conditional compilation;
- recheck signing/package/linkage before another on-device permission test.

Success gate:
1. dictionary restore succeeds;
2. arm64 compile succeeds;
3. strict signing verification succeeds;
4. no removed heavy framework returns;
5. artifact uploads;
6. then replace P6 with P7 for a fresh permission-flow test.


---

## Build Probe P7 Result — permission flow / tap timeout repair

Status: SUCCESS.

Evidence:
- workflow run `36328853832`;
- job `108646782186`;
- artifact ID `10935311519`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- artifact size: 2,590,944 bytes;
- dictionary restore, arm64 compile, strict signing verification, packaging and upload succeeded;
- linkage remains Apple system frameworks + Swift runtime overlays;
- no Whisper, FluidAudio/Parakeet, Sparkle or Translation framework returned.

What P7 changes at runtime:
- Lite no longer creates/retries the active event tap every 0.5 s while permission is unresolved;
- exactly one native Accessibility request is initiated;
- no Keyboop custom permission NSAlert or relaunch modal is stacked on top;
- Accessibility fallback checks run off-main at 1 Hz;
- active event tap is created only after a granted status is observed;
- no synchronous TCC query is performed immediately after attaching the active tap.

Why this addresses the user's observed Mac freeze:
- the P6 screenshot's `health.tapSuspended` state can only be reached after the tap receives three
  timeout-disable events in the 60-second storm window;
- the old Lite permission choreography contained multiple synchronous TCC/tap operations on the main
  runloop and an explicit post-start `AXIsProcessTrusted()` call while the active tap was already
  installed;
- P7 removes those overlaps from the Lite path.

Runtime checkpoint:
1. fully quit P6 and replace only `/Applications/Keyboop Lite.app` with P7;
2. for a clean permission-flow test, toggle/remove the existing Lite Accessibility grant only if the
   user intentionally wants to reproduce first-run permission behavior; otherwise normal launch is fine;
3. confirm no cluster of Keyboop permission dialogs appears;
4. confirm keyboard/mouse never freeze and menu never shows `tapSuspended`;
5. confirm Lite starts automatically after Accessibility becomes granted;
6. then continue the P6 functional checks: DoubleShift/F18, immediate Exit, dead UI copy,
   auto-switch, TypoFix and Autoreplace.


---

## Memory Optimization Branch P8 — baseline and P8A Settings teardown

Status: IMPLEMENTED on experimental branch; CI intentionally triggered by this commit.

Baseline preservation:
- exact known-good P7 baseline: `6c4f829f04b4dd4a0fd4f91dfc1b3d802c2e947e`;
- `main` and `surgical-upstream-0.4.10` remain untouched on that P7 line;
- `stable-p7` was created and pinned to the same P7 commit as an explicit rollback/reference branch;
- RAM experiments are isolated on `memory-p8-experiments`.

P8 rule:
- memory work must not trade away retained functionality;
- auto RU/EN switching, TypoFix, Autoreplace/snippets, manual switching/hotkeys, permissions,
  retained menu behavior and the original retained Settings UI are functional gates;
- optimize lifetime/storage first; do not simplify switching heuristics or dictionary semantics merely
  to win RAM.

P8A purpose:
- remove a confirmed lifetime leak-by-design in Lite: after the Settings window was closed,
  `AppDelegate.settingsWC` kept the entire SettingsWindowController/AppKit view tree alive for the
  remainder of the process.

P8A implementation:
- `SettingsWindowController` exposes a Lite-only close lifecycle hook;
- after AppKit finishes `windowWillClose`, AppDelegate drops its strong Settings controller reference;
- reopening Settings constructs the same original retained UI again from persisted `AppSettings`,
  `ExceptionStore` and `SnippetStore` state;
- the release is deferred to the next main-runloop turn and is cancelled if the same window has
  already become visible again;
- non-Lite behavior is unchanged.

Files changed in this implementation commit:
- `Sources/Keyboop/AppDelegate.swift`;
- `Sources/Keyboop/SettingsWindow.swift`;
- `.github/workflows/build-lite.yml` (allows the isolated memory branch to run the same gated CI);
- `.github/BUILD_LITE_TRIGGER`;
- `AGENTS.md`.

Safety / functional assessment:
- no Engine, EventTap, LayoutDetector, LayoutData, TypoFix, TextReplacer, SnippetStore or hotkey logic changed;
- no retained resource, dictionary, framework or setting was removed;
- this optimization affects only memory retained after the Settings window is closed;
- expected RAM saving depends on whether Settings has been opened during the session and must be
  measured on-device rather than guessed from bundle size.

Build Probe P8A:
- trigger value: `probe-p8a-settings-release`;
- source commit: `f85793c446f38d8a55fce101f3c442f9b6dac6e2`;
- success gate: compile, strict signing, packaging, artifact upload and unchanged forbidden-linkage guard;
- runtime gate: open/close/reopen Settings repeatedly, verify state persists and UI is identical, then
  verify auto-switch, TypoFix, Autoreplace and manual hotkeys before proceeding to dictionary/storage work.

Exact next step after P8A runtime validation:
1. measure RAM before opening Settings, while open, and 5-10 seconds after close;
2. if the controller teardown is proven safe, commit the result in this journal;
3. then begin P8B dictionary representation work as a separate reversible experiment, preserving exact
   `contains()` semantics and detection results.


---

## Build Probe P8A Result — Settings lifecycle memory experiment

Status: SUCCESS.

Evidence:
- workflow run `36329673381`;
- job `108649081420`;
- source commit `f85793c446f38d8a55fce101f3c442f9b6dac6e2`;
- artifact ID `10935850346`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- artifact size: 2,591,780 bytes;
- dictionary restore, 67-source arm64 compile, strict signing verification, packaging and artifact upload all succeeded.

Linkage audit:
- no Whisper;
- no FluidAudio/Parakeet;
- no Sparkle;
- no Apple Translation framework;
- direct linkage remains Apple system frameworks plus Swift runtime overlays.
- `libswiftAVFoundation.dylib` remains only as a weak Swift overlay from retained shared source imports;
  P8A does not change this because the current experiment is intentionally limited to object lifetime.

P8A runtime checkpoint:
1. replace P7 with this P8A artifact only for the memory experiment;
2. record RAM after launch before opening Settings;
3. open Settings and record RAM;
4. close Settings, wait 5-10 seconds, and record RAM again;
5. reopen Settings and confirm retained values/UI are intact;
6. verify auto-switch, TypoFix, Autoreplace/snippets and manual hotkeys;
7. do not merge this branch into `main` until these checks pass.

Stable rollback remains:
- `stable-p7` -> `6c4f829f04b4dd4a0fd4f91dfc1b3d802c2e947e`;
- `main` remains on the P7 line;
- all subsequent RAM work stays on `memory-p8-experiments`.


---

## P8A runtime result — Settings close does not return Activity Monitor memory to cold baseline

Status: ON-DEVICE TESTED; functional regression not reported in this checkpoint, but RSS result is insufficient.

Measured on MacBook Air M1 / macOS Sequoia with P8A:
- first launch, before opening Settings: main Keyboop Lite process = **33.2 MB**;
- persistent resource-guard helper = **2.9 MB**;
- after opening Settings once, closing it, and waiting roughly 1-2 minutes:
  main process = **45.2 MB**;
- helper remained **2.9 MB**;
- visible post-Settings delta versus cold main-process baseline = **+12.0 MB**.

Interpretation:
- dropping `AppDelegate.settingsWC` is still the correct object-lifetime behavior and prevents Lite
  itself from intentionally owning the closed Settings tree forever;
- however Activity Monitor did not fall back to 33.2 MB. AppKit/Foundation caches and Darwin malloc
  are allowed to retain freed pages/arenas for later reuse, so object release does not imply an
  immediate RSS/footprint contraction;
- therefore P8A alone is not a useful user-visible RAM solution. Keep it isolated on the memory branch,
  but do not spend further iterations trying to force AppKit to purge allocator caches.

Decision:
- proceed to the dominant always-resident allocation: the 162,760-word RU and 59,276-word EN base
  dictionaries currently decoded into Swift `Set<String>` hash tables;
- preserve every word and exact membership semantics.

---

## Memory Optimization P8B — compact exact word lexicons

Status: IMPLEMENTED; CI intentionally triggered by this commit.

Purpose:
- reduce the **cold/background** footprint without changing detection quality;
- replace only Lite's resident JSON -> `[String]` -> `Set<String>` representation of the two large
  base word dictionaries.

Implementation:
- canonical `words_ru.json` and `words_en.json` remain the source of truth;
- during GitHub Actions build, `scripts/make-compact-lexicons.swift` converts them to sorted,
  newline-delimited UTF-8 `.lex` resources without deleting or normalizing any word;
- Lite memory-maps the resulting files with `Data.ReadingOptions.mappedIfSafe`;
- runtime keeps only 32-bit line-start offsets and performs exact binary search over UTF-8 bytes;
- all `ExtraWords` sets remain the same small in-memory overlays and keep the same precedence;
- if a compact resource is unexpectedly absent, Lite falls back to the original exact JSON/Set path
  rather than silently changing behavior;
- full/non-Lite Keyboop keeps its original `Set<String>` implementation.

What is deliberately NOT changed:
- no word is removed;
- no Bloom filter/probabilistic membership;
- no stemming, morphology, truncation or heuristic shortcut;
- no change to LayoutDetector decision order, thresholds, trigrams, TypoFix rules, Engine, EventTap,
  snippets/autoreplace, manual switching, hotkeys or permission flow;
- trigram dictionaries remain unchanged for this experiment.

Expected memory effect:
- eliminate hundreds of thousands of long-lived Swift String/hash-bucket allocations from the Lite
  base dictionaries;
- mapped lexicon pages are file-backed/reclaimable, while line offsets are under ~1 MB for both
  dictionaries combined;
- exact on-device result must be measured; no target number is claimed before runtime evidence.

Files changed:
- `Sources/Keyboop/LayoutData.swift`;
- new `scripts/make-compact-lexicons.swift`;
- `build-lite.sh`;
- `.github/BUILD_LITE_TRIGGER`;
- `AGENTS.md`.

Build Probe P8B:
- trigger: `probe-p8b-compact-lexicons`;
- success gate: lexicons generated, all retained Swift sources compile, strict signing succeeds,
  package uploads, removed heavy framework linkage does not return;
- runtime gate: compare cold RAM to P8A's 33.2 MB baseline and then verify the same RU/EN samples,
  TypoFix, Autoreplace/snippets and manual hotkeys before any merge.


---

## Build Probe P8B Result — compact exact lexicon artifact

Status: SUCCESS.

Evidence:
- workflow run `36330718004`;
- job `108651976132`;
- source commit `e89b75d6ffac89d7638940588cd7430d44ce8db6`;
- artifact ID `10935413821`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- outer artifact size: 3,361,408 bytes;
- compact lexicon generation completed before compilation:
  - RU: 162,760 words;
  - EN: 59,276 words;
- all 67 retained Swift sources compiled;
- signing verification, packaging and upload succeeded.

Post-build artifact integrity audit:
- unpacked artifact contains both canonical JSON resources and generated `.lex` resources for this
  experimental checkpoint;
- RU `.lex`: 162,760 lines, exactly the same unique word set as `words_ru.json`;
- EN `.lex`: 59,276 lines, exactly the same unique word set as `words_en.json`;
- both lexicons are correctly sorted by UTF-8 byte order used by the runtime binary search;
- no base dictionary word was added, removed, normalized or changed.

Linkage:
- no Whisper;
- no FluidAudio/Parakeet;
- no Sparkle;
- no Apple Translation framework;
- direct linkage remains Apple system frameworks plus weak Swift overlays already present before P8B.

Runtime checkpoint:
1. replace P8A with P8B from the experimental branch;
2. on a fresh process, wait about 10 seconds before opening Settings and record main-process RAM;
3. compare against P8A cold baseline **33.2 MB**;
4. type several known RU and EN cases that previously auto-switched correctly, including short/common
   words, then test TypoFix and Autoreplace/snippets;
5. open/close Settings once and record RAM again only as a secondary measurement;
6. helper-process memory is tracked separately (P8A: 2.9 MB) and is not affected by P8B.

Do not merge into main until on-device behavior confirms exact lookup parity.


---

## P8B runtime result — compact lexicons materially reduce cold RAM; Settings still ratchets footprint

Status: ON-DEVICE TESTED.

Measured on MacBook Air M1 / macOS Sequoia:
- P8A cold main process before opening Settings: **33.2 MB**;
- P8B cold main process before opening Settings: **21.7 MB**;
- cold-main reduction from compact exact lexicons: **11.5 MB (~34.6%)**;
- persistent resource-guard helper remains **2.9 MB**;
- after one Settings open/close and several minutes idle, P8B main process settles around **39.7 MB**;
- therefore the Settings high-water delta in P8B is about **+18.0 MB** and still does not naturally
  return to the 21.7 MB cold baseline.

Conclusion:
- P8B is a successful direction for always-resident memory: exact dictionary behavior was preserved
  while the cold main process fell from 33.2 MB to 21.7 MB;
- P8A object release by itself is not enough to make Activity Monitor fall after Settings closes;
- the remaining post-Settings footprint is consistent with freed AppKit/Foundation allocations being
  retained by Darwin malloc zones/caches rather than an intentional strong reference from AppDelegate.

---

## Memory Optimization P8C — reclaim freed Settings heap pages

Status: IMPLEMENTED; CI intentionally triggered by this commit.

Purpose:
- preserve the successful P8B cold footprint and make memory used transiently by Settings eligible to
  return to the OS after the window is actually closed;
- do this without changing Settings UI, stored values, switching algorithms, dictionaries or input path.

Implementation:
- after P8A has dropped the last AppDelegate strong reference to the closed Settings controller,
  schedule one delayed allocator pressure-relief pass;
- the pass runs after 2 seconds on a utility queue, never in `windowWillClose` and never directly on
  the event-tap/main runloop;
- if Settings was reopened during that delay, the trim is cancelled;
- call public macOS `malloc_zone_pressure_relief(nil, 0)`: NULL zone examines all zones, zero goal asks
  for maximal releasable-page pressure relief;
- log released bytes and elapsed time for runtime evidence.

Safety:
- this API only asks libmalloc to unmap pages that are already free; it does not free live objects;
- no retained feature logic changes;
- one-shot invocation only after Settings close, not a periodic timer;
- full/non-Lite path is unchanged.

Files changed:
- `Sources/Keyboop/AppDelegate.swift`;
- `.github/BUILD_LITE_TRIGGER`;
- `AGENTS.md`.

Runtime gate:
1. fresh launch: confirm P8C remains near P8B cold baseline (~21.7 MB main);
2. open Settings, close it, then wait 5-10 seconds;
3. check whether main-process memory now falls materially below P8B's post-close ~39.7 MB;
4. reopen Settings and verify identical UI/state;
5. verify auto-switch, TypoFix, Autoreplace/snippets and manual hotkeys.


---

## Build Probe P8C Result — Settings heap relief artifact

Status: SUCCESS.

Evidence:
- workflow run `36332844751`;
- job `108657980485`;
- source commit `b15fa2180569483341a784ff7291a6925d20ad18`;
- artifact ID `10936610849`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- artifact size: 3,362,674 bytes;
- compact lexicons regenerated successfully:
  - RU 162,760 words;
  - EN 59,276 words;
- all 67 retained Swift sources compiled;
- signing verification, packaging and artifact upload succeeded;
- removed heavy frameworks remain absent.

What P8C specifically tests:
- P8B cold-memory win remains intact;
- closed Settings controller is still released as in P8A;
- two seconds after close, when Settings has not been reopened, Lite asks libmalloc to return
  already-free pages to the OS via `malloc_zone_pressure_relief(nil, 0)`;
- runtime log records bytes actually released and elapsed milliseconds.

On-device comparison target:
- P8B cold main: **21.7 MB**;
- P8B after Settings close + minutes idle: **39.7 MB**;
- P8C is successful only if the post-close figure falls materially from that ~39.7 MB level without
  breaking reopening or any retained input feature.

Stable rollback remains unchanged:
- `stable-p7` -> `6c4f829f04b4dd4a0fd4f91dfc1b3d802c2e947e`;
- `main` remains on P7;
- RAM experiments remain isolated on `memory-p8-experiments`.


---

## P8C runtime result — allocator relief helps, but first-touch Settings caches remain

Status: ON-DEVICE TESTED.

Measured on MacBook Air M1 / macOS Sequoia:
- fresh P8C main process before opening Settings: **18.9 MB**;
- helper process: **2.7 MB**;
- opening Settings raised the main process to about **36 MB**;
- after closing Settings and waiting, the pressure-relief pass reduced it to **33.2 MB**;
- same-run retained delta versus cold baseline: **+14.3 MB**.

Interpretation:
- P8C proves a real portion of the post-Settings high-water mark was releasable allocator memory
  (roughly 2.8 MB from the observed ~36 MB peak to 33.2 MB);
- however most of the one-time increase survives maximal malloc-zone pressure relief, so it is not
  merely free heap pages;
- the remaining footprint is dominated by process-wide AppKit/UI first-touch state and caches.

New source-level finding:
- `SettingsWindowController` explicitly builds the **entire Pro Settings tree first** on every open:
  `NSSplitViewController` + `SidebarVC` + `DetailVC`, lays out the first detailed section,
  installs detailed observers, selects the first sidebar row, and only then collapses to the compact
  "Основное" screen;
- the source comment itself says: "ОКНО СОБИРАЕТСЯ ВСЕГДА В ВИДЕ PRO, И ТОЛЬКО ПОТОМ ... СХЛОПЫВАЕТСЯ";
- for Lite users opening the normal compact Settings screen this eagerly first-touches a large UI
  subsystem that is not needed at all unless they choose "Все".

Decision:
- keep P8B compact lexicons and P8C one-shot allocator relief;
- next experiment is to preserve the exact Pro UI but instantiate it lazily only when requested.

---

## Memory Optimization P8D — lazy Pro Settings construction

Status: IMPLEMENTED; CI intentionally triggered by this commit.

Purpose:
- reduce the persistent Settings high-water mark without removing any settings or changing their UI;
- avoid first-touching detailed AppKit controls on the common compact-settings path.

Implementation:
- Lite makes `NSSplitViewController`, `SidebarVC` and detailed `DetailVC` lazy;
- when Lite starts in "Основное", it builds only the compact root controller plus shared window chrome;
- detailed sidebar/split/detail objects, their observers and first-section layout are created only when:
  - the user switches to "Все", or
  - a deep link requests a detailed section;
- Pro size is calculated at that moment using the same saved-height/first-section rules as before;
- after Pro has been built, transitions and detailed Settings behavior use the same existing code paths;
- full/non-Lite behavior is unchanged;
- P8C's delayed allocator pressure relief remains after window close.

Functional safety:
- no setting removed or renamed;
- no change to AppSettings persistence;
- no change to layout detection, dictionaries, TypoFix, snippets/autoreplace, hotkeys or EventTap;
- the only change is **when** the existing detailed Settings object graph is constructed.

Runtime gate:
1. fresh launch: record main-process RAM;
2. open Settings and **do not switch to "Все"**; close it and wait 5-10 seconds;
3. compare post-close RAM to P8C's **33.2 MB**;
4. reopen Settings, switch to "Все", confirm sidebar/sections are visually and functionally identical;
5. close again and record the Pro-touched high-water mark separately;
6. verify retained input features.


---

## Build Probe P8D Result — lazy detailed Settings UI

Status: SUCCESS.

Evidence:
- workflow run `36334037632`;
- job `108661347212`;
- source commit `e0542f8176777fdeaeb1dd59ce08b2afa667ad27`;
- artifact ID `10936079417`, name `Keyboop-Lite-macOS-Apple-Silicon`;
- artifact size: 3,363,803 bytes;
- compact lexicons regenerated successfully (RU 162,760; EN 59,276);
- all 67 retained Swift sources compiled;
- strict signing verification, packaging and artifact upload succeeded;
- removed heavy frameworks remain absent.

What to measure on device:
- **simple-only path:** fresh launch -> open Settings -> leave mode on "Основное" -> close -> wait 5-10 s;
- compare against P8C post-close **33.2 MB** and fresh **18.9 MB** from the same machine;
- then reopen, switch to "Все", verify detailed sidebar/sections, close and record the separate
  Pro-touched high-water mark.

Expected interpretation:
- if simple-only post-close is materially below 33.2 MB, eager construction of the Pro tree was a
  significant source of the persistent one-time AppKit footprint;
- if it is unchanged, the remaining first-touch cost comes mostly from the shared window/root AppKit
  path itself, and further in-process trimming has diminishing returns.

Stable rollback:
- `stable-p7` remains pinned to `6c4f829f04b4dd4a0fd4f91dfc1b3d802c2e947e`;
- `main` remains untouched on P7;
- all P8 memory work remains isolated on `memory-p8-experiments`.


---

## P8D runtime result — lazy Pro construction works; in-process UI high-water remains

Status: ON-DEVICE TESTED.

Measured on MacBook Air M1 / macOS Sequoia:
- fresh launch, Settings never opened: main process about **20 MB**;
- opening Settings in **"Основное"**: about **30 MB**;
- switching to **"Все"**: about **40-42 MB**;
- closing Settings after Pro was touched and waiting: about **37 MB**;
- persistent resource-guard helper remains separate at roughly **2.7-2.9 MB**.

What this proves:
- P8D successfully avoids eagerly constructing the Pro tree on the common simple-settings path:
  simple Settings now costs roughly +10 MB instead of immediately first-touching the 40+ MB Pro state;
- first-touching the full Pro UI adds another roughly 10-12 MB;
- after Pro has been instantiated once, closing the window plus P8C malloc pressure relief still leaves
  a process-wide AppKit high-water mark around 37 MB.

Important architectural conclusion:
- the cold/background engine itself is now near **20 MB**;
- the remaining post-close gap is not coming from the compact dictionaries and is no longer explained
  by a retained SettingsWindowController alone;
- it is predominantly process-global AppKit/Dock/UI first-touch state. In particular Settings also
  intentionally switches the LSUIElement agent to `.regular` via `DockPresence.acquire(.settings)`
  while the window is open, which first-touches Dock/application UI infrastructure in the same process;
- returning to `.accessory` on close does not unload those frameworks/caches.

Decision point:
- further in-process micro-trimming is expected to have diminishing returns;
- preserving the exact same Settings UI **and** returning the background process to its ~20 MB cold
  footprint after Settings closes requires a process boundary (Settings in a short-lived helper process)
  or a controlled app restart after closing Settings;
- a helper process is the cleaner no-feature-loss architecture, but it requires explicit cross-process
  settings propagation and live side-effect reconciliation, so it should be a new isolated experiment
  rather than folded into P8D.

Stable state:
- `stable-p7` remains the known-good rollback baseline;
- P8B compact exact lexicons are the confirmed largest safe RAM win;
- P8C allocator relief and P8D lazy Pro construction remain on `memory-p8-experiments`;
- do not merge the experimental RAM branch into `main` until the desired architecture is chosen.


---

## Stability review after P8D — settings helper/restart rejected for release path

Status: REVIEWED; stability-first direction chosen.

User priority:
- minimize the probability of glitches, freezes, typing latency or missed corrections;
- RAM reduction must not come at the expense of the keyboard/event-tap path.

Re-check of the proposed separate Settings process:
- **not selected as the next production architecture** despite its theoretical RAM advantage;
- the current Settings UI does more than write passive preferences: controls trigger live side effects
  such as Caps/Globe reconciliation, Caps LED, menu/icon refresh, language/menu notifications,
  login-item changes, hotkey state and other process-owned behavior;
- moving the same UI to another process would require a real IPC contract and centralizing all side
  effects back in the engine process. A simple shared-UserDefaults helper would risk stale cached state,
  duplicated system mutations and settings that visually change but are not applied live;
- that is a substantially larger regression surface than the ~17 MB post-Pro high-water mark justifies.

Re-check of "restart after closing Settings":
- rejected for the same stability goal;
- restarting necessarily tears down and recreates the CGEventTap/singleton/resource-guard lifecycle;
- even a well-coordinated restart creates a short interval where live typing is not observed by the
  engine and adds avoidable TCC/tap lifecycle risk.

P8B lookup hot-path review:
- compact lexicons preserve exact membership semantics;
- a local optimized Swift 6.2 benchmark over the actual P8D dictionaries (15,038 mixed hit/miss
  queries, repeated) showed compact binary lookup in the same order as Swift Set lookup on that host:
  roughly 326-352 ns/query compact vs 332-396 ns/query Set, with identical hit counts;
- this benchmark host is x86_64 Linux, not the target M1/macOS, so it is not treated as an M1 latency
  measurement, but it provides no evidence that the P8B representation is intrinsically a typing
  bottleneck.

P8C allocator-pressure review:
- on-device it recovered only about 2.8 MB after closing Settings;
- `malloc_zone_pressure_relief(nil, 0)` is a process-wide allocator operation. Even though P8C runs
  it once on a utility queue, it can contend with allocator zones used by other threads;
- no user-visible stall was observed, but the stability-first release should not carry a low-level
  process-wide trim for such a small gain.

Decision:
- production-oriented experiment should keep **P8B compact exact dictionaries + P8D lazy Pro UI**;
- remove P8C manual malloc pressure relief;
- keep Settings in the main process;
- accept the AppKit high-water mark after detailed Settings is opened rather than introduce IPC,
  process restart or allocator-pressure risk into a keyboard utility.

---

## P8E — stability-first memory candidate

Status: IMPLEMENTED; CI intentionally triggered.

Changes from P8D:
- removed the delayed `malloc_zone_pressure_relief(nil, 0)` call and its scheduling code;
- retained release of `SettingsWindowController` itself after close;
- retained P8D lazy detailed Settings construction;
- retained P8B compact exact lexicons;
- no Engine/EventTap/LayoutDetector/TypoFix/TextReplacer/hotkey behavior changed.

Expected memory trade-off:
- cold/background memory should remain near the ~20 MB P8D level;
- after detailed Settings has been opened, footprint may remain a few MB higher than P8C/P8D because
  the allocator is allowed to keep free pages;
- this is intentional: stability and typing latency take precedence over reclaiming the last few MB.

Release gate:
1. CI compile/sign/package/linkage success;
2. fresh launch and normal typing/auto-switch test;
3. open simple Settings and detailed Settings, close them, then continue typing immediately;
4. verify no input pause, missed conversion or event-tap warning;
5. if stable, prefer P8E over P8C/P8D as the base for any future optimization.
