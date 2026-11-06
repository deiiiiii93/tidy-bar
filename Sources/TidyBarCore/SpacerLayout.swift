import Foundation

/// Display geometry in points. On a notched screen, status items occupy only
/// the trailing area; the full screen width is not the amount to displace.
public struct MenuBarDisplay: Equatable, Sendable {
    public let width: Double
    public let statusWidth: Double

    public init(width: Double, statusWidth: Double? = nil) {
        self.width = width
        self.statusWidth = statusWidth ?? width
    }
}

/// Width budget for public NSStatusItem spacers. macOS 27 discards a single
/// oversized item; split the budget below the narrowest status area's cutoff.
public struct SpacerLayout: Equatable, Sendable {
    public let widths: [Double]
    public let coversAllDisplays: Bool
    public static let maximumItems = 7

    public static func make(displays: [MenuBarDisplay], modern: Bool) -> SpacerLayout {
        guard !displays.isEmpty, displays.allSatisfy({
            $0.width.isFinite && $0.width > 0 && $0.statusWidth.isFinite
                && $0.statusWidth > 0 && $0.statusWidth <= $0.width
        }) else {
            return SpacerLayout(widths: [], coversAllDisplays: false)
        }
        let widest = displays.map(\.width).max()!
        if !modern {
            let length = min(10_000, widest * 2)
            return SpacerLayout(widths: [length], coversAllDisplays: length > widest)
        }
        // Conservative cap: below half of every available status area.
        let limit = floor(displays.map(\.statusWidth).min()! / 2 - 64)
        guard limit >= 22 else {
            return SpacerLayout(widths: [], coversAllDisplays: false)
        }
        let budget = displays.map(\.statusWidth).max()!
        let count = min(maximumItems, Int(ceil(budget / limit)))
        return SpacerLayout(widths: Array(repeating: limit, count: count), coversAllDisplays: Double(count) * limit >= budget)
    }
}

/// Length zero alone does not deactivate an item in macOS's overflow layout.
/// Keep identities registered, but make inactive helper items explicitly absent.
@MainActor
public protocol SpacerItem: AnyObject {
    var length: CGFloat { get set }
    var isVisible: Bool { get set }
}

@MainActor
public enum SpacerVisibility {
    public static func apply(widths: [Double], to items: [any SpacerItem]) {
        for (index, item) in items.enumerated() {
            let width = index < widths.count ? widths[index] : 0
            if width.isFinite && width > 0 {
                item.length = CGFloat(width)
                item.isVisible = true
            } else {
                item.isVisible = false
                item.length = 0
            }
        }
    }
}
