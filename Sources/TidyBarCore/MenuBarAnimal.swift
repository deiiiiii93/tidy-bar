public enum MenuBarAnimal: String, CaseIterable, Identifiable {
    case cat, bunny, bear, fox, dog, mouse, pig, owl

    public var id: String { rawValue }
    public var name: String { rawValue.capitalized }

    public static func fromPreference(_ value: String?) -> MenuBarAnimal {
        value.flatMap(MenuBarAnimal.init(rawValue:)) ?? .cat
    }
}
