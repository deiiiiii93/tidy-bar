# Verification

Host: Apple Silicon, macOS 27.0 (26A428), Xcode 27.0 (27A266a), Swift 6.4. Deployment target: macOS 14.0.

## Current update: v1.1.0 native application visibility

The older sections below describe the historical spacer builds. v1.1.0 replaces macOS 27 spacers with a native application allow-list and a searchable settings list.

Executed on 2026-11-06:

- Release build succeeds; source and packaged Info.plist validate; strict ad hoc bundle signature verifies.
- 22 Swift Testing tests pass. Ten new checks exercise the production native coordinator through controlled leases: acknowledgement, pending cancellation, timeout without completion, late success, failed refresh, failed restore/retry, own-control preservation, refreshed inventory, no-target behavior and unavailable backend. A reentrant observer cancellation is also covered in this set.
- The read-only probe loaded the installed framework and verified all required method signatures. A second probe enumerated the native system-item enum, finding 0...8. Neither probe activated a restriction.
- The user copied the bundle into `/Applications` after the automatic installation review failed with HTTP 404, `Requested model is not valid`. The installed version is **1.1.0, build 6**. Built and installed executable SHA-256 both equal `0988a5f176d09dfe1b10e30941a52ff6faba4f78344e87f1b66f736bda8c5b58`; the installed strict signature passes.
- Computer-use inspection confirms the live settings show the native toggle, searchable app list, selected-app checkboxes, trial button, auto-hide and existing login preferences. The view scrolls without clipping its text. No privacy permission was requested.
- The previous spacer app was expanded and quit. The installed native app creates the cat without the old divider/helper set.
- A trial selecting Amphetamine initially refused because ChatGPT Computer Use and FigmaAgent were running outside `/Applications`. This exercised the real preflight instead of silently claiming those apps could remain visible. Both helpers were temporarily included in the trial selection.
- The installed backend accepted the three-app trial. Settings changed to **Trial · restores after 10s** and then back to **Expanded**. MenuBarAgent's accessibility tree changed during activation and restoration. These observations confirm acknowledgement and timed release, but do not identify every physical icon on each display.
- Ordinary hiding was also acknowledged. Quit while active removed the cat from MenuBarAgent's accessibility tree; reopening through Finder brought Settings back. This verifies the normal shutdown/reopen path, not forced process-death recovery.
- A synthetic Option–Command–B action did not produce an observable state change. The registration reports success, but the physical global shortcut remains unverified.
- Final cleanup explicitly restored Expanded and cleared all three temporary selections. Settings remains open, with native hiding enabled and zero selected apps. Existing auto-hide (30 seconds), hide-at-launch (off), and login startup (on) preferences were retained. Auto-hide is paused while Settings stays open.
- **User-confirmed visual result:** the user answered “Yes, on both monitors” when asked whether Amphetamine's icon disappeared and then returned during the ten-second trial. Native hiding and restoration are therefore visually confirmed for that app on the user's current two-monitor setup. This does not qualify every app, other display configurations, or future OS builds.

Remaining evidence boundary: MenuBarAgent screenshots from the computer-use tool omit monochrome icons. Scoped unified-log inspection cannot run inside this sandbox. The two-monitor result above is confirmed by the user's visual observation, not inferred from app state or the accessibility tree. Other apps/display configurations, all Apple controls, Notification Center interaction and forced process-death recovery still require separate checks. Native hiding remains explicitly experimental.

## Build and automated checks

- Release executable compiled against the installed macOS 27 SDK.
- Twelve Swift Testing tests pass, including stale timer rejection and settings suspension.
- App bundle Info.plist validates.
- Ad hoc bundle signature passes `codesign --verify --deep --strict`.
- Original 1024 × 1024 icon visually inspected; standard and Retina ICNS sizes packaged and read back by macOS.
- Source has no remote dependencies, network access, private framework calls, or permission requests.

## Live checks on macOS 27

The user opened the packaged app after the execution tool's launch approval service failed. Its native settings window was then inspected with the computer-use tool.

- Settings render with the cat artwork, setup diagram, preferences and footer visible, without clipped text.
- Hide and Show buttons alternate the app's observable state correctly.
- With auto-hide set to 10 seconds, the app stays visible while settings remains open beyond the interval.
- After closing settings and allowing the interval to elapse, reopening settings shows Hidden. This verifies the live timer and settings-close transition.
- Auto-hide was restored to Never, and icons were returned to Visible after testing.
- Launch at login was already On when inspection began. It was left unchanged. A login/reboot cycle has not been tested.

## macOS 27 failure and v1.0.1 correction

The user reported that **actual hiding does not work in v1.0.0**. This overrides any apparent success from the window state or timer checks. The first build is not qualified as a working macOS 27 hider.

The initial controller requested a single 10,000-point divider. [MenubarHide's primary implementation notes](https://github.com/junior-rj/menubar-hide#how-it-works) document that macOS 27 drops items at approximately half the available display width. That is consistent with the user's failure and the divider being absent while the app reported Hidden.

v1.0.1 replaces the giant divider with up to seven bounded spacers, using the narrowest display / notch trailing area as the per-item cap and the widest display for total coverage. Ten tests pass, including the cutoff, notch, mixed-display, unsupported-budget and legacy cases. Display changes expand the bar. Unsupported geometry reports an error and stays expanded. New autosave identities require one-time rearrangement.

The updated signed bundle has been rebuilt and relaunched. Its settings identify v1.0.1; Hide/Show transitions run without a geometry error on this Mac. The macOS MenuBarAgent surface is now accessible through the automation tool, but its JPEG capture omits monochrome menu bar icons, so it is not reliable before/after visual evidence. A full desktop screenshot was not executed because the automatic approval service returned HTTP 404 for its configured model. After the one-time rearrangement, the user confirmed: "it worked", then reported an interaction problem with the system « / » overflow control. **Actual hide/reveal in v1.0.1 is user-confirmed; coexistence with the system overflow control is not yet qualified.**

## Remaining evidence limits

A synthetic Option-Command-B action did not produce an observable state change, so global hotkey behavior is not yet verified; this alone does not establish whether the tool delivered a system hotkey. The user has been asked to check both clicking the cat and physically pressing Option-Command-B with an icon placed to the left of the divider. Actual icon displacement is now user-confirmed. The global shortcut remains unverified.

Multi-display, full-screen, crowded/notched display behavior, older macOS releases, and login startup across a reboot need separate testing. Compatibility is not inferred solely from compilation or the app's state label.

## System overflow interaction under investigation

v1.0.1 manipulates menu bar space, not the system’s overflow expanded/collapsed state. The built-in overflow control can reveal the very items Tidy Bar displaced; these are the same overflow group, not independent hidden groups. The model tracks the requested spacer mode and does not observe the native overflow state. The user clarified that icons do not restore correctly when the current app’s left-side menus fill the bar. This is consistent with natural system overflow due to insufficient space; it does not by itself show that Tidy Bar left spacers expanded.

## v1.0.2 restore cleanup and capacity wording

Source review found that v1.0.1 kept unused helpers `isVisible == true` at length zero and budgeted against the full display width on notched screens. v1.0.2 deactivates every helper on restore (before shrinking the divider), hides inactive helpers, suppresses their empty accessibility elements, and budgets against the actual status area. Existing autosave identities are preserved.

The executed test suite has 12 passing tests, including repeated restore, hide/show/hide helper visibility, and a notch case that proves the spacer group covers the status area without needlessly covering the whole screen. These test the actual helper-application function through a small interface, not a duplicate width formula. They do not prove system compositor behavior.

The settings now say Expanded rather than Visible and explain how to access remaining icons with the native overflow button when application menus consume the bar. This avoids claiming that all icons are physically on-screen.

Live inspection/restart of v1.0.2 was blocked: the computer-use tool’s application-selection call was not executed because its automatic approval service returned HTTP 404 for the configured model. No desktop or system settings were changed to bypass that failure. The packaged update needs a normal user restart; compositor-level restoration remains unverified for v1.0.2.
