import Foundation

/// A type that represents the value of an Automerge counter.
public struct Counter: Equatable, Hashable {
    /// The value of the counter.
    public var value: Int

    public init(_ value: Int) {
        self.value = value
    }

    public init(_ value: Int64) {
        self.value = Int(value)
    }
}

// MARK: Counter Conversions

/// A failure to convert an Automerge scalar value to or from a signer integer counter representation.
public enum CounterScalarConversionError: LocalizedError {
    case notCounterValue(_ val: Value)
    case notCounterScalarValue(_ val: ScalarValue)

    /// A localized message describing what error occurred.
    public var errorDescription: String? {
        switch self {
        case let .notCounterValue(val):
            return "Failed to read the value \(val) as a signed integer counter."
        case let .notCounterScalarValue(val):
            return "Failed to read the scalar value \(val) as a signed integer counter."
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}

extension Counter: ScalarValueRepresentable {
    public typealias ConvertError = CounterScalarConversionError

    public static func fromValue(_ val: Value) -> Result<Counter, CounterScalarConversionError> {
        switch val {
        case let .Scalar(.Counter(d)):
            return .success(Counter(d))
        default:
            return .failure(CounterScalarConversionError.notCounterValue(val))
        }
    }

    public static func fromScalarValue(_ val: ScalarValue) -> Result<Counter, CounterScalarConversionError> {
        switch val {
        case let .Counter(d):
            return .success(Counter(d))
        default:
            return .failure(CounterScalarConversionError.notCounterScalarValue(val))
        }
    }

    public func toScalarValue() -> ScalarValue {
        .Counter(Int64(value))
    }
}
