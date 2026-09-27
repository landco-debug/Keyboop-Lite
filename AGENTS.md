# AGENTS.md — Keyboop Lite

## Project purpose

Keyboop Lite is a deliberately reduced macOS build derived from the open-source Keyboop project.

Primary target:
- MacBook Air M1
- macOS Sequoia
- Apple Silicon arm64
- minimal resident memory and minimal background work

Upstream baseline:
- repository: `iffuno/keyboop`
- upstream release baseline: Keyboop 0.4.10
- upstream commit: `fb9bdde4eb8f13a486974cf102a8bec9d607e5d2`
- upstream license: MIT

## Product scope that MUST remain

1. Automatic RU/EN layout correction.
2. Exceptions / learned words required by automatic switching.
3. The full practical "Автозамена" feature set:
   - abbreviation → replacement expansion;
   - trigger on Space / Enter / Tab;
   - paste as plain text;
   - typo correction;
   - two-capitals correction;
   - change case of selected text;
   - explicit snippets / snippet hotkey.
4. Menu-bar app behavior and lightweight settings necessary to configure the above.
5. Accessibility / Input Monitoring handling required for keyboard interception.

## Product scope that MUST NOT be linked into Lite unless later explicitly approved

- Voice dictation.
- Whisper / whisper.cpp.
- Parakeet / FluidAudio.
- Audio capture / audio import.
- Call recording.
- Voice history.
- Translation.
- Model downloaders.
- Persistent clipboard-history watcher.
- Sparkle auto-update framework.
- Feedback / changelog / onboarding subsystems that are not required at runtime.
- Slap / chassis gestures and unrelated experimental features.

The rule is physical exclusion from the Lite target, not merely disabled settings.

## Engineering rules

- Prefer Apple system frameworks already present on macOS.
- Do not add Homebrew.
- Do not require Xcode Command Line Tools on the user's Mac.
- Build distributable test artifacts with GitHub Actions.
- Keep the main runtime free from WebView/Electron/Tauri.
- Avoid polling timers when event-driven APIs are sufficient.
- Do not optimize away correctness of automatic switching or Autoreplace.
- Measure memory with the settings window closed and after a clean launch.
- Keep external behavior compatible with macOS Sequoia.
- Use arm64 as the first supported architecture.

## Repository / hand-off discipline

Every implementation commit must update this file in the same commit with:
- commit identifier or placeholder if the SHA is not yet known;
- purpose;
- files added/changed;
- architectural decisions;
- test/build state;
- next step.

A neighboring chat should be able to continue by reading only this file plus the current source.

## Stage plan

1. Establish clean Lite target and CI.
2. Port automatic-switching core and Autoreplace without heavy dependencies.
3. Restore the required settings UI and menu-bar controls.
4. Run functional tests and produce an arm64 artifact.
5. Profile memory.
6. If needed, replace JSON→Swift Set/Dictionary language data with compact binary storage without changing detection decisions.

---

## Commit 1 — repository bootstrap

Status: COMPLETE.

Purpose:
- establish project rules before source work starts;
- pin the exact upstream baseline;
- define the product boundary so future work cannot accidentally re-add voice/audio/translation dependencies.

Files:
- `AGENTS.md`

Build/test:
- no executable source yet.

Next:
- create the first compilable Keyboop Lite skeleton and GitHub Actions workflow, then begin porting the switching/autoreplace core.


---

## Commit 2 — first working Lite architecture

Status: IMPLEMENTED, awaiting CI validation.

Purpose:
- create the first real arm64 Keyboop Lite application;
- physically exclude all voice/audio/translation/update frameworks from the target;
- keep automatic switching plus the required Autoreplace feature family;
- optimize the largest language dictionaries for resident memory from the first build.

Files added:
- `Sources/KeyboopLite/main.swift`
- `Sources/KeyboopLite/AppDelegate.swift`
- `Sources/KeyboopLite/AppSettings.swift`
- `Sources/KeyboopLite/Engine.swift`
- `Sources/KeyboopLite/Keymap.swift`
- `Sources/KeyboopLite/LanguageData.swift`
- `Sources/KeyboopLite/Stores.swift`
- `Sources/KeyboopLite/TextTools.swift`
- `Sources/KeyboopLite/SettingsWindow.swift`
- `build-app.sh`
- `.github/workflows/build-test.yml`
- `README.md`
- `LICENSE`
- `THIRD_PARTY.md`

Architecture:
- AppKit status-bar application; no SwiftUI/WebView runtime.
- One CGEventTap for keyboard processing.
- Automatic RU/EN detection uses source/target dictionaries plus trigram plausibility.
- RU/EN word lists are converted during CI from pinned upstream JSON into sorted newline UTF-8 and opened with `Data(..., .mappedIfSafe)`.
- Only UInt32 line offsets are allocated for the large dictionaries; the words are not expanded into `Set<String>`.
- Trigram tables remain in in-memory dictionaries for the first profile pass.
- Autoreplace uses the same upstream-compatible UserDefaults keys `snippetsOrdered` and `textSnippets`.
- One-time migration reads relevant preferences from the full Keyboop domain `ru.keyboop.app`, so an existing user's autoreplace lists, exceptions and text-correction toggles can carry over.
- Plain-text paste reads the pasteboard only at the requested paste action; there is no clipboard polling/watcher.
- Case change snapshots/restores the pasteboard only while the explicit case-change action runs.
- Heavy upstream resources are pinned to upstream commit `fb9bdde4...` and downloaded only at build time, never at runtime.

Current functionality:
- automatic switching on Space / Enter / Tab;
- exceptions;
- layout/case-independent abbreviation autoreplace;
- plain-text paste;
- typo rules plus conservative transposition/double-letter repair;
- two-leading-capitals repair;
- selected-text case toggle;
- explicit snippets via Ctrl+Option+S then 1–9;
- settings for all of the above;
- launch-at-login control;
- Accessibility prompt;
- menu-bar auto toggle / settings / quit.

Build:
- GitHub Actions workflow builds only arm64 for macOS 14+ and uploads `Keyboop-Lite-arm64.zip`.
- Runtime links AppKit, ApplicationServices, Carbon and ServiceManagement only.
- CI validation has not yet completed at the time this commit is being authored.

Known limitations to test after first successful artifact:
- the first Lite detector is intentionally smaller than upstream 0.4.10's many edge-case guards; functional parity will be expanded only where real tests show a difference;
- settings UI is intentionally compact in v0.1 and will be visually refined after runtime correctness and memory are confirmed;
- the first build uses the standard U.S./Russian physical key map for conversion; selected macOS input source switching is language-based.

Next:
- run CI, fix every compile/link error in separate documented commits;
- obtain the first runnable artifact;
- perform user E2E for switching + Autoreplace;
- then measure clean-launch memory with the settings window closed.


---

## Commit 3 — compile-path hardening before CI

Status: IMPLEMENTED, awaiting CI validation.

Purpose:
- remove likely Swift/AppKit compile hazards before the first hosted build;
- make GitHub Actions also run on pull requests so CI can be forced through a PR event if API-originated pushes do not trigger workflows.

Files changed:
- `Sources/KeyboopLite/Engine.swift`
- `Sources/KeyboopLite/TextTools.swift`
- `Sources/KeyboopLite/Stores.swift`
- `Sources/KeyboopLite/SettingsWindow.swift`
- `.github/workflows/build-test.yml`
- `AGENTS.md`

Details:
- CGEvent masks are now built with explicit `CGEventMask(1) << rawValue`.
- modifier filtering uses an explicit CGEventFlags mask.
- navigation key codes use `Set<CGKeyCode>`.
- Unicode read/write goes through Swift unsafe buffer pointers rather than relying on array pointer coercion.
- case-conversion string assembly no longer mixes String and Substring operands.
- checkbox actions use a dedicated NSButton subclass with a retained Swift closure instead of an Objective-C associated-object helper.
- settings tabs are constructed explicitly and the default NSWindow style is left intact.
- CI now listens to `pull_request` as well as `push` and `workflow_dispatch`.

Build/test:
- source-level hardening only; hosted compilation is the next gate.

Next:
- push a tiny CI-bootstrap branch and open a PR if no push run appears;
- inspect exact compiler errors from the hosted macOS runner;
- fix only evidence-backed failures in the next documented commit.
