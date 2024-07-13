import AutomergeUniffi
import Foundation

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
    func raw() -> Data {
        let rawBytes = map(\.bytes).sorted { lhs, rhs in
            lhs.debugDescription > rhs.debugDescription
        }
        return Data(rawBytes.joined())
    }
}

public extension Data {
    /// Interprets the data to return the data as a set of change hashes that represent a state within an Automerge
    /// document. If the data is not a multiple of 32 bytes, returns nil.
    func heads() -> Set<ChangeHash>? {
        let rawBytes: [UInt8] = Array(self)
        guard rawBytes.count % 32 == 0 else { return nil }
        let totalHashes = rawBytes.count / 32
        let heads = (0 ..< totalHashes).map { index in
            let lowerBound = index * 32
            let upperBound = (index + 1) * 32
            let bytes = rawBytes[lowerBound ..< upperBound]
            return ChangeHash(bytes: Array(bytes))
        }
        return Set(heads)
    }
}
