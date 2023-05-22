import enum AutomergeUniffi.Value

typealias FfiValue = AutomergeUniffi.Value

/// A type that represents a value or object managed by Automerge.
public enum Value: Equatable, Hashable, Sendable {
    /// An object type
    case Object(ObjId, ObjType)
    /// A scalar value
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

extension Value: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .Object(objId, objType):
            return "OBJ[\(objId), \(objType)]"
        case let .Scalar(scalarValue):
            return "SCALAR[\(scalarValue)]"
        }
    }
}
