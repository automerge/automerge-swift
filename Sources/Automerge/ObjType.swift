import enum AutomergeUniffi.ObjType

typealias FfiObjtype = AutomergeUniffi.ObjType

/// A type that represents an Automerge object.
public enum ObjType {
    /// A type that represents a map that uses String as keys.
    case Map
    /// A type that represents a sequence of arbitrary Automerge values.
    case List
    /// A type that represents sequence of unicode characters.
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
