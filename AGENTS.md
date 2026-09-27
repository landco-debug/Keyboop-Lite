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
