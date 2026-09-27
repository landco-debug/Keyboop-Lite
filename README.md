# Keyboop Lite

A deliberately small Apple-Silicon build of Keyboop focused on:

- automatic RU/EN layout correction;
- exceptions;
- autoreplace;
- typo correction;
- two-leading-capitals correction;
- plain-text paste;
- selection case toggle;
- explicit text snippets.

## What is intentionally absent

No voice dictation, Whisper, Parakeet, FluidAudio, audio capture, translation, call recording,
voice history, model downloaders, Sparkle, WebView, Electron or Tauri.

The runtime uses AppKit/CoreGraphics/Carbon only where needed.

## Memory-oriented design

The large RU/EN word lists are converted at build time to sorted UTF-8 line files and memory-mapped
at runtime. Keyboop Lite keeps only compact UInt32 line offsets instead of decoding hundreds of
thousands of Swift String objects into Set<String>.

The RU/EN trigram probability tables are also converted at build time. Each trigram is stored as one
fixed 16-byte record (three Unicode scalar values + one Float32 probability), sorted and memory-mapped.
Lookup is allocation-free binary search; there is no resident [String: Double] trigram dictionary.

## Build

GitHub Actions builds the arm64 app. The build runs a deterministic self-test before packaging and
fails if heavy frameworks such as AVFoundation, CoreML, SwiftUI, Translation, Sparkle, FluidAudio,
Whisper or ggml leak into the linked executable.

A local build requires the Apple Swift toolchain, but users do not need Xcode or Command Line Tools
to run the produced artifact.

Upstream baseline: iffuno/keyboop 0.4.10 @ fb9bdde4eb8f13a486974cf102a8bec9d607e5d2.
