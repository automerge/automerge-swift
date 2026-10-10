import enum AutomergeUniffi.HydratedValue

typealias FfiHydratedValue = AutomergeUniffi.HydratedValue

/// A type that mirrors the Automerge internal types, holding an object's contents as a tree of values.
///
/// Block markers in rich text hold their contents as a map of these values. See ``Span``.
public enum AutomergeValue: Hashable, Equatable, Sendable {
    /// Represents a dictionary or map type.
    case dict([String: AutomergeValue])
    /// Represents an array or list type.
    case array([AutomergeValue])
    /// Represents an Automerge Text type.
    case text(String)
    /// Represents an Automerge scalar value.
    case scalar(ScalarValue)

    static func fromFfi(_ value: FfiHydratedValue) -> Self {
        switch value {
        case let .scalar(value):
            return .scalar(ScalarValue.fromFfi(value: value))
        case let .map(value):
            return .dict(value.mapValues(AutomergeValue.fromFfi))
        case let .list(value):
            return .array(value.map(AutomergeValue.fromFfi))
        case let .text(value):
            return .text(value)
        }
    }

    func toFfi() -> FfiHydratedValue {
        switch self {
        case let .scalar(value):
            return .scalar(value: value.toFfi())
        case let .dict(value):
            return .map(value: value.mapValues { $0.toFfi() })
        case let .array(value):
            return .list(value: value.map { $0.toFfi() })
        case let .text(value):
            return .text(value: value)
        }
    }
}

extension AutomergeValue: CustomStringConvertible {
    /// A text representation of the schema type and value.
    public var description: String {
        switch self {
        case let .dict(dictionary):
            return "{\(dictionary.description)}"
        case let .array(array):
            return "[\(array.description)]"
        case let .text(string):
            return "T{\(string)}"
        case let .scalar(scalarValue):
            return scalarValue.description
        }
    }
}
