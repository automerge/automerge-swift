import AutomergeUniffi

/// The unique internal identifier for an object stored in an Automerge document.
public struct ObjId: Hashable, Sendable {
    var bytes: [UInt8]
    /// The root identifier for an Automerge document.
    public static let ROOT = ObjId(bytes: AutomergeUniffi.root())
}

// Equality and hashing match Automerge's own object IDs: two IDs refer to the same object when their
// actor and counter match. The serialized bytes also carry an actor index, which is only a lookup hint
// local to the document that produced the ID. It can change when a merge or sync adds actors, so the
// same object can come back with different bytes, and it's excluded here.
extension ObjId {
    public static func == (lhs: ObjId, rhs: ObjId) -> Bool {
        let lhsIdentity = lhs.identity
        let rhsIdentity = rhs.identity
        return lhsIdentity.actor == rhsIdentity.actor && lhsIdentity.counter == rhsIdentity.counter
    }

    public func hash(into hasher: inout Hasher) {
        let identity = identity
        hasher.combine(identity.actor.count)
        identity.actor.withUnsafeBytes { hasher.combine(bytes: $0) }
        identity.counter.withUnsafeBytes { hasher.combine(bytes: $0) }
    }

    /// The bytes that identify the object, split around the actor index that sits between them.
    ///
    /// Automerge serializes an object ID as a tag byte, the uLEB128 length of the actor ID, the actor ID
    /// bytes, the uLEB128 actor index, and the uLEB128 counter. `actor` covers everything up to the end of
    /// the actor ID, and `counter` is the trailing counter. The root ID, and any bytes that don't follow
    /// this layout, are compared as a whole.
    private var identity: (actor: ArraySlice<UInt8>, counter: ArraySlice<UInt8>) {
        let wholeID = (actor: bytes[...], counter: bytes[bytes.endIndex...])
        guard bytes.count > 1,
              let (actorLength, actorStart) = Self.readULEB128(bytes, at: 1),
              actorLength <= UInt64(bytes.count - actorStart)
        else {
            return wholeID
        }
        let actorEnd = actorStart + Int(actorLength)
        guard let (_, counterStart) = Self.readULEB128(bytes, at: actorEnd),
              counterStart < bytes.endIndex
        else {
            return wholeID
        }
        return (actor: bytes[..<actorEnd], counter: bytes[counterStart...])
    }

    /// Reads an unsigned LEB128 value starting at `index`, returning it with the index just past it.
    private static func readULEB128(_ bytes: [UInt8], at index: Int) -> (value: UInt64, next: Int)? {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        var index = index
        while index < bytes.endIndex, shift < 64 {
            let byte = bytes[index]
            value |= UInt64(byte & 0x7F) << shift
            index += 1
            if byte & 0x80 == 0 {
                return (value, index)
            }
            shift += 7
        }
        return nil
    }
}

extension ObjId: CustomDebugStringConvertible {
    public var debugDescription: String {
        if bytes == AutomergeUniffi.root() {
            return "ObjId.ROOT"
        } else {
            return "ObjId(\(bytes.map { Swift.String(format: "%02hhx", $0) }.joined()))"
        }
    }
}
