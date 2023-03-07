import struct AutomergeUniffi.Patch
import enum AutomergeUniffi.PatchAction

typealias FfiPatchAction = AutomergeUniffi.PatchAction
typealias FfiPatch = AutomergeUniffi.Patch

/// A collection of changes to an Automerge document.
public struct Patch: Equatable {
    /// The type change
    public let action: PatchAction

    /// The path to the object identifier the action effects.
    public let path: [PathElement]

    /// Creates a new patch
    /// - Parameters:
    ///   - action: The type of change
    ///   - path: A collection of the paths to apply the change.
    public init(action: PatchAction, path: [PathElement]) {
        self.action = action
        self.path = path
    }

    init(_ ffi: FfiPatch) {
        self.path = ffi.path.map(PathElement.fromFfi)
        self.action = PatchAction.fromFfi(ffi.action)
    }
}

/// The type of change to apply along with the data to change.
public enum PatchAction: Equatable {
    /// Put a new value at the property for the identified object.
    case Put(ObjId, Prop, Value)
    /// Insert a collection of values at the index you provide for the identified object.
    case Insert(ObjId, UInt64, [Value])
    /// Splices characters into and/or removes characters from the identified object at a given position within it.
    case SpliceText(ObjId, UInt64, String)
    /// Increment the property of the identified object by the value you provide.
    case Increment(ObjId, Prop, Int64)
    /// Delete a key from a identified object.
    case DeleteMap(ObjId, String)
    /// Delete a sequence from the identified object starting at the index you provide for the length you provide.
    case DeleteSeq(DeleteSeq)

    static func fromFfi(_ ffi: FfiPatchAction) -> Self {
        switch ffi {
        case let .put(obj, prop, value):
            return .Put(ObjId(bytes: obj), Prop.fromFfi(prop), Value.fromFfi(value: value))
        case let .insert(obj, index, values):
            return .Insert(ObjId(bytes: obj), index, values.map { Value.fromFfi(value: $0) })
        case let .spliceText(obj, index, value):
            return .SpliceText(ObjId(bytes: obj), index, value)
        case let .increment(obj, prop, value):
            return .Increment(ObjId(bytes: obj), Prop.fromFfi(prop), value)
        case let .deleteMap(obj, key):
            return .DeleteMap(ObjId(bytes: obj), key)
        case let .deleteSeq(obj, index, length):
            return .DeleteSeq(Automerge.DeleteSeq(obj: ObjId(bytes: obj), index: index, length: length))
        }
    }
}

/// A sequence of deletions.
public struct DeleteSeq: Equatable {
    /// The object to which the delete applies.
    public let obj: ObjId
    /// The index location of the start of the deletion.
    public let index: UInt64
    /// The number of elements to delete.
    public let length: UInt64

    public init(obj: ObjId, index: UInt64, length: UInt64) {
        self.obj = obj
        self.index = index
        self.length = length
    }
}
