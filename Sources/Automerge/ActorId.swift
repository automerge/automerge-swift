import AutomergeUniffi

/// The identifier for collaborators contributing to an Automerge document.
///
/// Each separate instance of an Automerge document should have it's own, unique, `ActorId`.
/// If you create your own `ActorId`, no concurrent changes should ever be made with the same `ActorId`.
public struct ActorId: Equatable, Hashable {
    internal var bytes: [UInt8]
}

extension ActorId: CustomStringConvertible {
    public var description: String {
        bytes.map { Swift.String(format: "%02hhx", $0) }.joined().uppercased()
    }
}
