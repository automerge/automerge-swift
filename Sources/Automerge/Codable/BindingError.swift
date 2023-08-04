import Foundation

/// Binding errors
public enum BindingError: LocalizedError, Equatable {
    public static func == (lhs: BindingError, rhs: BindingError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }

    /// The path provided was invalid to bind into the Automerge document.
    case InvalidPath(String)
    /// The Automerge object at the path provided was not a Text object.
    case NotText
    /// The Automerge object at the path and key/index provided was not a Counter.
    case NotCounter
    /// The instance is not bound to an Automerge Document.
    case Unbound

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case let .InvalidPath(path):
            return "Attempted to bind to an invalid path within the Automerge document: \(path)"
        case .NotText:
            return "Path location was not an Automerge Text object."
        case .NotCounter:
            return "Path location and key or index does not reference a Counter."
        case .Unbound:
            return "The object does not yet reference an Automerge Text object."
        }
    }
}
