import enum AutomergeUniffi.ObjType

typealias FfiObjtype = AutomergeUniffi.ObjType

public enum ObjType {
    case Map
    case List
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
