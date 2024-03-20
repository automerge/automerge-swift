import AutomergeUniffi
import Foundation

/// The identifier for collaborators contributing to an Automerge document.
///
/// Each separate instance of an Automerge document should have it's own, unique, `ActorId`.
/// If you create your own `ActorId`, no concurrent changes should ever be made with the same `ActorId`.
public struct ActorId: Equatable, Hashable, Sendable {
    var data: Data

    init(ffi: AutomergeUniffi.ActorId) {
        data = Data(ffi)
    }

    // Creates a new, random actor.
    public init() {
        self.init(uuid: UUID())
    }

    // Creates an actor from a UUID.
    public init(uuid: UUID) {
        data = withUnsafeBytes(of: uuid.uuid, { Data($0) })
    }

    // Creates an actor from data.
    public init?(data: Data) {
        guard data.count <= 128 else {
            return nil
        }
        self.data = data
    }
}

extension ActorId: CustomStringConvertible {
    public var description: String {
        data.map { String(format: "%02hhX", $0) }.joined()
    }
}
