/// The service operates on whole applications, independent of screen geometry.
public enum NativeVisibilityPlan {
    public static func allowed(running: Set<String>, hidden: Set<String>, own: String) -> [String] {
        running.subtracting(hidden).union([own]).filter { !$0.isEmpty }.sorted()
    }
}

public enum NativeVisibilityState: Equatable, Sendable {
    case expanded
    case preparing
    /// macOS accepted the request. Physical icon visibility is a separate check.
    case active
    case failed(String)
}

@MainActor public protocol VisibilityLease: AnyObject {
    func activate(allowing: [String], completion: @escaping @MainActor (String?) -> Void)
    func invalidate() -> String?
}

@MainActor public protocol VisibilityBackend: AnyObject {
    var unavailableReason: String? { get }
    func makeLease() -> any VisibilityLease
}

/// Owns every pending/active lease. Reveal, replacement and timeout invalidate
/// the lease immediately, even if macOS never calls its completion handler.
@MainActor public final class NativeVisibilityCoordinator {
    public private(set) var state: NativeVisibilityState = .expanded
    public private(set) var revision: UInt64 = 0
    public var onChange: ((NativeVisibilityState) -> Void)?
    private let backend: any VisibilityBackend
    private var lease: (any VisibilityLease)?

    public init(backend: any VisibilityBackend) { self.backend = backend }

    public func hide(running: Set<String>, hidden: Set<String>, own: String) {
        revision &+= 1
        let ticket = revision
        if let error = release() { publish(.failed(error)); return }
        guard !own.isEmpty else { publish(.failed("Tidy Bar has no bundle identity.")); return }
        guard !running.intersection(hidden.subtracting([own])).isEmpty else {
            publish(.expanded)
            return
        }
        if let reason = backend.unavailableReason { publish(.failed(reason)); return }
        let next = backend.makeLease()
        lease = next
        publish(.preparing)
        guard revision == ticket, lease === next else { return }
        next.activate(allowing: NativeVisibilityPlan.allowed(running: running, hidden: hidden, own: own)) { [weak self, weak next] error in
            guard let self, let next else { return }
            guard self.revision == ticket, self.lease === next else {
                // A stale completion can never re-enable hiding.
                _ = next.invalidate()
                return
            }
            if let error {
                let restoreError = self.release()
                self.publish(.failed(restoreError ?? error))
            } else {
                self.publish(.active)
            }
        }
    }

    public func reveal() {
        revision &+= 1
        if let error = release() { publish(.failed(error)) }
        else { publish(.expanded) }
    }

    public func timeout(ticket: UInt64) {
        guard ticket == revision, state == .preparing else { return }
        revision &+= 1
        let restoreError = release()
        publish(.failed(restoreError ?? "macOS did not confirm hiding. The request was cancelled; try again."))
    }

    private func release() -> String? {
        guard let lease else { return nil }
        if let error = lease.invalidate() { return error }
        self.lease = nil
        return nil
    }

    private func publish(_ state: NativeVisibilityState) {
        self.state = state
        onChange?(state)
    }
}
