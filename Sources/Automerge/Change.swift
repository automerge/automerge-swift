import struct AutomergeUniffi.Change
import Foundation

typealias FfiChange = AutomergeUniffi.Change

public struct Change: Equatable {
    public let actorId: ActorId
    public let message: String?
    public let deps: [ChangeHash]
    public let timestamp: Date
    public let bytes: Data
    public let hash: ChangeHash

    init(_ ffi: FfiChange) {
        actorId = ActorId(bytes: ffi.actorId)
        message = ffi.message
        deps = ffi.deps.map(ChangeHash.init(bytes:))
        timestamp = Date(timeIntervalSince1970: TimeInterval(ffi.timestamp))
        bytes = Data(ffi.bytes)
        hash = ChangeHash(bytes: ffi.hash)
    }
}
