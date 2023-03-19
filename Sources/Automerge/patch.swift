import struct AutomergeUniffi.Patch
import enum AutomergeUniffi.PatchAction

typealias FfiPatchAction = AutomergeUniffi.PatchAction
typealias FfiPatch = AutomergeUniffi.Patch

/// A collection of updates applied to an Automerge document.
///
/// A patch can be received from applying updates to an Automerge document with one of the following methods:
/// -  ``Document/applyEncodedChangesWithPatches(encoded:)``
/// - ``Document/receiveSyncMessageWithPatches(state:message:)``
/// - ``Document/mergeWithPatches(other:)``.
///
/// You can inspect these patches to identify the objects updated within the Automerge document, in order to react
/// accordingly within your code.
/// A common use case for inspecting patches is to recalculate derived data that is using Automerge as an authoritative
/// source.
public struct Patch: Equatable {
    /// The the type of change, and the value that patch updated, if relevant to the change.
    public let action: PatchAction

    /// The path to the object that the update effects.
    ///
    /// The path doesn't identify the property or index being updated on that object, that information is contained with
    /// the associated `action`.
    public let path: [PathElement]

    /// Creates a new patch
    /// - Parameters:
    ///   - action: The kind of update to apply.
    ///   - path: The path to the object identifier that the action effects.
    ///
    ///   The `path` does not identify the property on an object, or index in a sequence, that is updated, only the
    /// object that is effected.
    ///   The `action` includes the type of change, and the value being updated, if relevant to the change.
    init(action: PatchAction, path: [PathElement]) {
        self.action = action
        self.path = path
    }

    init(_ ffi: FfiPatch) {
        self.path = ffi.path.map(PathElement.fromFfi)
        self.action = PatchAction.fromFfi(ffi.action)
    }
}

/// The type of change the library applied to an Automerge document, along with the data that changed.
public enum PatchAction: Equatable {
    /// Put a new value at the property for the identified object.
    ///
    /// The property included within the `Put` can be either an index to a sequence, or a key into a map.
    case Put(ObjId, Prop, Value)
    /// Insert a collection of values at the index you provide for the identified object.
    case Insert(ObjId, UInt64, [Value])
    /// Splices characters into and/or removes characters from the identified object at a given position within it.
    ///
    /// > Note: The unsigned 64bit integer is the index to a UTF-8 code point, and not a grapheme cluster index.
    /// If you are working with `Characters` from a `String`, you will need to calculate the offset to insert it
    /// correctly.
    case SpliceText(ObjId, UInt64, String)
    /// Increment the property of the identified object, typically a Counter.
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
