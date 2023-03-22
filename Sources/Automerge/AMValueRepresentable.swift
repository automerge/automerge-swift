import Foundation

/// A type that can be represented within an Automerge document.
public protocol AMValueRepresentable {
    /// The error type associated with failed attempted conversion into or out of Automerge representation.
    associatedtype ConvertError: LocalizedError

    /// Converts the Automerge representation to a local type, or returns a failure
    /// - Parameter val: The Automerge ``Value`` to be converted into a local type.
    /// - Returns: The type, converted to a local type, or an error indicating the reason for the failure to convert.
    static func fromAMValue(_ val: Value) -> Result<Self, ConvertError>

    /// Converts a local type into an Automerge scalar value.
    /// - Returns: The ``ScalarValue`` that aligns with the provided type
    func toAMValue() -> ScalarValue
}

// MARK: Boolean Conversions

/// A failure to convert an Automerge merge to or from a Boolean representation.
public enum BadBool: LocalizedError {
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

extension Bool: AMValueRepresentable {
    public typealias ConvertError = BadBool
    public static func fromAMValue(_ val: Value) -> Result<Self, BadBool> {
        switch val {
        case let .Scalar(.Boolean(b)):
            return .success(b)
        default:
            return .failure(BadBool.notbool(val))
        }
    }

    public func toAMValue() -> ScalarValue {
        .Boolean(self)
    }
}

// MARK: String Conversions

public enum BadString: LocalizedError {
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

extension String: AMValueRepresentable {
    public typealias ConvertError = BadString
    public static func fromAMValue(_ val: Value) -> Result<String, BadString> {
        switch val {
        case let .Scalar(.String(s)):
            return .success(s)
        default:
            return .failure(BadString.notstring(val))
        }
    }

    public func toAMValue() -> ScalarValue {
        .String(self)
    }
}

// TODO: full list
// Bytes (Data)
// Uint (UInt64)
// Int (Int64)
// F64 (Double)
// Counter (Int64)
// Timestamp (Int64)
// Null
