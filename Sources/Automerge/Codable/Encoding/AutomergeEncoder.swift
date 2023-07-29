/// An encoder that stores codable-conforming types into an Automerge document.
public struct AutomergeEncoder {
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    var doc: Document
    var schemaStrategy: SchemaStrategy
    var cautiousWrite: Bool
    let logLevel: LogVerbosity

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
            cautiousWrite: cautiousWrite,
            logLevel: logLevel
        )
        try value.encode(to: encoder)
        encoder.postencodeCleanup()
    }

    public func encode<T: Encodable>(_ value: T, at path: [CodingKey]) throws {
        let encoder = AutomergeEncoderImpl(
            userInfo: userInfo,
            codingPath: path,
            doc: doc,
            strategy: schemaStrategy,
            cautiousWrite: cautiousWrite,
            logLevel: logLevel
        )
        try value.encode(to: encoder)
        encoder.postencodeCleanup()
    }
}
