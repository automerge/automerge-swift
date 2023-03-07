import AutomergeUniffi

/// An opaque hash that represents a change within an Automerge document.
public struct ChangeHash: Equatable, Hashable, CustomDebugStringConvertible {
    internal var bytes: [UInt8]

    /// The hex value of the change hash.
    public var debugDescription: String {
        bytes.map { String(format: "%02hhx", $0) }.joined()
    }
}
