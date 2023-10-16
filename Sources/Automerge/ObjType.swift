import enum AutomergeUniffi.ObjType

typealias FfiObjtype = AutomergeUniffi.ObjType

/// A type that represents an Automerge object.
public enum ObjType: Sendable {
    /// A type that represents a dictionary that uses the type String for keys.
    ///
    /// A `map` type can be used to represent a Swift dictionary, or an swift value or reference type encoded in the
    /// document using ``AutomergeEncoder``.
    /// An Automerge `map` type uses `String` for keys, and can reference any other Automerge object type or a
    /// ``ScalarValue``.
    /// Automerge `maps` are not constrained to a single type for all values within the dictionary.
    case Map

    /// A type that represents an array of Automerge values.
    ///
    /// An Automerge `list` type can be either another object type, or a ``ScalarValue``.
    /// Automerge `list` types are not constrained to a single type for all values within the array.
    case List

    /// A type that represents an array of unicode characters.
    ///
    /// This type is frequently correlated with the ``AutomergeText`` class, which provides a convenient read/write
    /// interface to the encapsulated String.
    /// Automerge `text` types always represent a String, internally represented as an array of UTF-8 characters.
    case Text

    func toFfi() -> FfiObjtype {
        switch self {
        case .Map:
            return FfiObjtype.map
        case .List:
            return FfiObjtype.list
        case .Text:
            return FfiObjtype.text
        }
    }

    static func fromFfi(ty: FfiObjtype) -> Self {
        switch ty {
        case .map:
            return .Map
        case .list:
            return .List
        case .text:
            return .Text
        }
    }
}

extension ObjType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .List: return "List"
        case .Map: return "Map"
        case .Text: return "Text"
        }
    }
}
