import enum AutomergeUniffi.Value

typealias FfiValue = AutomergeUniffi.Value

public enum Value: Equatable, Hashable {
    case Object(ObjId, ObjType)
    case Scalar(ScalarValue)

    static func fromFfi(value: FfiValue) -> Self {
        switch value {
        case let .object(typ, id):
            return .Object(ObjId(bytes: id), ObjType.fromFfi(ty: typ))
        case let .scalar(v):
            return .Scalar(ScalarValue.fromFfi(value: v))
        }
    }
}
