import AutomergeUniffi

/// The unique internal identifier for an object stored in an Automerge document.
public struct ObjId: Equatable, Hashable, Sendable {
    internal var bytes: [UInt8]
    /// The root identifier for an Automerge document.
    public static let ROOT = ObjId(bytes: AutomergeUniffi.root())
}

extension ObjId: CustomDebugStringConvertible {
    public var debugDescription: String {
        if bytes == AutomergeUniffi.root() {
            return "ObjId.ROOT"
        } else {
            return "ObjId(\(bytes.map { Swift.String(format: "%02hhx", $0) }.joined())"
        }
    }
}
