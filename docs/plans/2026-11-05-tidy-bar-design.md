# Tidy Bar

User-approved scope: simple grouped menu bar hiding, a cute icon, local operation, macOS 27 support.

## Design

A native AppKit menu bar agent with a SwiftUI settings window. Two public NSStatusItem instances form a control and a divider. Command-drag icons to the left of the divider. Expanding the divider pushes that group off the menu bar; shrinking it reveals them. The control stays available. This established spacing technique avoids inspecting or controlling other applications, but relies on the system's menu bar layout behavior. A crowded/notched display can still clip revealed items; Tidy Bar does not create a secondary icon tray.

Alternatives considered: per-app management requires a larger permission and compatibility surface; a replacement icon tray requires image capture and synthetic interactions. Grouped spacing meets the approved small, local scope.

Visual direction: warm paper, deep green, mint accents, rounded cards, a hand-drawn sleeping cat in a little tray. Native vector artwork supplies both the monochrome menu icon and a full-resolution app icon.

Controls: click cat to toggle; right-click for actions; Option-Command-B shortcut; optional 10/30/60-second auto-hide; optional hiding at launch and login startup. No network calls, dependencies, telemetry, screen recording, or accessibility permissions. Settings use local UserDefaults. Launch at login uses ServiceManagement with visible failure/approval state.

## Implementation and verification

1. Build native app lifecycle, divider behavior, timer policy and settings. Verify timer state transitions, stale callbacks and settings suspension in unit tests.
2. Generate vector icon and package a signed local .app. Compile and test against this host's macOS 27 SDK.
3. Launch the actual app; inspect settings and menu bar; exercise hide/reveal and shortcut. Document limitations and installation.

Compatibility target: macOS 14+, tested on macOS 27.0 / Xcode 27.0. Ad hoc signing supports local use; distribution to other Macs requires a Developer ID and notarization.

## Correction after live failure

User testing found that the v1.0.0 10,000-point divider does not hide icons on macOS 27. The earlier compile and timer checks did not establish icon hiding. macOS 27 discards oversized status items and owns the bar in MenuBarAgent. v1.0.1 uses up to seven separately bounded spacers and native overflow, with a fresh identity for one-time layout migration. The width budget uses all displays and the notch’s trailing region. Screen changes restore the expanded state. See README and verification notes for evidence and limits.
