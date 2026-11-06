// Read-only inspection of Swift enum metadata from the installed framework.
// This is a research executable, not linked into Tidy Bar. No service activation.
import Foundation
import Darwin

func enumerate<T: CaseIterable>(_ type: T.Type) -> [Int] {
    type.allCases.compactMap { ($0 as? any RawRepresentable)?.rawValue as? Int }.sorted()
}

guard let handle = dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore", RTLD_NOW),
      let symbol = dlsym(handle, "$s17MenuBarClientCore22MBSystemItemIdentifierOMa") else {
    fputs("System-item metadata accessor unavailable\n", stderr)
    exit(1)
}
// Swift ABI metadata request 0 requests complete metadata. The accessor returns
// metadata in the first result register; no value of the private enum is forged.
let accessor = unsafeBitCast(symbol, to: (@convention(c) (UInt) -> UnsafeRawPointer).self)
let type = unsafeBitCast(accessor(0), to: Any.Type.self)
guard let iterable = type as? any CaseIterable.Type else {
    fputs("System-item CaseIterable conformance unavailable\n", stderr)
    exit(1)
}
let result: [String: Any] = [
    "os": ProcessInfo.processInfo.operatingSystemVersionString,
    "enum": String(reflecting: type),
    "rawValues": enumerate(iterable),
    "activationAttempted": false
]
let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
print(String(decoding: data, as: UTF8.self))
