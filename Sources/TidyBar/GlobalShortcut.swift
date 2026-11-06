import Carbon

@MainActor
final class GlobalShortcut {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var onToggle: (() -> Void)?

    func register() -> Bool {
        let context = Unmanaged.passUnretained(self).toOpaque()
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installed = InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let context, let event else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let result = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard result == noErr, identifier.signature == 0x54494459, identifier.id == 1 else { return OSStatus(eventNotHandledErr) }
            // AppKit dispatches application events on the main thread.
            MainActor.assumeIsolated {
                Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue().onToggle?()
            }
            return noErr
        }, 1, &event, context, &handler)
        guard installed == noErr else { return false }
        let identifier = EventHotKeyID(signature: 0x54494459, id: 1)
        let registered = RegisterEventHotKey(UInt32(kVK_ANSI_B), UInt32(optionKey | cmdKey), identifier, GetApplicationEventTarget(), 0, &hotKey)
        if registered != noErr { unregister() }
        return registered == noErr
    }

    func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
        hotKey = nil
        handler = nil
    }
}
