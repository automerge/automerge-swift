import Foundation

/// A type that can be represented as an individual value within an Automerge document.
///
/// The ``ScalarValue`` representation of a local type is an all-at-once update, as compared with ``Value/Object(_:_:)``
/// types which represent types that can be incrementally updated by multiple collaborators.
///
/// For more complex types, conform your type to the `Codable` protocol and consider using ``AutomergeEncoder`` and
/// ``AutomergeDecoder`` to store those representations into an Automerge document.
/// If your type is a simple representation, you can encode your own types as a scalar value by conforming your type to
/// `ScalarValueRepresentable`.
/// By doing so, you provide the functions needed to convert with one of the Automerge primitive types, represented by
/// ``ScalarValue``.
///
/// Implement ``ScalarValueRepresentable/toScalarValue()`` to encode your type into a relevant Automerge primitive.
/// For example, you can encode your type into a buffer of bytes, and store the result as a value by returning
/// ``ScalarValue/Bytes(_:)`` with the data embedded.
/// Implement ``ScalarValueRepresentable/fromScalarValue(_:)`` to decode
/// the scalar value into your type.
///
/// Types that conform to ScalarValueRepresentable define a localized error type to provide information when conversion
/// issues arise.
public protocol ScalarValueRepresentable {
    /// The error type associated with failed attempted conversion into or out of Automerge representation.
    associatedtype ConvertError: LocalizedError

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
    case notboolScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notboolScalarValue(val):
            return "Failed to read the scalar value \(val) as a Boolean."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Bool: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Bool, BooleanScalarConversionError> {
        switch val {
        case let .Boolean(b):
            return .success(b)
        default:
            return .failure(.notboolScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Boolean(self)
    }
}

// MARK: URL Conversions

/// A failure to convert an Automerge scalar value to or from a Boolean representation.
public enum URLScalarConversionError: LocalizedError {
    case notStringScalarValue(_ val: ScalarValue)
    case notMatchingURLScheme(String)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notStringScalarValue(scalarValue):
            return "Failed to read the scalar value \(scalarValue) as a String before converting to URL."
        case let .notMatchingURLScheme(string):
            return "Failed to convert the string \(string) to URL."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension URL: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<URL, URLScalarConversionError> {
        switch val {
        case let .String(urlString):
            if let url = URL(string: urlString) {
                return .success(url)
            } else {
                return .failure(.notMatchingURLScheme(urlString))
            }
        default:
            return .failure(.notStringScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .String(absoluteString)
    }
}

// MARK: String Conversions

/// A failure to convert an Automerge scalar value to or from a String representation.
public enum StringScalarConversionError: LocalizedError {
    case notstringScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notstringScalarValue(val):
            return "Failed to read the scalar value \(val) as a String."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension String: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<String, StringScalarConversionError> {
        switch val {
        case let .String(s):
            return .success(s)
        default:
            return .failure(.notstringScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .String(self)
    }
}

// MARK: Bytes Conversions

/// A failure to convert an Automerge scalar value to or from a byte representation.
public enum BytesScalarConversionError: LocalizedError {
    case notbytesScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notbytesScalarValue(val):
            return "Failed to read the scalar value \(val) as a bytes."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Data: ScalarValueRepresentable {
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
    case notUIntScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notUIntScalarValue(val):
            return "Failed to read the scalar value \(val) as an unsigned integer."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension UInt: ScalarValueRepresentable {
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
    case notIntScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notIntScalarValue(val):
            return "Failed to read the scalar value \(val) as a signed integer."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Int: ScalarValueRepresentable {
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

extension Int8: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Int8, IntScalarConversionError> {
        switch val {
        case let .Int(d):
            return .success(Int8(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

extension Int16: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Int16, IntScalarConversionError> {
        switch val {
        case let .Int(d):
            return .success(Int16(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

extension Int32: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Int32, IntScalarConversionError> {
        switch val {
        case let .Int(d):
            return .success(Int32(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

extension Int64: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Int64, IntScalarConversionError> {
        switch val {
        case let .Int(d):
            return .success(Int64(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Int(Int64(self))
    }
}

// MARK: UInt types

extension UInt8: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<UInt8, IntScalarConversionError> {
        switch val {
        case let .Uint(d):
            return .success(UInt8(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(UInt64(self))
    }
}

extension UInt16: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<UInt16, IntScalarConversionError> {
        switch val {
        case let .Uint(d):
            return .success(UInt16(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(UInt64(self))
    }
}

extension UInt32: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<UInt32, IntScalarConversionError> {
        switch val {
        case let .Uint(d):
            return .success(UInt32(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(UInt64(self))
    }
}

extension UInt64: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<UInt64, IntScalarConversionError> {
        switch val {
        case let .Uint(d):
            return .success(UInt64(d))
        default:
            return .failure(IntScalarConversionError.notIntScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Uint(self)
    }
}

// MARK: Double Conversions

/// A failure to convert an Automerge scalar value to or from a 64-bit floating-point value representation.
public enum FloatingPointScalarConversionError: LocalizedError {
    case notF64ScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notF64ScalarValue(val):
            return "Failed to read the scalar value \(val) as a 64-bit floating-point value."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Double: ScalarValueRepresentable {
    public typealias ConvertError = FloatingPointScalarConversionError

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Double, FloatingPointScalarConversionError> {
        switch val {
        case let .F64(d):
            return .success(Double(d))
        default:
            return .failure(FloatingPointScalarConversionError.notF64ScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .F64(self)
    }
}

extension Float: ScalarValueRepresentable {
    public typealias ConvertError = FloatingPointScalarConversionError

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Float, FloatingPointScalarConversionError> {
        switch val {
        case let .F64(d):
            return .success(Float(d))
        default:
            return .failure(FloatingPointScalarConversionError.notF64ScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .F64(Double(self))
    }
}

// MARK: Timestamp Conversions

/// A failure to convert an Automerge scalar value to or from a timestamp representation.
public enum TimestampScalarConversionError: LocalizedError {
    case notTimetampScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notTimetampScalarValue(val):
            return "Failed to read the scalar value \(val) as a timestamp value."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Date: ScalarValueRepresentable {
    public static func fromScalarValue(_ val: ScalarValue) -> Result<Date, TimestampScalarConversionError> {
        switch val {
        case let .Timestamp(d):
            return .success(d)
        default:
            return .failure(.notTimetampScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Timestamp(self)
    }
}
