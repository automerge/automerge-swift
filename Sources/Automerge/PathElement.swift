import struct AutomergeUniffi.PathElement
import enum AutomergeUniffi.Prop

typealias FfiPathElem = AutomergeUniffi.PathElement
typealias FfiProp = AutomergeUniffi.Prop

/// A component of the path to an object within a document.
///
/// A path constructed of `PathElement` instances represents the sequence of navigating through a hierarchical structure
/// of objects within an Automerge document.
/// The base of this tree structure is  ``ObjId/ROOT``.
public struct PathElement: Equatable {
    let prop: Prop
    let obj: ObjId

    /// Creates a new path element.
    /// - Parameters:
    ///   - obj: The object Id of the path element.
    ///   - prop: The property on the object, either a key on a map, or index position in a list.
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
///
/// The property is either a ``Prop/Key(_:)``, in the from of a `String` to a map,
/// or a ``Prop/Index(_:)`` with the index position represented as a 64-bit unsigned integer.
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
