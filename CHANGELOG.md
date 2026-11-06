# Changelog

## 1.1.0 — 2026-11-06

- Replace macOS 27 width-based spacers with native application visibility requests. One cat control remains; monitor dimensions no longer determine the hidden selection.
- Add persisted app selection, search, a ten-second trial and Show everything recovery.
- Watch running-app inventory; allow new apps and release the restriction when no selected apps are running.
- Wait for native acknowledgement; cancel pending requests after three seconds and reject stale completions after restore or replacement.
- Detect missing/changed method signatures, activation errors, restoration errors and known apps outside `/Applications` that cannot be guaranteed visible.
- Allow the nine system-item enum values verified from the installed macOS 27.0 framework. Keep the feature experimental and disclose system-icon/Notification Center limitations.
- Preserve the legacy divider on macOS 14–26 and retain existing login/auto-hide preferences.

Verification: 22 tests pass; release bundle and installed v1.1.0 build 6 match and verify. Live native acknowledgement, timed release, normal Quit and settings cleanup were exercised. The user visually confirmed Amphetamine's icon disappeared and returned on both monitors during the trial. Other apps and display configurations remain unqualified.
