import Foundation

/// A type that can be represented within an Automerge document.
///
/// The ``ScalarValue`` representation of a local type is an atomic update, as compared with ``Value/Object(_:_:)``
/// types which represent types that can be incrementally updated by multiple collaborators.
///
/// You can encode your own types to be used within ``ObjType/List`` or ``ObjType/Map`` by conforming your type
/// to `ScalarValueRepresentable`. Implement ``ScalarValueRepresentable/toScalarValue()`` with your
/// preferred encoding, returning ``ScalarValue/Bytes(_:)`` with the encoded data embedded,
/// and ``ScalarValueRepresentable/fromValue(_:)`` to decode into your type.
public protocol ScalarValueRepresentable {
    /// The error type associated with failed attempted conversion into or out of Automerge representation.
    associatedtype ConvertError: LocalizedError

    /// Converts the Automerge representation to a local type, or returns a failure.
    /// - Parameter val: The Automerge ``Value`` to be converted as a scalar value into a local type.
    /// - Returns: The type, converted to a local type, or an error indicating the reason for the failure to convert.
    ///
    /// The protocol accepts defines a function to accept a ``Value`` primarily for convenience.
    /// ``Value`` is a higher level enumeration that also includes object types such as ``ObjType/List``,
    /// ``ObjType/Map``,
    /// and ``ObjType/Text``.
    static func fromValue(_ val: Value) -> Result<Self, ConvertError>

    /// Converts the Automerge representation to a local type, or returns a failure.
    /// - Parameter val: The Automerge ``ScalarValue`` to be converted into a local type.
    /// - Returns: The local type, or an error indicating the reason for the failure to convert.
    static func fromScalarValue(_ val: ScalarValue) -> Result<Self, ConvertError>

    /// Converts a local type into an Automerge scalar value.
    /// - Returns: The ``ScalarValue`` that aligns with the provided type
    func toScalarValue() -> ScalarValue
}

// MARK: Boolean Conversions

/// A failure to convert an Automerge scalar value to or from a Boolean representation.
public enum BooleanScalarConversionError: LocalizedError {
    case notboolValue(_ val: Value)
    case notboolScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notboolValue(val):
            return "Failed to read the value \(val) as a Boolean."
        case let .notboolScalarValue(val):
            return "Failed to read the scalar value \(val) as a Boolean."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Bool: ScalarValueRepresentable {
    public typealias ConvertError = BooleanScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Self, BooleanScalarConversionError> {
        switch val {
        case let .Scalar(.Boolean(b)):
            return .success(b)
        default:
            return .failure(BooleanScalarConversionError.notboolValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Bool, BooleanScalarConversionError> {
        switch val {
        case let .Boolean(b):
            return .success(b)
        default:
            return .failure(BooleanScalarConversionError.notboolScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Boolean(self)
    }
}

// MARK: String Conversions

/// A failure to convert an Automerge scalar value to or from a String representation.
public enum StringScalarConversionError: LocalizedError {
    case notstringValue(_ val: Value)
    case notstringScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notstringValue(val):
            return "Failed to read the value \(val) as a String."
        case let .notstringScalarValue(val):
            return "Failed to read the scalar value \(val) as a String."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension String: ScalarValueRepresentable {
    public typealias ConvertError = StringScalarConversionError

    public static func fromValue(_ val: Value) -> Result<String, StringScalarConversionError> {
        switch val {
        case let .Scalar(.String(s)):
            return .success(s)
        default:
            return .failure(StringScalarConversionError.notstringValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<String, StringScalarConversionError> {
        switch val {
        case let .String(s):
            return .success(s)
        default:
            return .failure(StringScalarConversionError.notstringScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .String(self)
    }
}

// MARK: Bytes Conversions

/// A failure to convert an Automerge scalar value to or from a byte representation.
public enum BytesScalarConversionError: LocalizedError {
    case notbytesValue(_ val: Value)
    case notbytesScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notbytesValue(val):
            return "Failed to read the value \(val) as a bytes."
        case let .notbytesScalarValue(val):
            return "Failed to read the scalar value \(val) as a bytes."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Data: ScalarValueRepresentable {
    public typealias ConvertError = BytesScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Data, BytesScalarConversionError> {
        switch val {
        case let .Scalar(.Bytes(d)):
            return .success(d)
        default:
            return .failure(BytesScalarConversionError.notbytesValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Data, BytesScalarConversionError> {
        switch val {
        case let .Bytes(d):
            return .success(d)
        default:
            return .failure(BytesScalarConversionError.notbytesScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Bytes(self)
    }
}

// MARK: UInt Conversions

/// A failure to convert an Automerge scalar value to or from an unsigned integer representation.
public enum UIntScalarConversionError: LocalizedError {
    case notUIntValue(_ val: Value)
    case notUIntScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notUIntValue(val):
            return "Failed to read the value \(val) as an unsigned integer."
        case let .notUIntScalarValue(val):
            return "Failed to read the scalar value \(val) as an unsigned integer."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension UInt: ScalarValueRepresentable {
    public typealias ConvertError = UIntScalarConversionError

    public static func fromValue(_ val: Value) -> Result<UInt, UIntScalarConversionError> {
        switch val {
        case let .Scalar(.Uint(d)):
            return .success(UInt(d))
        default:
            return .failure(UIntScalarConversionError.notUIntValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<UInt, UIntScalarConversionError> {
        switch val {
        case let .Uint(d):
            return .success(UInt(d))
        default:
            return .failure(UIntScalarConversionError.notUIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(UInt64(self))
    }
}

// MARK: Int Conversions

/// A failure to convert an Automerge scalar value to or from a signed integer representation.
public enum IntScalarConversionError: LocalizedError {
    case notIntValue(_ val: Value)
    case notIntScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notIntValue(val):
            return "Failed to read the value \(val) as a signed integer."
        case let .notIntScalarValue(val):
            return "Failed to read the scalar value \(val) as a signed integer."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Int: ScalarValueRepresentable {
    public typealias ConvertError = IntScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Int, IntScalarConversionError> {
        switch val {
        case let .Scalar(.Int(d)):
            return .success(Int(d))
        default:
            return .failure(IntScalarConversionError.notIntValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Int, IntScalarConversionError> {
        switch val {
        case let .Int(d):
            return .success(Int(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

// MARK: Double Conversions

/// A failure to convert an Automerge scalar value to or from a 64-bit floating-point value representation.
public enum DoubleScalarConversionError: LocalizedError {
    case notDoubleValue(_ val: Value)
    case notDoubleScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notDoubleValue(val):
            return "Failed to read the value \(val) as a 64-bit floating-point value."
        case let .notDoubleScalarValue(val):
            return "Failed to read the scalar value \(val) as a 64-bit floating-point value."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Double: ScalarValueRepresentable {
    public typealias ConvertError = DoubleScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Double, DoubleScalarConversionError> {
        switch val {
        case let .Scalar(.F64(d)):
            return .success(Double(d))
        default:
            return .failure(DoubleScalarConversionError.notDoubleValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Double, DoubleScalarConversionError> {
        switch val {
        case let .F64(d):
            return .success(Double(d))
        default:
            return .failure(DoubleScalarConversionError.notDoubleScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .F64(self)
    }
}

// MARK: Timestamp Conversions

/// A failure to convert an Automerge scalar value to or from a timestamp representation.
public enum TimestampScalarConversionError: LocalizedError {
    case notTimetampValue(_ val: Value)
    case notTimetampScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notTimetampValue(val):
            return "Failed to read the value \(val) as a timestamp value."
        case let .notTimetampScalarValue(val):
            return "Failed to read the scalar value \(val) as a timestamp value."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Date: ScalarValueRepresentable {
    public typealias ConvertError = TimestampScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Date, TimestampScalarConversionError> {
        switch val {
        case let .Scalar(.Timestamp(d)):
            return .success(Date(timeIntervalSince1970: TimeInterval(d)))
        default:
            return .failure(TimestampScalarConversionError.notTimetampValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Date, TimestampScalarConversionError> {
        switch val {
        case let .Timestamp(d):
            return .success(Date(timeIntervalSince1970: TimeInterval(d)))
        default:
            return .failure(TimestampScalarConversionError.notTimetampScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Timestamp(Int64(timeIntervalSince1970))
    }
}
