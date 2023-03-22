import Foundation

/// A struct that represents the value of an Automerge counter.
public struct Counter {
    /// The value of the counter.
    public var value: Int

    internal init(_ value: Int) {
        self.value = value
    }

    internal init(_ value: Int64) {
        self.value = Int(value)
    }
}

// MARK: Counter Conversions

/// A failure to convert an Automerge scalar value to or from a signer integer counter representation.
public enum CounterScalarConversionError: LocalizedError {
    case notCounter(_ val: Value)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notCounter(val):
            return "Failed to read the scalar value \(val) as a signed integer counter."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Counter: ScalarValueRepresentable {
    public typealias ConvertError = CounterScalarConversionError
    public static func fromAMValue(_ val: Value) -> Result<Counter, CounterScalarConversionError> {
        switch val {
        case let .Scalar(.Counter(d)):
            return .success(Counter(d))
        default:
            return .failure(CounterScalarConversionError.notCounter(val))
        }
    }

    public func toAMValue() -> ScalarValue {
        .Counter(Int64(value))
    }
}
