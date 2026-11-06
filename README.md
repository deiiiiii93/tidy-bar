# Tidy Bar

![Tidy Bar app icon](Resources/AppIcon.png)

**A small, local macOS menu bar companion.** Choose which apps to tuck away, then click the sleepy cat to bring them back.

Tidy Bar has no account, telemetry, or network connection. It is built with SwiftUI and AppKit and keeps its preferences on your Mac.

## Features

- Select apps by name in a searchable list.
- Hide selected apps temporarily for a 10-second trial or until you restore them.
- Restore everything from the menu bar cat, **Show everything**, or **Option–Command–B**.
- Remember app selections and existing auto-hide and login-startup preferences.
- Use a single cat control on macOS 27; keep the draggable divider on macOS 14–26.

## macOS 27: native hiding (experimental)

On macOS 27, Tidy Bar uses a macOS menu bar visibility service to hide selected applications. The selection is based on app bundle identifiers, not screen coordinates, and applies across all monitors. Multiple menu bar icons belonging to one app are hidden together.

**This feature is experimental.** It uses Apple's private `MenuBarClientCore` framework through a runtime-resolved interface. A macOS update may change or remove that interface. Tidy Bar reports when the capability is unavailable or a request fails; it does not silently switch to the older spacer technique.

To use it:

1. Open Settings from the cat's right-click menu, or reopen Tidy Bar in Finder.
2. Turn on **Use native hiding · experimental**.
3. Search for apps and select **Hide** beside the ones you want to tuck away.
4. Choose **Try for 10 seconds** or **Hide selected apps**.
5. Click the cat, press **Option–Command–B**, or choose **Show everything** to restore the menu bar.

Native hiding is off by default during migration. Existing auto-hide, login-startup, and hide-at-launch preferences are preserved, but apps are not selected automatically. Auto-hide pauses while Settings is open.

### Known limitations

- **Native hiding active** means macOS accepted the request; it does not prove that every selected icon disappeared on every display.
- Some Apple menu extras may be affected, and Notification Center may be unavailable while the restriction is active. Restore the menu bar before opening those controls.
- Tidy Bar cannot guarantee that unselected app icons remain visible for known app candidates outside `/Applications`; it refuses the request in that case. Background helpers may appear in the check.
- macOS may still place icons in its overflow area when application menus leave too little room.
- After display, wake, or Space changes, macOS may rearrange the bar. Saved selections remain; click the cat again after the transition.
- Do not run another menu bar organizer that holds a visibility restriction at the same time.

See the [verification notes](docs/verification.md) and [native visibility research](docs/research/2026-11-06-native-visibility.md) for tested behavior and remaining compatibility questions.

## macOS 14–26

On earlier supported macOS versions, Tidy Bar uses a draggable divider. Hold Command and drag icons to the divider's left; keep the cat on its right. This older behavior has not been newly qualified by the macOS 27 verification.

## Install and build

Tidy Bar requires macOS 14 or later, Swift 6, and the Xcode or Command Line Tools SDK. Native hiding requires macOS 27.

Build the app bundle from source:

```sh
./scripts/build.sh
```

The script creates `dist/Tidy Bar.app`, ad hoc signs it for local use, and verifies the signature. Copy it to Applications and launch it from Finder:

```sh
ditto "dist/Tidy Bar.app" "/Applications/Tidy Bar.app"
```

The app is not Developer ID signed or notarized. macOS may require you to approve opening a locally built app. It is not suitable for App Store distribution because native hiding depends on a private Apple framework.

To run the test suite:

```sh
./scripts/test.sh
```

Tests cover visibility request acknowledgement, cancellation, late completion, timeouts, restoration and retry, app-list refresh, auto-hide policy, and legacy spacer layout. They do not prove physical compositor behavior.

## Privacy

- No accounts, telemetry, network requests, or remote package dependencies.
- No Accessibility or Screen Recording permissions.
- App selection uses the running-app inventory; Tidy Bar does not inspect documents or other apps' menus.
- Preferences are stored locally in the `com.tidybar.app` UserDefaults domain.
- Optional login startup uses macOS ServiceManagement.

## License

Tidy Bar is available under the [MIT License](LICENSE).
