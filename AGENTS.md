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
