import class AutomergeUniffi.SyncState
import Foundation

typealias FfiSyncState = AutomergeUniffi.SyncState

/// The state of a synchronisation session with another peer.
///
/// Use ``encode()`` to generate a byte representation of the SyncState to persist it, and use ``init(bytes:)`` to initialize a new instance from those bytes.
///
/// The sync protocol is designed to run over a reliable in-order transport with
/// the ``SyncState`` tracking the state between successive calls to
/// ``Document/generateSyncMessage(state:)`` and
/// ``Document/receiveSyncMessage(state:message:)``. 
///
/// The following code example illustrates using `SyncState` to generate and receive one side of a network sync.
/// ```swift
/// let doc = Document()
/// let state = SyncState()
/// repeat {
///    if let msg = doc.generateSyncMessage(state) {
///        await network.send(msg)
///    }
///    let response = await network.receive() {
///        try! doc.receiveSyncMessage(state, response)
///    }
/// }
/// ```
///
/// For a more thorough example of sync, see <doc:ChangesAndHistory>.
public struct SyncState: @unchecked Sendable {
    fileprivate let queue = DispatchQueue(label: "automerge-syncstate-queue", qos: .userInteractive)

    var ffi_state: FfiSyncState
    // NOTE(heckj): `FfiSyncState` is a fully generated reference type, which I would
    // otherwise make Sendable down when it's being generated, but instead I'm doing it "up one layer"
    // in this wrapping type, and serializing the interaction with the type through a serial
    // dispatch queue in order to accommodate marking the wrapping class as `unchecked @Sendable`.

    /// The heads last reported by a peer.
    ///
    /// Use ``Document/receiveSyncMessage(state:message:)`` to update a sync state, which updates this value.
    public var theirHeads: Set<ChangeHash>? {
        queue.sync {
            ffi_state.theirHeads().map { Set($0.map { ChangeHash(bytes: $0) }) }
        }
    }
    
    /// Create a new, empty sync state.
    public init() {
        ffi_state = FfiSyncState()
    }
    
    /// Create a sync state from data.
    /// - Parameter bytes: The data that represents a serialized sync state.
    ///
    /// Serialize a sync state using ``SyncState/encode()``.
    public init(bytes: Data) throws {
        self.ffi_state = try wrappedErrors { try FfiSyncState.decode(bytes: Array(bytes)) }
    }

    /// Reset the state if the connection is interrupted
    ///
    /// Some of the state in a ``SyncState`` relies on the reliable, in-order
    /// nature of the transport. If a connection has dropped and this can no
    /// longer be relied (messages may have been lost, or may be redelivered
    /// etc. etc.) then you must call ``reset()`` before continuing to synch.
    public func reset() {
        queue.sync {
            self.ffi_state.reset()
        }
    }

    /// Serialize this sync state
    ///
    /// The serialized representation does not include session data which
    /// depends on reliable in-order delivery. That is, you don'o't need to call
    /// ``reset()`` on a decoded sync state.
    public func encode() -> Data {
        queue.sync {
            Data(self.ffi_state.encode())
        }
    }
}
