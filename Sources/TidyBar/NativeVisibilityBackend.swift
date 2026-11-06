import NativeMenuBar
import TidyBarCore

@MainActor final class NativeMenuBarBackend: VisibilityBackend {
    var unavailableReason: String? { TBMenuBarSession.unavailableReason() }
    func makeLease() -> any VisibilityLease { NativeMenuBarLease() }
}

@MainActor private final class NativeMenuBarLease: VisibilityLease {
    private let session = TBMenuBarSession()
    func activate(allowing: [String], completion: @escaping @MainActor (String?) -> Void) {
        session.activateAllowingBundles(allowing) { error in
            // The bridge always delivers on the main queue.
            MainActor.assumeIsolated { completion(error?.localizedDescription) }
        }
    }
    func invalidate() -> String? { session.releaseRestriction()?.localizedDescription }
}
