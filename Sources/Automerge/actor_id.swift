import AutomergeUniffi

/// A type that represents a collaboration instance for managing replication within an Automerge document.
public struct ActorId: Equatable, Hashable {
    internal var bytes: [UInt8]
}
