import Foundation

/// A decoder that initializes codable-conforming types from an Automerge document.
public struct AutomergeDecoder {
    /// The user info dictionary for the decoder.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    /// The instance of the an Automerge document to decode from.
    public let doc: Document

    /// Creates a new instance of an Automerge decoder.
    /// - Parameter doc: An instance of the document to decode types from.
    public init(doc: Document) {
        self.doc = doc
    }

    /// Returns the type you specify, decoded from the Automerge document referenced by the decoder.
    /// - Parameter _: _ The type of the value to decode from the Automerge document.
    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        if T.self == AutomergeText.self {
            // Special case decoding AutomergeText - when it's the top level type being encoded,
            // its content is placed as a keyed encoded location by the AutomergeEncoder
            let decoder = AutomergeDecoderImpl(
                doc: doc,
                userInfo: userInfo,
                codingPath: [AutomergeText.CodingKeys.value]
            )
            return try decoder.decode(T.self)
        } else {
            let decoder = AutomergeDecoderImpl(
                doc: doc,
                userInfo: userInfo,
                codingPath: []
            )
            return try decoder.decode(T.self)
        }
    }

    /// Returns the type you specify, decoded from the Automerge document referenced by the decoder.
    /// - Parameters:
    ///   - _: _ The type of the value to decode from the Automerge document.
    ///   - path: The path to the schema location within the Automerge document to attempt to decode into the type you
    /// provide.
    ///
    ///  The `path` parameter accepts any type conforming to the `CodingKey` protocol.
    ///  This library provides a type-erased coding key, ``AnyCodingKey``, and an initialization parser
    /// (``AnyCodingKey/parsePath(_:)``) to interpret a string as a sequence of path elements.
    ///  Use the combination of these types to conveniently specify where to read from within an Automerge document.
    ///
    ///  For example, the following code attempts to read a string from the `name` property of the first element in the
    /// root list referenced by the key `example`:
    ///  ```swift
    ///  let path = AnyCodingKey.parsePath("example.[0].name")
    ///  decoder.decode(String.self, at: path)
    ///  ```
    @inlinable public func decode<T: Decodable>(_: T.Type, from path: [CodingKey]) throws -> T {
        let decoder = AutomergeDecoderImpl(
            doc: doc,
            userInfo: userInfo,
            codingPath: path
        )
        return try decoder.decode(T.self)
    }
}
