@testable import Automerge
import XCTest

/// Asserts that `error` is an `E`, and that it matches `predicate`.
///
/// Use it in the error handler of `XCTAssertThrowsError`, so a test checks which error it gets rather
/// than only that something was thrown.
func XCTAssertError<E: Error>(
    _ error: any Error,
    is _: E.Type,
    file: StaticString = #filePath,
    line: UInt = #line,
    where predicate: (E) -> Bool = { _ in true }
) {
    guard let typed = error as? E else {
        XCTFail("expected \(E.self), got \(type(of: error)): \(error)", file: file, line: line)
        return
    }
    XCTAssertTrue(predicate(typed), "unexpected \(E.self): \(typed)", file: file, line: line)
}

extension CodingKeyLookupError {
    var isSchemaMissing: Bool {
        if case .SchemaMissing = self { return true }
        return false
    }

    var isMismatchedSchema: Bool {
        if case .MismatchedSchema = self { return true }
        return false
    }

    var isIndexOutOfBounds: Bool {
        if case .IndexOutOfBounds = self { return true }
        return false
    }

    /// Whether this wraps a document error saying the object is the wrong type.
    var isWrongObjectTypeDocError: Bool {
        if case let .AutomergeDocError(error) = self, let docError = error as? DocError {
            return docError.isWrongObjectType
        }
        return false
    }
}

extension DocError {
    var isWrongObjectType: Bool {
        if case .WrongObjectType = inner { return true }
        return false
    }
}

extension PathParseError {
    var isInvalidPathElement: Bool {
        if case .InvalidPathElement = self { return true }
        return false
    }

    var isEmptyListIndex: Bool {
        if case .EmptyListIndex = self { return true }
        return false
    }
}

extension EncodingError {
    /// Whether this is an `invalidValue` error for a value of type `T`.
    func isInvalidValue<T>(of _: T.Type) -> Bool {
        if case let .invalidValue(value, _) = self { return value is T }
        return false
    }

    var debugDescription: String {
        switch self {
        case let .invalidValue(_, context): return context.debugDescription
        @unknown default: return ""
        }
    }
}

extension DecodingError {
    /// Whether this is a `typeMismatch` error expecting `T`, at a coding path ending in `key`.
    func isTypeMismatch<T>(expecting _: T.Type, at key: String) -> Bool {
        if case let .typeMismatch(type, context) = self {
            return type == T.self && context.codingPath.last?.stringValue == key
        }
        return false
    }
}
