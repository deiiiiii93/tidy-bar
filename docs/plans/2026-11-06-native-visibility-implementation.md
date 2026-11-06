# Native visibility implementation

Authorized by the user's “make it happen” after reviewing the native-visibility research.

1. Implement an Objective-C bridge and a Swift lease coordinator. Verify cancellation, timeout, failed activation, failed restoration, superseded callbacks, and new-app allow-list updates with controlled leases.
2. Replace macOS 27 spacers with one cat control and explicit persisted app selection. Preserve the legacy divider only on older releases. Native hiding starts disabled for migration; introduce a ten-second trial and immediate restore. Track running-app changes and expose installation/capability problems. Keep existing auto-hide opt-in behavior.
3. Build, render the settings, package and verify v1.1.0. Preserve the prior bundle. Attempt live inspection and installation through authorized tools; record the exact boundaries if the host session or approval service blocks them. Do not claim multi-monitor success from state labels.

First release is experimental because it depends on a private API. Screen Recording and Accessibility are unnecessary for explicit app selection. A single application selection applies to all displays; macOS retains icon order. Apple system icons are not offered as individually hideable apps. Service-side system preservation and Notification Center behavior require live qualification.
