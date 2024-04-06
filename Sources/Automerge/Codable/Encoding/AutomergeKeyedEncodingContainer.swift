import Foundation // for Date support
#if canImport(os)
import os // for structured logging
#endif

struct AutomergeKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K

    /// A reference to the Automerge Encoding Implementation class used for tracking encoding state.
    let impl: AutomergeEncoderImpl
    /// An instance that represents a Map being constructed in an Automerge Document that maps to the keyed container
    /// you provide to encode.
    // let object: AutomergeObject
    /// An array of types that conform to CodingKey that make up the "schema path" to this instance from the root of the
    /// top-level encoded type.
    let codingPath: [CodingKey]
    /// The Automerge document that the encoder writes into.
    let document: Document
    /// The objectId that this keyed encoding container maps to within an Automerge document.
    ///
    /// If `document` is `nil`, the error attempting to retrieve should be in ``lookupError``.
    let objectId: ObjId?
    /// An error captured when attempting to look up or create an objectId in Automerge based on the coding path
    /// provided.
    let lookupError: Error?

    /// Creates a new keyed-encoding container you use to encode into an Automerge document.
    ///
    /// After initialization, the container has one of two properties set: ``objectId`` or ``lookupError``.
    /// As the container is created and initialized, it attempts to either look up or create an Automerge objectId that
    /// maps to the relevant schema path matching from the ``codingPath``.
    /// If the lookup was successful, the property `objectId` has the proper value from the associated document.
    /// Otherwise, the initialization captures the error into ``lookupError`` and is thrown when you invoke any of the
    /// `encode` methods.
    ///
    /// Called from within a developer's type providing conformance to `Encodable`, for example:
    /// ```swift
    /// var container = encoder.container(keyedBy: CodingKeys.self)
    /// ```
    ///
    /// - Parameters:
    ///   - impl: A reference to the AutomergeEncodingImpl that this container represents.
    ///   - codingPath: An array of types that conform to CodingKey that make up the "schema path" to this instance from
    /// the root of the top-level encoded type.
    ///   - doc: The Automerge document that the encoder writes into.
    init(impl: AutomergeEncoderImpl, codingPath: [CodingKey], doc: Document) {
        self.impl = impl
        self.codingPath = codingPath
        document = doc
        switch doc.retrieveObjectId(
            path: codingPath,
            containerType: .Key,
            strategy: impl.schemaStrategy
        ) {
        case let .success(objId):
            objectId = objId
            impl.objectIdForContainer = objId
            lookupError = nil
        case let .failure(capturedError):
            objectId = nil
            lookupError = capturedError
        }
        #if canImport(os)
        if #available(macOS 11, iOS 14, *) {
            let logger = Logger(subsystem: "Automerge", category: "AutomergeEncoder")
            if impl.reportingLogLevel >= LogVerbosity.debug {
                logger.debug("Establishing Keyed Encoding Container for path \(codingPath.map { AnyCodingKey($0) })")
            }
        }
        #endif
    }

    fileprivate func reportBestError() -> Error {
        // Returns the best value it can from a lookup error scenario.
        if let containerLookupError = lookupError {
            return containerLookupError
        } else {
            // If the error wasn't captured for some reason, drop back to a more general error exposing
            // the precondition failure.
            return CodingKeyLookupError
                .UnexpectedLookupFailure(
                    "Encoding called on KeyedContainer when ObjectId is nil, and there was no recorded lookup error for the path \(codingPath)"
                )
        }
    }

    fileprivate func checkTypeMatch<T>(value: T, objectId: ObjId, key: Self.Key, type: TypeOfAutomergeValue) throws {
        if let testCurrentValue = try document.get(obj: objectId, key: key.stringValue),
           TypeOfAutomergeValue.from(testCurrentValue) != type
        {
            // BLOW UP HERE
            throw EncodingError.invalidValue(
                value,
                EncodingError
                    .Context(
                        codingPath: codingPath,
                        debugDescription: "The type in the automerge document (\(TypeOfAutomergeValue.from(testCurrentValue))) doesn't match the type being written (\(type))"
                    )
            )
        }
    }

    mutating func encodeNil(forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        try document.put(obj: objectId, key: key.stringValue, value: .Null)
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Bool, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .bool)
        }
        try document.put(obj: objectId, key: key.stringValue, value: .Boolean(value))
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: String, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .string)
        }
        try document.put(obj: objectId, key: key.stringValue, value: .String(value))
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Double, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: codingPath + [key],
                debugDescription: "Unable to encode Double.\(value) at \(codingPath) into an Automerge F64."
            ))
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .double)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Float, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: codingPath + [key],
                debugDescription: "Unable to encode Float.\(value) directly in JSON."
            ))
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .double)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Int, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .int)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Int8, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .int)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Int16, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .int)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Int32, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .int)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: Int64, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .int)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: UInt, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: UInt8, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: UInt16, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: UInt32, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode(_ value: UInt64, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        if impl.cautiousWrite {
            try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
        }
        try document.put(obj: objectId, key: key.stringValue, value: value.toScalarValue())
        impl.mapKeysWritten.append(key.stringValue)
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Self.Key) throws {
        guard let objectId = objectId else {
            throw reportBestError()
        }
        let newPath = impl.codingPath + [key]
        // this is where we need to figure out what the encodable type is in order to create
        // the correct Automerge objectType underneath the covers.
        // For example - for encoding another struct, class, or dict - we'd want to make it .map,
        // array or list would be .list, and for a singleValue property we don't want to create a new
        // objectId.
        // This should ideally be an "upsert" - look up and find if there already, otherwise create
        // a new instance to write into...

        // as we create newEncoder, we don't have any idea what kind of thing this is - singleValue, keyed, or
        // unkeyed...
        // As such, we can't easily assert the "new" objectId - because we don't know if we need one,
        // and if so, if it's associated with singleValue (don't need a new one), keyed (need a new map one),
        // or unkeyed (need a new list one). In fact, we don't even know for sure what we'll need until
        // the Codable method `encode` is called - because that's where a container is created. So while we
        // can set this "newPath", we don't have the deets to create (if needed) a new objectId until we
        // initialize a specific container type.

        switch value {
        case let date as Date:
            // Capture and override the default encodable pathing for Date since
            // Automerge supports it as a primitive value type.
            if impl.cautiousWrite {
                try checkTypeMatch(value: value, objectId: objectId, key: key, type: .timestamp)
            }
            try document.put(obj: objectId, key: key.stringValue, value: date.toScalarValue())
            impl.mapKeysWritten.append(key.stringValue)
        case let data as Data:
            // Capture and override the default encodable pathing for Data since
            // Automerge supports it as a primitive value type.
            if impl.cautiousWrite {
                try checkTypeMatch(value: value, objectId: objectId, key: key, type: .bytes)
            }
            try document.put(obj: objectId, key: key.stringValue, value: data.toScalarValue())
            impl.mapKeysWritten.append(key.stringValue)
        case let counter as Counter:
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            if impl.cautiousWrite {
                try checkTypeMatch(value: value, objectId: objectId, key: key, type: .counter)
            }
            if counter.doc == nil || counter.objId == nil {
                // instance is an unbound instance - implying a new reference into the Automerge
                // document. Attempt to serialize the unboundStorage into place.
                if case let .Scalar(.Counter(currentCounterValue)) = try document.get(
                    obj: objectId,
                    key: key.stringValue
                ) {
                    let counterDifference = currentCounterValue - Int64(counter._unboundStorage)
                    try document.increment(obj: objectId, key: key.stringValue, by: counterDifference)
                } else {
                    try document.put(
                        obj: objectId,
                        key: key.stringValue,
                        value: .Counter(Int64(counter._unboundStorage))
                    )
                }
            }
            impl.mapKeysWritten.append(key.stringValue)
        case let text as AutomergeText:
            // Capture and override the default encodable pathing for AutomergeText since
            // Automerge supports it as a primitive value type.
            let textNodeId: ObjId
            if let existingNode = try document.get(obj: objectId, key: key.stringValue) {
                guard case let .Object(textId, .Text) = existingNode else {
                    throw CodingKeyLookupError
                        .MismatchedSchema(
                            "Text Encoding on KeyedContainer at \(codingPath) exists and is \(existingNode), not Text."
                        )
                }
                textNodeId = textId
            } else {
                textNodeId = try document.putObject(obj: objectId, key: key.stringValue, ty: .Text)
            }

            // AutomergeText is a reference type that, when bound, writes directly into the
            // Automerge document, so no additional work is needed to write in the data unless
            // the object is 'unbound' (for example, a new AutomergeText instance)
            if text.doc == nil || text.objId == nil {
                // instance is an unbound instance - implying a new reference into the Automerge
                // document. Attempt to serialize the unboundStorage into place.
                if !text._unboundStorage.isEmpty {
                    // Iterate through
                    let currentText = try document.text(obj: textNodeId)
                    if currentText != text._unboundStorage {
                        try document.updateText(obj: textNodeId, value: text._unboundStorage)
                    }
                }
            }
            impl.mapKeysWritten.append(key.stringValue)
        case let url as URL:
            if impl.cautiousWrite {
                try checkTypeMatch(value: value, objectId: objectId, key: key, type: .uint)
            }
            try document.put(obj: objectId, key: key.stringValue, value: url.toScalarValue())
            impl.mapKeysWritten.append(key.stringValue)
        default:
            let newEncoder = AutomergeEncoderImpl(
                userInfo: impl.userInfo,
                codingPath: newPath,
                doc: document,
                strategy: impl.schemaStrategy,
                cautiousWrite: impl.cautiousWrite,
                logLevel: impl.reportingLogLevel
            )
            // Create a link from the current AutomergeEncoderImpl to the child, which
            // will be referenced from future containers and updated with status.
            impl.childEncoders.append(newEncoder)

            try value.encode(to: newEncoder)
            impl.mapKeysWritten.append(key.stringValue)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Self.Key) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey
    {
        let newPath = impl.codingPath + [key]
        let nestedContainer = AutomergeKeyedEncodingContainer<NestedKey>(
            impl: impl,
            codingPath: newPath,
            doc: document
        )
        return KeyedEncodingContainer(nestedContainer)
    }

    mutating func nestedUnkeyedContainer(forKey key: Self.Key) -> UnkeyedEncodingContainer {
        let newPath = impl.codingPath + [key]
        let nestedContainer = AutomergeUnkeyedEncodingContainer(
            impl: impl,
            codingPath: newPath,
            doc: document
        )
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        impl
    }

    mutating func superEncoder(forKey _: Self.Key) -> Encoder {
        impl
    }
}
