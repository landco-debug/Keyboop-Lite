import AppKit

/// Pasteboard ownership marker retained by Keyboop Lite.
///
/// Upstream defines this tiny NSPasteboard convenience extension next to ClipboardWatcher.
/// Lite deliberately excludes ClipboardWatcher (no persistent clipboard-history process), but
/// PlainPaste, SelectionText and SecureInputProbe still need to tag their own temporary writes so
/// the shared pure PasteboardOwnership logic can distinguish them correctly.
extension NSPasteboard {
    func kbNoteOurs() { PasteboardOwnership.note(changeCount) }
}
