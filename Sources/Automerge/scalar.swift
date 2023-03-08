import enum AutomergeUniffi.ScalarValue

typealias FFIScalar = AutomergeUniffi.ScalarValue

public enum ScalarValue: Equatable, Hashable {
    case Bytes([UInt8])
    case String(String)
    case Uint(UInt64)
    case Int(Int64)
    case F64(Double)
    case Counter(Int64)
    case Timestamp(Int64)
    case Boolean(Bool)
    case Unknown(typeCode: UInt8, data: [UInt8])
    case Null

    internal func toFfi() -> FFIScalar {
        switch self {
        case let .Bytes(b):
            return .bytes(value: b)
        case let .String(s):
            return .string(value: s)
        case let .Uint(i):
            return .uint(value: i)
        case let .Int(i):
            return .int(value: i)
        case let .F64(d):
            return .f64(value: d)
        case let .Counter(i):
            return .counter(value: i)
        case let .Timestamp(i):
            return .timestamp(value: i)
        case let .Boolean(v):
            return .boolean(value: v)
        case let .Unknown(t, d):
            return .unknown(typeCode: t, data: d)
        case .Null:
            return .null
        }
    }

    static func fromFfi(value: FFIScalar) -> Self {
        switch value {
        case let .bytes(value):
            return .Bytes(value)
        case let .string(value):
            return .String(value)
        case let .uint(value):
            return .Uint(value)
        case let .int(value):
            return .Int(value)
        case let .f64(value):
            return .F64(value)
        case let .counter(value):
            return .Counter(value)
        case let .timestamp(value):
            return .Timestamp(value)
        case let .boolean(value):
            return .Boolean(value)
        case let .unknown(typeCode, data):
            return .Unknown(typeCode: typeCode, data: data)
        case .null:
            return .Null
        }
    }
}
