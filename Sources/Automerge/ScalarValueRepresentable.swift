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

    /// Converts the Automerge representation to a local type, or returns a failure
    /// - Parameter val: The Automerge ``Value`` to be converted as a scalar value into a local type.
    /// - Returns: The type, converted to a local type, or an error indicating the reason for the failure to convert.
    ///
    /// The protocol accepts defines a function to accept a ``Value`` primarily for convenience.
    /// ``Value`` is a higher level enumeration that can include object types such as ``ObjType/List``, ``ObjType/Map``,
    /// and ``ObjType/Text``.
    static func fromValue(_ val: Value) -> Result<Self, ConvertError>

    /// Converts a local type into an Automerge scalar value.
    /// - Returns: The ``ScalarValue`` that aligns with the provided type
    func toScalarValue() -> ScalarValue
}

// MARK: Boolean Conversions

/// A failure to convert an Automerge scalar value to or from a Boolean representation.
public enum BooleanScalarConversionError: LocalizedError {
    case notbool(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notbool(val):
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
            return .failure(BooleanScalarConversionError.notbool(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Boolean(self)
    }
}

// MARK: String Conversions

/// A failure to convert an Automerge scalar value to or from a String representation.
public enum StringScalarConversionError: LocalizedError {
    case notstring(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notstring(val):
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
            return .failure(StringScalarConversionError.notstring(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .String(self)
    }
}

// MARK: Bytes Conversions

/// A failure to convert an Automerge scalar value to or from a byte representation.
public enum BytesScalarConversionError: LocalizedError {
    case notbytes(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notbytes(val):
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
            return .failure(BytesScalarConversionError.notbytes(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Bytes(self)
    }
}

// MARK: UInt Conversions

/// A failure to convert an Automerge scalar value to or from an unsigned integer representation.
public enum UIntScalarConversionError: LocalizedError {
    case notUInt(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notUInt(val):
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
            return .failure(UIntScalarConversionError.notUInt(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(UInt64(self))
    }
}

// MARK: Int Conversions

/// A failure to convert an Automerge scalar value to or from a signed integer representation.
public enum IntScalarConversionError: LocalizedError {
    case notInt(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notInt(val):
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
            return .failure(IntScalarConversionError.notInt(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

// MARK: Double Conversions

/// A failure to convert an Automerge scalar value to or from a 64-bit floating-point value representation.
public enum DoubleScalarConversionError: LocalizedError {
    case notDouble(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notDouble(val):
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
            return .failure(DoubleScalarConversionError.notDouble(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .F64(self)
    }
}

// MARK: Timestamp Conversions

/// A failure to convert an Automerge scalar value to or from a timestamp representation.
public enum TimestampScalarConversionError: LocalizedError {
    case notTimetamp(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notTimetamp(val):
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
            return .failure(TimestampScalarConversionError.notTimetamp(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Timestamp(Int64(timeIntervalSince1970))
    }
}
