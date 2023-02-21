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
    case .Bytes(let b):
      return .bytes(value: b)
    case .String(let s):
      return .string(value: s)
    case .Uint(let i):
      return .uint(value: i)
    case .Int(let i):
      return .int(value: i)
    case .F64(let d):
      return .f64(value: d)
    case .Counter(let i):
      return .counter(value: i)
    case .Timestamp(let i):
      return .timestamp(value: i)
    case .Boolean(let v):
      return .boolean(value: v)
    case .Unknown(let t, let d):
      return .unknown(typeCode: t, data: d)
    case .Null:
      return .null
    }
  }

  static func fromFfi(value: FFIScalar) -> Self {
    switch value {
    case .bytes(let value):
      return .Bytes(value)
    case .string(let value):
      return .String(value)
    case .uint(let value):
      return .Uint(value)
    case .int(let value):
      return .Int(value)
    case .f64(let value):
      return .F64(value)
    case .counter(let value):
      return .Counter(value)
    case .timestamp(let value):
      return .Timestamp(value)
    case .boolean(let value):
      return .Boolean(value)
    case .unknown(let typeCode, let data):
      return .Unknown(typeCode: typeCode, data: data)
    case .null:
      return .Null
    }
  }
}
