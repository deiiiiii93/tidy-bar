/// Rejects stale auto-hide callbacks after another user action or settings change.
public struct VisibilityPolicy: Sendable {
    public private(set) var isHidden = false
    public private(set) var revision: UInt64 = 0
    public private(set) var delay = 0
    public private(set) var suspended = false

    public init() {}

    public mutating func setHidden(_ hidden: Bool) {
        isHidden = hidden
        revision &+= 1
    }

    public mutating func configure(delay: Int, suspended: Bool) {
        self.delay = max(0, delay)
        self.suspended = suspended
        revision &+= 1
    }

    public var timerTicket: UInt64? {
        !isHidden && !suspended && delay > 0 ? revision : nil
    }

    @discardableResult
    public mutating func autoHide(ticket: UInt64) -> Bool {
        guard timerTicket == ticket else { return false }
        setHidden(true)
        return true
    }
}
