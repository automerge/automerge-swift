import Foundation // for LocalizedError

// rough equivalent to an opaque path - serves a similar function to Automerge.PathElement
// but from an external, path-only point of view to reference or build a potentially existing
// schema within Automerge.

/// A type that maps provides a coding key value with an enumeration.
public struct AnyCodingKey: Equatable {
    private let pathElement: Automerge.Prop

    /// Creates a generalized Coding Key from an Automerge Property.
    /// - Parameter pathProperty: The Automerge property to convert.
    init(_ pathProperty: Automerge.Prop) {
        pathElement = pathProperty
    }

    /// Creates a generalized Coding Key from an Automerge Path Element.
    /// - Parameter element: The Automerge path element to convert.
    init(_ element: Automerge.PathElement) {
        pathElement = element.prop
    }

    /// Creates a new schema path element from a generic coding key.
    /// - Parameter key: The coding key to use for internal values.
    public init(_ key: some CodingKey) {
        if let intValue = key.intValue {
            pathElement = .Index(UInt64(intValue))
        } else {
            pathElement = .Key(key.stringValue)
        }
    }

    /// Creates a new schema path element for a keyed container using the string you provide.
    /// - Parameter stringVal: The key for a keyed container.
    public init(_ stringVal: String) {
        pathElement = .Key(stringVal)
    }

    /// Creates a new schema path element for an un-keyed container using the index you provide.
    /// - Parameter intValue: The index position for an un-keyed container.
    public init(_ intValue: UInt64) {
        pathElement = .Index(intValue)
    }

    /// A coding key that represents the root of a schema hierarchy.
    ///
    /// `ROOT` conceptually maps to the equivalent of an empty array of `some CodingKey`.
    public static let ROOT = AnyCodingKey(.Key(""))
}

// MARK: CodingKey conformance

extension AnyCodingKey: CodingKey {
    /// Creates a new schema path element for an un-keyed container using the index you provide.
    ///
    /// For a non-failable initializer for ``AnyCodingKey``, use ``AnyCodingKey/init(_:)``.
    ///
    /// - Parameter intValue: The index position for an un-keyed container.
    public init?(intValue: Int) {
        if intValue < 0 {
            preconditionFailure("Schema index positions can't be negative")
        }
        pathElement = Automerge.Prop.Index(UInt64(intValue))
    }

    /// Creates a new schema path element for a keyed container using the string you provide.
    ///
    /// For a non-failable initializer for ``AnyCodingKey``, use ``AnyCodingKey/init(_:)``.
    ///
    /// - Parameter stringVal: The key for a keyed container.
    public init?(stringValue: String) {
        pathElement = Automerge.Prop.Key(stringValue)
    }

    /// The string value for this schema path element.
    public var stringValue: String {
        if case let .Key(stringVal) = pathElement {
            return stringVal
        }
        preconditionFailure("Invalid string value from CodingKey that is an index \(pathElement)")
    }

    /// The integer value of this schema path element.
    ///
    /// If `nil`, the schema path element is expected to be a string that represents a key for a keyed container.
    public var intValue: Int? {
        if case let .Index(intValue) = pathElement {
            return Int(intValue)
        }
        return nil
    }
}

/// Path Errors
public enum PathParseError: LocalizedError {
    /// The path element is not valid.
    case InvalidPathElement(String)
    /// The path element, structured as a Index location, doesn't include an index value.
    case EmptyListIndex(String)

    /// A localized message describing the error.
    public var errorDescription: String? {
        switch self {
        case let .InvalidPathElement(str):
            return str
        case let .EmptyListIndex(str):
            return str
        }
    }
}

public extension AnyCodingKey {
    /// Parses a string into an array of generic coding path elements.
    /// - Parameter path: The string to parse.
    /// - Returns: An array of coding path elements corresponding to the string.
    static func parsePath(_ path: String) throws -> [AnyCodingKey] {
        // breaks up the provided path, breaking on '.' and parsing the results into a series
        // of AnyCodingKey
        try path
            .split(separator: ".")
            .map { String($0) }
            .map { strValue in
                if let firstChar = strValue.first, firstChar.isASCII, firstChar.isLetter {
                    return AnyCodingKey(strValue)
                } else if strValue.first == "[", strValue.last == "]" {
                    let start = strValue.index(after: strValue.startIndex)
                    let end = strValue.index(before: strValue.endIndex)
                    let substring = String(strValue[start ..< end])
                    if !substring.isEmpty, let parsedIndexValue = UInt64(substring) {
                        return AnyCodingKey(parsedIndexValue)
                    } else {
                        throw PathParseError.EmptyListIndex(String(strValue))
                    }
                }
                throw PathParseError.InvalidPathElement(String(strValue))
            }
    }
}

extension AnyCodingKey: CustomStringConvertible {
    /// A string description of the schema path element.
    public var description: String {
        switch pathElement {
        case let .Index(uintVal):
            return "[\(uintVal)]"
        case let .Key(strVal):
            return strVal
        }
    }
}

extension AnyCodingKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch pathElement {
        case let .Index(intVal):
            hasher.combine(intVal)
        case let .Key(strVal):
            hasher.combine(strVal)
        }
    }
}

extension Sequence where Element: CodingKey {
    /// Returns a string that represents the schema path.
    func stringPath() -> String {
        let path = map { pathElement in
            AnyCodingKey(pathElement).description
        }
        .joined(separator: ".")
        return ".\(path)"
    }
}
