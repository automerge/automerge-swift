import AutomergeUniffi
import Foundation

/// The identifier for collaborators contributing to an Automerge document.
///
/// Each instance of an Automerge document should have its own, unique, `ActorId`.
/// A new, or forked, Automerge document automatically creates its own ActorId.
///
/// > Warning: It is an error in Automerge to make two concurrent changes to an Automerge document with the same
/// ActorId.
/// When you create your own ActorIds, you are responsible to enforce that two concurrent changes on a document does not
/// happen.
/// Because of this, Automerge recommends that you use the default ActorId that it provides.
public struct ActorId: Equatable, Hashable, Sendable {
    var data: Data

    init(ffi: AutomergeUniffi.ActorId) {
        data = Data(ffi)
    }

    /// Creates a random Actor Id.
    public init() {
        self.init(uuid: UUID())
    }

    /// Creates an Actor Id from the contents of a UUID you provide.
    public init(uuid: UUID) {
        data = withUnsafeBytes(of: uuid.uuid) { Data($0) }
    }

    /// Creates an Actor Id from the data you provide.
    /// - Parameter data: A maximum of 128 bytes that represents the Actor Id.
    ///
    /// ActorId imposes a limit of 128 bytes for the data that represents the actor Id.
    ///
    /// > Warning: It is an error in Automerge to make two concurrent changes to an Automerge document with the same
    /// ActorId.
    /// When you create your own ActorIds, you are responsible to enforce that two concurrent changes on a document does
    /// not happen.
    /// Because of this, Automerge recommends that you use the default ActorId that it provides.
    public init?(data: Data) {
        guard data.count <= 128 else {
            return nil
        }
        self.data = data
    }
}

extension ActorId: CustomStringConvertible {
    /// A hex-encoded string that represents the bytes of the Actor Id.
    public var description: String {
        data.map { String(format: "%02hhX", $0) }.joined()
    }
}
