import AutomergeUniffi

/// An opaque hash that represents a change within an Automerge document.
public struct ChangeHash: Equatable, Hashable, CustomDebugStringConvertible, Sendable {
    var bytes: [UInt8]

    /// The hex value of the change hash.
    public var debugDescription: String {
        bytes.map { String(format: "%02hhx", $0) }.joined()
    }
}

public extension Set<ChangeHash> {

    /// Transforms each `ChangeHash` in the set into its byte array (`[UInt8]`). This raw byte representation
    /// captures the state of the document at a specific point in its history, allowing for efficient storage
    /// and retrieval of document states.
    func raw() -> [[UInt8]] {
        map(\.bytes).sorted { lhs, rhs in
            lhs[0] > rhs[0]
        }
    }
}
