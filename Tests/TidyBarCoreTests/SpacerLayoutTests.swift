import Foundation
import Testing
@testable import TidyBarCore

@Test func modernSpacersStayBelowDiscardThreshold() {
    for width in [1024.0, 1440, 1728, 2560, 3840] {
        let layout = SpacerLayout.make(displays: [.init(width: width)], modern: true)
        #expect(layout.coversAllDisplays)
        #expect(layout.widths.count > 1)
        #expect(layout.widths.allSatisfy { $0 < width / 2 })
        #expect(layout.widths.reduce(0, +) >= width)
        #expect(layout.widths.dropLast().reduce(0, +) < width)
    }
}

@Test func notchDoesNotFillTheUnavailablePartOfTheDisplay() {
    let layout = SpacerLayout.make(displays: [.init(width: 1512, statusWidth: 650)], modern: true)
    #expect(layout.coversAllDisplays)
    #expect(layout.widths.allSatisfy { $0 < 650 / 2 })
    #expect(layout.widths.reduce(0, +) >= 650)
    #expect(layout.widths.dropLast().reduce(0, +) < 650)
    #expect(layout.widths.reduce(0, +) < 1512)
}

@Test func mixedDisplaysRespectSmallestLimit() {
    let layout = SpacerLayout.make(displays: [.init(width: 1440), .init(width: 3840)], modern: true)
    #expect(layout.coversAllDisplays)
    #expect(layout.widths.count <= SpacerLayout.maximumItems)
    #expect(layout.widths.allSatisfy { $0 < 1440 / 2 })
    #expect(layout.widths.reduce(0, +) >= 3840)
}

@Test func unsupportedLayoutDoesNotClaimCoverage() {
    let layout = SpacerLayout.make(displays: [.init(width: 1024), .init(width: 10_000)], modern: true)
    #expect(!layout.coversAllDisplays)
    #expect(layout.widths.count == SpacerLayout.maximumItems)
    #expect(!SpacerLayout.make(displays: [], modern: true).coversAllDisplays)
    #expect(!SpacerLayout.make(displays: [.init(width: .nan)], modern: true).coversAllDisplays)
    #expect(!SpacerLayout.make(displays: [.init(width: 1024, statusWidth: 2000)], modern: true).coversAllDisplays)
}

@Test func legacyUsesOneBoundedSpacer() {
    let layout = SpacerLayout.make(displays: [.init(width: 1728)], modern: false)
    #expect(layout.widths == [3456])
    #expect(layout.coversAllDisplays)
}

@MainActor private final class RecordedSpacer: SpacerItem {
    var length: CGFloat = 0
    var isVisible = true
}

@Test @MainActor func restoringDeactivatesEveryPreviouslyInflatedHelper() {
    let helpers = (0..<6).map { _ in RecordedSpacer() }
    SpacerVisibility.apply(widths: [600, 600, 600], to: helpers)
    #expect(helpers.prefix(3).allSatisfy { $0.isVisible && $0.length == 600 })
    #expect(helpers.suffix(3).allSatisfy { !$0.isVisible && $0.length == 0 })
    SpacerVisibility.apply(widths: [], to: helpers)
    #expect(helpers.allSatisfy { !$0.isVisible && $0.length == 0 })
    SpacerVisibility.apply(widths: [400], to: helpers)
    #expect(helpers[0].isVisible && helpers[0].length == 400)
    #expect(helpers.dropFirst().allSatisfy { !$0.isVisible && $0.length == 0 })
}

@Test @MainActor func repeatedRestoreIsIdempotent() {
    let helpers = (0..<6).map { _ in RecordedSpacer() }
    for _ in 0..<3 { SpacerVisibility.apply(widths: [], to: helpers) }
    #expect(helpers.allSatisfy { !$0.isVisible && $0.length == 0 })
}
