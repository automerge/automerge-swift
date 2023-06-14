import Foundation // for LocalizedError

public enum CodingKeyLookupError: LocalizedError, Equatable {
    public static func == (lhs: CodingKeyLookupError, rhs: CodingKeyLookupError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }

    /// An error that represents a coding container was unable to look up a relevant Automerge objectId and was unable
    /// to capture a more specific error.
    case UnexpectedLookupFailure(String)
    /// The path element is not valid.
    case InvalidPathElement(String)
    /// The path element, structured as a Index location, doesn't include an index value.
    case EmptyListIndex(String)
    /// The list index requested was longer than the list in the Document.
    case IndexOutOfBounds(String)
    /// The path provided to look up a value is invalid.
    case InvalidValueLookup(String)
    /// The path provided to look up an index is invalid.
    case InvalidIndexLookup(String)
    /// The path provided extends through Automerge Text, a leaf node in the schema.
    case PathExtendsThroughText(String)
    /// The path provided extends through an Automerge ScalarValue, a leaf node in the schema.
    case PathExtendsThroughScalar(String)
    /// The path provided doesn't match the schema within the Automerge Document.
    case MismatchedSchema(String)
    /// The path provided expected schema within the Automerge document that doesn't exist.
    case SchemaMissing(String)
    /// No coding path was provided for encoding a single value into the Automerge document.
    case NoPathForSingleValue(String)
    /// An underlying Automerge Document error.
    case AutomergeDocError(Error)

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case let .UnexpectedLookupFailure(str):
            return str
        case let .InvalidPathElement(str):
            return str
        case let .EmptyListIndex(str):
            return str
        case let .IndexOutOfBounds(str):
            return str
        case let .InvalidValueLookup(str):
            return str
        case let .InvalidIndexLookup(str):
            return str
        case let .PathExtendsThroughText(str):
            return str
        case let .PathExtendsThroughScalar(str):
            return str
        case let .SchemaMissing(str):
            return str
        case let .MismatchedSchema(str):
            return str
        case let .NoPathForSingleValue(str):
            return str
        case let .AutomergeDocError(err):
            return "An underlying Automerge error: \(err.localizedDescription)"
        }
    }

    /// A localized message describing the reason for the failure.
    public var failureReason: String? { nil }
}
