import enum AutomergeUniffi.ScalarValue
import Foundation

typealias FFIScalar = AutomergeUniffi.ScalarValue

/// A type that represents a primitive Automerge value.
public enum ScalarValue: Equatable, Hashable {
    /// A byte buffer.
    case Bytes(Data)
    /// A string.
    case String(String)
    /// An unsigned integer.
    case Uint(UInt64)
    /// A signed integer.
    case Int(Int64)
    /// A floating point number.
    case F64(Double)
    /// An integer counter.
    case Counter(Int64)
    /// A timestamp represented by the milliseconds since UNIX epoch.
    case Timestamp(Int64)
    /// A Boolean value.
    case Boolean(Bool)
    /// An unknown, raw scalar type.
    ///
    /// This type is reserved for forward compatibility, and is not expected to be created directly.
    case Unknown(typeCode: UInt8, data: Data)
    /// A null.
    case Null

    internal func toFfi() -> FFIScalar {
        switch self {
        case let .Bytes(b):
            return .bytes(value: Array(b))
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
            return .unknown(typeCode: t, data: Array(d))
        case .Null:
            return .null
        }
    }

    static func fromFfi(value: FFIScalar) -> Self {
        switch value {
        case let .bytes(value):
            return .Bytes(Data(value))
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
            return .Unknown(typeCode: typeCode, data: Data(data))
        case .null:
            return .Null
        }
    }
}
