import SwiftUI
import ServiceManagement
import TidyBarCore

private enum Palette {
    static let ink = Color(red: 0.16, green: 0.26, blue: 0.22)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let mint = Color(red: 0.85, green: 0.92, blue: 0.86)
    static let muted = Color(red: 0.39, green: 0.45, blue: 0.40)
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var search = ""
    @State private var selectedOnly = false

    private var filteredApps: [SelectableApp] {
        model.applications.filter {
            (!selectedOnly || model.hiddenBundleIDs.contains($0.id))
                && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
                    || $0.id.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(nsImage: CatArtwork.appIcon(size: 160))
                        .resizable().frame(width: 64, height: 64).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tidy Bar").font(.system(size: 27, weight: .bold, design: .rounded))
                        Text("A little room to breathe.").font(.system(size: 13)).foregroundStyle(Palette.muted)
                    }
                    Spacer()
                    Text("LOCAL & LOVELY").font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(9).background(Palette.mint, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(model.stateLabel.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1)
                        .accessibilityIdentifier("visibilityState")
                    Text(model.usesNative ? "Choose your calm." : "Your menu bar, tidied.")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                    Text(model.usesNative ? "The same apps tuck away on every display. Click your animal to bring them back." : "Hold ⌘ and drag icons left of the divider. Keep your animal on its right.")
                        .font(.system(size: 12)).foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button(model.wantsHidden ? "Show everything" : (model.usesNative ? "Hide selected apps" : "Hide icons")) { model.toggle() }
                            .buttonStyle(.borderedProminent).tint(Palette.ink)
                            .accessibilityIdentifier("toggleVisibility")
                        if model.usesNative {
                            Button("Try for 10 seconds") { model.runTrial() }
                                .disabled(!model.nativeEnabled || model.hiddenBundleIDs.isEmpty || model.trialActive)
                        }
                        Spacer()
                    }
                }.padding(18).background(Palette.mint.opacity(0.62), in: RoundedRectangle(cornerRadius: 16))

                if let error = model.visibilityError {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(error).font(.caption).foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
                        Button("Show everything") { model.setHidden(false) }
                    }.padding(12).background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 10))
                }

                animalPicker

                if model.usesNative { appPicker }

                VStack(spacing: 0) {
                    HStack {
                        Label("Tuck away automatically", systemImage: "moon.zzz")
                        Spacer()
                        Picker("Tuck away automatically", selection: $model.autoHideDelay) {
                            Text("Never").tag(0)
                            Text("After 10 seconds").tag(10)
                            Text("After 30 seconds").tag(30)
                            Text("After 1 minute").tag(60)
                        }.labelsHidden().frame(width: 155)
                    }.padding(.vertical, 10)
                    Divider().opacity(0.5)
                    Toggle("Start with selected apps hidden", isOn: $model.hideAtLaunch).padding(.vertical, 10)
                    Divider().opacity(0.5)
                    Toggle("Launch at login", isOn: Binding(get: { model.loginEnabled }, set: model.setLoginEnabled)).padding(.vertical, 10)
                    if model.loginNeedsApproval {
                        Button("Approve in Login Items…") { SMAppService.openSystemSettingsLoginItems() }.padding(.bottom, 8)
                    }
                    if let error = model.loginError {
                        Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled).padding(.bottom, 8)
                    }
                }.font(.system(size: 12)).toggleStyle(.switch).controlSize(.small)
                    .padding(.horizontal, 16).background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.shortcutAvailable ? "⌥ ⌘ B · Hide or show from anywhere" : "Shortcut unavailable · another app may use ⌥⌘B")
                        .font(.system(size: 11, weight: .medium))
                    Text("Auto-hide pauses here. Right-click your animal for settings. · v1.1.0")
                        .font(.system(size: 10)).foregroundStyle(Palette.muted)
                }
            }.padding(24)
        }
        .foregroundStyle(Palette.ink)
        .frame(width: 560, height: 730)
        .background(Palette.paper)
        .preferredColorScheme(.light)
    }

    private var animalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your menu bar companion")
                .font(.system(size: 13, weight: .semibold))
            Text("Choose a little face for your menu bar.")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(MenuBarAnimal.allCases) { animal in
                    Button { model.menuBarAnimal = animal } label: {
                        VStack(spacing: 4) {
                            Image(nsImage: AnimalArtwork.menuImage(animal: animal, hidden: false, size: 38))
                                .renderingMode(.template).resizable().frame(width: 38, height: 38)
                            Text(animal.name).font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(model.menuBarAnimal == animal ? Palette.mint : Palette.paper,
                                    in: RoundedRectangle(cornerRadius: 9))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .stroke(model.menuBarAnimal == animal ? Palette.ink : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(animal.name)
                    .accessibilityValue(model.menuBarAnimal == animal ? "Selected" : "Not selected")
                    .accessibilityIdentifier("animal.\(animal.rawValue)")
                }
            }
        }.padding(16).background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
    }

    private var appPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Use native hiding · experimental", isOn: $model.nativeEnabled)
                .font(.system(size: 13, weight: .semibold)).toggleStyle(.switch)
                .accessibilityIdentifier("nativeEnabled")
            Text("Choose apps below. All icons from one app hide together. Some listed apps have no menu bar icon.")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("Unlisted background apps and apps outside /Applications are hidden by default while native hiding is active.")
                .font(.system(size: 11)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                TextField("Search apps", text: $search).textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("appSearch")
                Toggle("Selected", isOn: $selectedOnly).toggleStyle(.checkbox).font(.system(size: 11))
                Button { model.refreshApplications() } label: { Image(systemName: "arrow.clockwise") }
                    .help("Refresh running apps").accessibilityLabel("Refresh apps")
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    if filteredApps.isEmpty {
                        Text(search.isEmpty ? "No apps to display. Open a menu bar app and refresh." : "No matching apps.")
                            .font(.caption).foregroundStyle(Palette.muted).padding(20)
                    }
                    ForEach(filteredApps) { app in
                        HStack(spacing: 10) {
                            if let icon = app.icon { Image(nsImage: icon).resizable().frame(width: 24, height: 24) }
                            else { Image(systemName: "app.dashed").frame(width: 24, height: 24) }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                Text(app.isRunning ? app.id : "Not running · \(app.id)")
                                    .font(.system(size: 9)).foregroundStyle(Palette.muted).lineLimit(1)
                            }.help(app.id)
                            Spacer(minLength: 8)
                            Toggle("Hide", isOn: Binding(
                                get: { model.hiddenBundleIDs.contains(app.id) },
                                set: { model.setAppHidden(app.id, hidden: $0) }
                            )).toggleStyle(.checkbox).font(.system(size: 11))
                                .accessibilityLabel("Hide \(app.name)")
                                .accessibilityIdentifier("hideApp.\(app.id)")
                        }.padding(.horizontal, 10).padding(.vertical, 9)
                        Divider().opacity(0.35)
                    }
                }
            }.frame(height: 190).background(Palette.paper, in: RoundedRectangle(cornerRadius: 10))
            Text("\(model.hiddenBundleIDs.count) selected · Apple system items are not selectable")
                .font(.system(size: 10)).foregroundStyle(Palette.muted)
            Text("Experimental: some Apple icons and Notification Center may be affected while hiding. Show everything releases the restriction.")
                .font(.system(size: 10)).foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(16).background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
    }
}
