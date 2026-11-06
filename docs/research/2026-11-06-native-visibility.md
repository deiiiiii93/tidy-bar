# Replacing width-based hiding on macOS 27

Research date: 2026-11-06. Current status: **implemented in v1.1.0; the user visually confirmed Amphetamine hides and restores on both monitors in the current setup.** Other apps, display configurations and OS builds remain unqualified.

Implementation update: v1.1.0 now implements this mechanism. See [verification](../verification.md) for the executed checks and their limits. The original research below is retained as the design rationale.

Local correction to upstream system-item claims: during implementation, the installed framework's `MBSystemItemIdentifier.allCases` was read through Swift metadata. On macOS 27.0 (26A428), it contains raw values **0...8**, rather than bit flags or an inferred 0...255 range. The bridge uses those nine values. See [probe](system-item-probe.swift) and [result](system-item-probe.json). This establishes enum values, not physical preservation of every system icon. Earlier upstream range claims below are external observations, not verified facts on this host.

## Recommendation

Prototype application-based visibility through the private `MenuBarClientCore` framework. Store an explicit set of application bundle identifiers to hide, and let MenuBarAgent lay out the remaining icons. Keep the cat as the toggle. This removes screen width from the hiding decision.

Start with a small app-selection settings list, rather than inferring membership from icon coordinates on one monitor. Apply the same selection across displays. This is a different product contract from the current drag-left-of-divider setup, and it needs to be presented clearly before migration.

This is a credible experimental replacement, not a universal compatibility claim. The first decision gate is whether it preserves the user's wanted icons and ordinary system interactions on this Mac. Do not replace the packaged app before that gate passes.

## Evidence collected locally

The current controller makes one layout from all `NSScreen` geometries. `SpacerLayout` caps each spacer against the smallest status area, then tries to cover the largest area with at most seven items. `coversAllDisplays` proves only an arithmetic condition. It cannot establish compositor behavior, and the controller does not observe the icons it claims to hide.

An original, read-only probe was compiled and executed on macOS **27.0, build 26A428**. It loaded the installed system framework and found both classes and all three relevant instance methods:

| Class | Method | Runtime type encoding |
| --- | --- | --- |
| `MBAssessmentModeConfiguration` | `initWithAllowedSystemItems:allowedBundleIdentifiers:` | `@32@0:8@16@24` |
| `MBAssessmentModeAssertion` | `activateWithConfiguration:completionHandler:` | `v32@0:8@16@?24` |
| `MBAssessmentModeAssertion` | `invalidate` | `v16@0:8` |

The probe never created or activated an assertion, requested permissions, or enumerated other applications. Symbol presence is **not** proof that activation succeeds, that allow-listed icons remain visible, or that both monitors render correctly.

Files: [probe source](native-visibility-probe.m), [recorded result](native-visibility-probe.json).

Reproduce from the repository root:

```sh
xcrun clang -fobjc-arc -framework Foundation docs/research/native-visibility-probe.m -o /tmp/tidy-native-visibility-probe
/tmp/tidy-native-visibility-probe
```

## Mechanism and implementation evidence

[Hidden Bar's Objective-C bridge](https://github.com/dwarvesf/hidden/blob/master/hidden/Features/StatusBar/Engine/Native/HBNativeVisibilityShim.m) resolves the framework dynamically, checks class/selector availability, constructs array-based configuration, and invokes asynchronous activation. It catches Objective-C exceptions around activation and invalidation. This is source-level evidence of a concrete implementation, not just a feature claim. A Swift-only `do/catch` would not catch those exceptions.

Conceptually, the proposed controller computes:

```text
allowed applications = known running bundle IDs minus the user's hidden set
                       plus Tidy Bar itself

hide    -> hold a visibility assertion with that allow-list
reveal  -> invalidate the assertion
```

System items have a separate list. Their identities and preservation require independent validation. The visibility interface has no display identifier or width parameter; the natural contract is one shared selection across monitors, not independent per-monitor hiding.

[Stash](https://github.com/brentc22/stash) documents that shared-display contract and provides an app-list UI. It also reports LaunchServices resolution problems when run outside `/Applications`, and a Screen Mirroring problem with a guessed system-item range. These are reasons to test installation identity and enumerate verified system constants, rather than blindly copying an integer range from another project.

## Alternatives

| Approach | Effect on the monitor problem | Decision |
| --- | --- | --- |
| Direct application visibility | Removes spacer width from hiding; macOS reflows remaining items | Recommended for an isolated prototype |
| A floating icon tray | Gives an independent, scrollable access surface; does not itself hide the original icons | Optional later feature, not the hiding fix |
| System menu-bar settings and native overflow | Uses supported user controls, but does not provide our own temporary grouped hide/show | Fallback when direct hiding is unavailable or fails validation |
| More adaptive spacers | Still relies on overflow geometry and undocumented discard behavior | Do not pursue as the general solution |

A tray can use ordinary application icons initially. Real status-icon images and menu forwarding introduce capture and Accessibility work. [baaar's architecture](https://github.com/bylaaabs/baaar/blob/main/docs/ARCHITECTURE.md) separates the visibility bridge, inventory scanner, capture cache and panel; that is useful evidence that the panel and hiding engine are distinct problems.

Apple's public [`NSStatusItem.isVisible`](https://developer.apple.com/documentation/appkit/nsstatusitem/isvisible) operates on a status-item instance and explicitly may return true when insufficient room keeps the item off-screen. It is not a way to set arbitrary other applications' icon visibility or verify physical visibility. No supported general cross-application hiding API was established by this research.

## Material limitations to test

- **Private API:** Apple can change it in an OS update. Load dynamically, validate method signatures, catch exceptions, and show a clear unavailable state. Missing capability must leave our restriction released.
- **Application granularity:** multiple icons from the same bundle share one decision. Do not offer independent toggles that the backend cannot honor.
- **System interactions:** [baaar](https://github.com/bylaaabs/baaar) reports that certain Apple modules disappear under the restriction and Notification Center needs a temporary release. Validate wanted Apple icons, their menus, and all normal Notification Center entry methods, not only clicking the clock.
- **Installation identity:** [SmartHiddenBar](https://github.com/roypadina/SmartHiddenBar) reports that some apps outside `/Applications` are suppressed despite being allow-listed. Preflight wanted items; a successful activation callback does not establish preservation.
- **Inventory lifecycle:** a new app must not remain unintentionally denied by an old allow-list. Refresh on app launch/termination, with cancellation of stale asynchronous completions.
- **Permission scope:** positional inventory and menu interaction in SmartHiddenBar use Accessibility. A prototype with explicit bundle selection and running-app inventory should avoid needing that discovery path, but actual activation without additional permission is still untested here. Screen Recording is unnecessary for the first prototype.
- **Crowded reveal:** releasing the restriction cannot make unlimited icons fit. System overflow can still occur after a successful reveal.

Do not copy invasive system-extra workarounds into the first prototype. [MenuBarHider](https://github.com/happy666End/MenuBarHider) additionally unloads Apple menu extras and reports multi-display setups as untested. Its existence is not evidence that those extensions are suitable for this project.

Recent [Thaw issue #1367](https://github.com/thaw-app/Thaw/issues/1367) reports unstable saved membership on multiple displays. This is a user report, not a reproduced root cause, but reinforces the need to keep our saved selection independent of transient icon positions.

## Concrete prototype and acceptance plan

1. Build a separate experimental app with its own bundle identity and preferences. Preserve the existing packaged Tidy Bar. Provide a settings app picker, one cat toggle, an explicit restore command, and a bounded trial that automatically releases its assertion.
2. Put the runtime bridge in a small Objective-C target. Keep Swift policy, running-app inventory, and UI separate. Model preparing, active, restoring and failed states; reject late activation completions after a reveal or shutdown.
3. Test one chosen third-party app first, with all other known running applications allowed. Record the activation result separately from observed icon disappearance and restoration. Abort if a wanted app or system control is lost.
4. Verify on the laptop alone, external monitor alone, both simultaneously, different scaling settings, primary-display changes, and reconnect. The chosen app must disappear on both bars without spacer gaps; allowed items and the cat must remain usable.
5. Verify crowded app menus, native overflow, Notification Center, Screen Mirroring, full screen, sleep/wake, app relaunch, and fresh apps starting during hiding. Check several icons owned by one bundle explicitly.
6. Verify restore after normal quit and forced process termination. Treat automatic release on process death as a hypothesis until observed locally. Repeat the inventory/position comparison after restoration.
7. Only promote the backend after the behavioral matrix passes. Keep unsupported cases expanded with an explanation; do not silently fall back to the old spacers.

Acceptance is actual disappearance, reflow, usability and recovery on each display. Pure policy tests and success callbacks are supporting evidence only.

## Research boundaries

Public source pages were inspected through web browsing. Upstream branch URLs are mutable; observations are dated above, not pinned to downloaded commits. A direct GitHub source download could not execute: automatic approval failed with HTTP 404, `Requested model is not valid`. The research continued through the available web tool. No upstream code was installed or executed. Only the original read-only probe was run; production app behavior is unchanged.
