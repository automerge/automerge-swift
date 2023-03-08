import struct AutomergeUniffi.Patch
import enum AutomergeUniffi.PatchAction

typealias FfiPatchAction = AutomergeUniffi.PatchAction
typealias FfiPatch = AutomergeUniffi.Patch

public struct Patch: Equatable {
    public let action: PatchAction
    public let path: [PathElement]

    public init(action: PatchAction, path: [PathElement]) {
        self.action = action
        self.path = path
    }

    init(_ ffi: FfiPatch) {
        self.path = ffi.path.map(PathElement.fromFfi)
        self.action = PatchAction.fromFfi(ffi.action)
    }
}

public enum PatchAction: Equatable {
    case Put(ObjId, Prop, Value)
    case Insert(ObjId, UInt64, [Value])
    case SpliceText(ObjId, UInt64, String)
    case Increment(ObjId, Prop, Int64)
    case DeleteMap(ObjId, String)
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

public struct DeleteSeq: Equatable {
    public let obj: ObjId
    public let index: UInt64
    public let length: UInt64

    public init(obj: ObjId, index: UInt64, length: UInt64) {
        self.obj = obj
        self.index = index
        self.length = length
    }
}
