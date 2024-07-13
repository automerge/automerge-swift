/// An encoder that stores types that conform to the Codable protocol into an Automerge document.
public struct AutomergeEncoder {
    /// The user info dictionary for the encoder.
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    /// The instance of the an Automerge document to encode into.
    public let doc: Document
    /// The strategy to use when encoding types into an Automerge document.
    public var schemaStrategy: SchemaStrategy
    /// A Boolean value that indicates whether to verify existing value types match the type being encoded.
    public var cautiousWrite: Bool
    /// The level of information that the encoder writes to the unified logging system.
    public let logLevel: LogVerbosity

    /// Creates a new encoder that can store types into an Automerge document.
    /// - Parameters:
    ///   - doc: An instance of the document to store data into.
    ///   - strategy: The strategy to use when encoding types into an Automerge document. The default value is
    /// ``SchemaStrategy/createWhenNeeded``.
    ///   - cautiousWrite: A Boolean value defaulting to `false` that indicates whether to verify existing value types
    /// match the type being encoded.
    ///   - reportingLoglevel: The level of information that the encoder writes to the unified logging system. The
    /// default value is ``LogVerbosity/errorOnly``.
    public init(
        doc: Document,
        strategy: SchemaStrategy = .createWhenNeeded,
        cautiousWrite: Bool = false,
        reportingLoglevel: LogVerbosity = .errorOnly
    ) {
        self.doc = doc
        schemaStrategy = strategy
        self.cautiousWrite = cautiousWrite
        logLevel = reportingLoglevel
    }

    /// Encodes an optional value you provide into the encoder's Automerge document.
    /// - Parameter value: The value to encode.
    public func encode<T: Encodable>(_ value: T?) throws {
        // capture any top-level optional types being encoded, and encode as
        // the underlying type if the provided value isn't nil.
        if let definiteValue = value {
            try encode(definiteValue)
        }
    }

    /// Encodes a value you provide into the encoder's Automerge document.
    /// - Parameter value: The value to encode.
    public func encode<T: Encodable>(_ value: T) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: [],
            doc: doc,
            strategy: schemaStrategy,
            cautiousWrite: cautiousWrite,
            logLevel: logLevel
        )
        switch value {
        // special case encoding AutomergeText directly - it has a default encoder implementation
        // that would otherwise get missed as a top-level item to be encoded, and not encode "correctly"
        // into an Automerge document.
        case let value as AutomergeText:
            var container = encoder.container(keyedBy: AutomergeText.CodingKeys.self)
            try container.encode(value, forKey: .value)
        default:
            try value.encode(to: encoder)
        }
        encoder.postencodeCleanup()
    }

    /// Encodes a value you provide into a specific location within the encoder's Automerge document.
    /// - Parameters:
    ///   - value: The value to encode
    ///   - path: The schema location within the document to encode the value.
    ///
    ///  Use this method to encode individual values or types to specific locations within an Automerge document.
    ///  The `path` parameter identifies the location, and when the encoder uses the ``SchemaStrategy/createWhenNeeded``
    /// strategy, it creates container objects (arrays and dictionaries) as needed to write to the path if those paths
    /// don't yet exist.
    ///
    ///  The `path` parameter accepts any type conforming to the `CodingKey` protocol.
    ///  This library provides a type-erased coding key, ``AnyCodingKey``, and an initialization parser
    /// (``AnyCodingKey/parsePath(_:)``) to interpret a string as a sequence of path elements.
    ///  Use the combination of these types to conveniently specify where to write into the Automerge document.
    ///
    ///  For example, the following code writes the string `Henry` into the `name` property of the first element in the
    /// root list referenced by the key `example`:
    ///  ```swift
    ///  let path = AnyCodingKey.parsePath("example.[0].name")
    ///  encoder.encode("Henry", at: path)
    ///  ```
    public func encode<T: Encodable>(_ value: T, at path: [CodingKey]) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: path,
            doc: doc,
            strategy: schemaStrategy,
            cautiousWrite: cautiousWrite,
            logLevel: logLevel
        )
        switch value {
        // special case encoding AutomergeText directly - it has a default encoder implementation
        // that would otherwise get missed as a top-level item to be encoded, and not encode "correctly"
        // into an Automerge document.
        case let value as AutomergeText:
            var container = encoder.container(keyedBy: AutomergeText.CodingKeys.self)
            try container.encode(value, forKey: .value)
        default:
            try value.encode(to: encoder)
        }
        encoder.postencodeCleanup(below: path.map { AnyCodingKey($0) })
    }
}
