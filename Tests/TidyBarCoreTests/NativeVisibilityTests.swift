import Testing
@testable import TidyBarCore

@MainActor private final class ControlledLease: VisibilityLease {
    var allowed: [String] = []
    var completion: (@MainActor (String?) -> Void)?
    var releases = 0
    var releaseError: String?
    func activate(allowing: [String], completion: @escaping @MainActor (String?) -> Void) {
        allowed = allowing
        self.completion = completion
    }
    func invalidate() -> String? { releases += 1; return releaseError }
    func finish(_ error: String? = nil) { completion?(error) }
}

@MainActor private final class ControlledBackend: VisibilityBackend {
    var unavailableReason: String?
    var leases: [ControlledLease] = []
    func makeLease() -> any VisibilityLease {
        let lease = ControlledLease()
        leases.append(lease)
        return lease
    }
}

@Test func nativePlanNeverHidesItsOwnControl() {
    #expect(NativeVisibilityPlan.allowed(running: ["chosen", "keep", "tidy", ""], hidden: ["chosen", "tidy"], own: "tidy") == ["keep", "tidy"])
}

@Test @MainActor func nativeWaitsForAcknowledgementAndReleasesOnReveal() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen", "keep"], hidden: ["chosen"], own: "tidy")
    #expect(coordinator.state == .preparing)
    #expect(backend.leases[0].allowed == ["keep", "tidy"])
    backend.leases[0].finish()
    #expect(coordinator.state == .active)
    coordinator.reveal()
    #expect(coordinator.state == .expanded)
    #expect(backend.leases[0].releases == 1)
}

@Test @MainActor func revealCancelsPendingRequestAndRejectsLateSuccess() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    coordinator.reveal()
    #expect(backend.leases[0].releases == 1)
    backend.leases[0].finish()
    #expect(coordinator.state == .expanded)
    #expect(backend.leases[0].releases == 2)
}

@Test @MainActor func timeoutReleasesEvenWithoutAnActivationCallback() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    coordinator.timeout(ticket: coordinator.revision)
    if case .failed = coordinator.state {} else { Issue.record("Timeout must report failure") }
    #expect(backend.leases[0].releases == 1)
    backend.leases[0].finish()
    if case .failed = coordinator.state {} else { Issue.record("Late completion must not undo timeout") }
}

@Test @MainActor func refreshedInventoryAllowsNewAppAndRejectsOldCallbacks() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen", "keep"], hidden: ["chosen"], own: "tidy")
    let oldTicket = coordinator.revision
    coordinator.hide(running: ["chosen", "keep", "newApp"], hidden: ["chosen"], own: "tidy")
    #expect(backend.leases[0].releases == 1)
    #expect(backend.leases[1].allowed == ["keep", "newApp", "tidy"])
    coordinator.timeout(ticket: oldTicket)
    backend.leases[0].finish("Old failure")
    #expect(coordinator.state == .preparing)
    backend.leases[1].finish()
    #expect(coordinator.state == .active)
}

@Test @MainActor func failedRefreshReleasesTheReplacement() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    backend.leases[0].finish()
    coordinator.hide(running: ["chosen", "new"], hidden: ["chosen"], own: "tidy")
    backend.leases[1].finish("Denied by service")
    #expect(coordinator.state == .failed("Denied by service"))
    #expect(backend.leases.allSatisfy { $0.releases == 1 })
}

@Test @MainActor func failedRestorationKeepsTheLeaseForRetry() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    backend.leases[0].finish()
    backend.leases[0].releaseError = "Restore failed"
    coordinator.reveal()
    #expect(coordinator.state == .failed("Restore failed"))
    backend.leases[0].releaseError = nil
    coordinator.reveal()
    #expect(coordinator.state == .expanded)
    #expect(backend.leases[0].releases == 2)
}

@Test @MainActor func emptyOrOfflineSelectionsHoldNoRestriction() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["keep"], hidden: ["offline"], own: "tidy")
    #expect(coordinator.state == .expanded)
    #expect(backend.leases.isEmpty)
    coordinator.hide(running: ["tidy"], hidden: ["tidy"], own: "tidy")
    #expect(backend.leases.isEmpty)
}

@Test @MainActor func unavailableBackendDoesNotCreateAnAssertion() {
    let backend = ControlledBackend()
    backend.unavailableReason = "Interface changed"
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    #expect(coordinator.state == .failed("Interface changed"))
    #expect(backend.leases.isEmpty)
}

@Test @MainActor func reentrantRevealDoesNotStartTheCancelledLease() {
    let backend = ControlledBackend()
    let coordinator = NativeVisibilityCoordinator(backend: backend)
    coordinator.onChange = { state in if state == .preparing { coordinator.reveal() } }
    coordinator.hide(running: ["chosen"], hidden: ["chosen"], own: "tidy")
    #expect(coordinator.state == .expanded)
    #expect(backend.leases[0].allowed.isEmpty)
    #expect(backend.leases[0].releases == 1)
}
