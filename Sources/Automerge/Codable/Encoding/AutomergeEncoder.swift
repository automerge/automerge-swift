/// An encoder that stores codable-conforming types into an Automerge document.
public struct AutomergeEncoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    var doc: Document
    var schemaStrategy: SchemaStrategy
    var cautiousWrite: Bool

    public init(doc: Document, strategy: SchemaStrategy = .createWhenNeeded, cautiousWrite: Bool = false) {
        self.doc = doc
        schemaStrategy = strategy
        self.cautiousWrite = cautiousWrite
    }

    public func encode<T: Encodable>(_ value: T?) throws {
        // capture any top-level optional types being encoded, and encode as
        // the underlying type if the provided value isn't nil.
        if let definiteValue = value {
            try encode(definiteValue)
        }
    }

    public func encode<T: Encodable>(_ value: T) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: [],
            doc: doc,
            strategy: schemaStrategy,
            cautiousWrite: cautiousWrite
        )
        try value.encode(to: encoder)
    }

    public func encode<T: Encodable>(_ value: T, at path: [CodingKey]) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: path,
            doc: doc,
            strategy: schemaStrategy,
            cautiousWrite: cautiousWrite
        )
        try value.encode(to: encoder)
    }
}
