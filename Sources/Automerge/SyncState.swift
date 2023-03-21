import class AutomergeUniffi.SyncState
import Foundation

typealias FfiSyncState = AutomergeUniffi.SyncState

/// A synchronisation session with another peer
/// The sync protocol is designed to run over a reliable in-order transport with
/// the ``SyncState`` tracking the state between successive calls to
/// ``Document/generateSyncMessage(state:)`` and
/// ``Document/receiveSyncMessage(state:message:)``. Assuming the existence of some
/// network infrastructure for sending and receiving messages on the transport a
/// loop to stay in sync might look like the following
///
/// ```
/// // somehow obtain the document, or create a new one if you have no data
/// let doc: Document = ...
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
/// Sync states can be persisted. If you know a peer might connect to you again
/// you can use ``encode()`` to save the state and ``init(bytes:)`` to decode it.
public struct SyncState {
    var ffi_state: FfiSyncState

    // The heads the other end last reported (`nil` if we haven't received anything from them yet)
    public var theirHeads: Set<ChangeHash>? {
        ffi_state.theirHeads().map { Set($0.map { ChangeHash(bytes: $0) }) }
    }

    public init() {
        ffi_state = FfiSyncState()
    }

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
        self.ffi_state.reset()
    }

    /// Serialize this sync state
    ///
    /// The serialized representation does not include session data which
    /// depends on reliable in-order delivery. I.e. you do not need to call
    /// ``reset()`` on a decoded sync state.
    public func encode() -> Data {
        Data(self.ffi_state.encode())
    }
}
