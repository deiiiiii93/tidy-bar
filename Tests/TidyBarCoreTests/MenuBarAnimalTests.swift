import Testing
@testable import TidyBarCore

@Test func animalPreferencesRoundTripAndFallBackToCat() {
    for animal in MenuBarAnimal.allCases {
        #expect(MenuBarAnimal.fromPreference(animal.rawValue) == animal)
    }
    #expect(MenuBarAnimal.fromPreference(nil) == .cat)
    #expect(MenuBarAnimal.fromPreference("unknown") == .cat)
}
