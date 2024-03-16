import AutomergeUniffi
import Foundation

/// The identifier for collaborators contributing to an Automerge document.
///
/// Each separate instance of an Automerge document should have it's own, unique, `ActorId`.
/// If you create your own `ActorId`, no concurrent changes should ever be made with the same `ActorId`.
public struct ActorId: Equatable, Hashable, Sendable {
    var data: Data

    public init(data: Data) {
        self.data = data
    }
}

extension ActorId: CustomStringConvertible {
    public var description: String {
        data.map { String(format: "%02hhX", $0) }.joined()
    }
}
