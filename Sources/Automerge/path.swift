import struct AutomergeUniffi.PathElement
import enum AutomergeUniffi.Prop

typealias FfiPathElem = AutomergeUniffi.PathElement
typealias FfiProp = AutomergeUniffi.Prop

/// The path to a property within an object.
public struct PathElement: Equatable {
    let prop: Prop
    let obj: ObjId

    public init(obj: ObjId, prop: Prop) {
        self.prop = prop
        self.obj = obj
    }

    static func fromFfi(_ ffiElem: FfiPathElem) -> Self {
        Self(
            obj: ObjId(bytes: ffiElem.obj),
            prop: Prop.fromFfi(ffiElem.prop)
        )
    }
}

/// A type that represents a property on an object within an Automerge document.
public enum Prop: Equatable {
    /// A property in a map.
    case Key(String)
    /// An index into a sequence.
    case Index(UInt64)

    static func fromFfi(_ ffi: FfiProp) -> Self {
        switch ffi {
        case let .index(value):
            return .Index(value)
        case let .key(value):
            return .Key(value)
        }
    }
}
