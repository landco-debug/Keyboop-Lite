# Pinned upstream large resource

`words_ru.json` from Keyboop 0.4.10 is 3,899,830 bytes. The GitHub connector used to
bootstrap this repository silently returned an empty body for that oversized file.

To avoid an external runtime/build dependency and to preserve the exact upstream data, the
resource is stored here as ordered transport-safe chunks. `scripts/restore-words-ru.sh`
concatenates them before a build and verifies the original Git blob id when Git is available.

Source:
- repository: iffuno/keyboop
- commit: fb9bdde4eb8f13a486974cf102a8bec9d607e5d2
- path: Sources/Keyboop/Resources/words_ru.json
- byte size: 3899830
- Git blob: c059e65604324434b110112bdfdca94125372e48

This is a repository transport workaround only. Runtime dictionary contents must remain
byte-for-byte identical to upstream 0.4.10.
