import Foundation // for Date support
#if canImport(os)
import os // for structured logging
#endif

struct AutomergeUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let impl: AutomergeEncoderImpl
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

    private(set) var count: Int = 0

    init(impl: AutomergeEncoderImpl, codingPath: [CodingKey], doc: Document) {
        self.impl = impl
        self.codingPath = codingPath
        document = doc
        switch doc.retrieveObjectId(
            path: codingPath,
            containerType: .Index,
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
        // Fix for issue #54 looks best here, but I'm not happy with it.
        // We don't know the length of what's going to be encoded, nor do we get any
        // signal when we're done, so the only path I can see is to pro-actively wipe
        // out the extent of any array *before* we start writing back into it.
        if #available(macOS 11, iOS 14, *) {
            let logger = Logger(subsystem: "Automerge", category: "AutomergeEncoder")
            if impl.reportingLogLevel >= LogVerbosity.debug {
                logger.debug("Established Unkeyed Encoding Container for path \(codingPath.map { AnyCodingKey($0) })")
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
                    "Encoding called on UnkeyedContainer when ObjectId is nil, and there was no recorded lookup error for the path \(codingPath)"
                )
        }
    }

    mutating func encodeNil() throws {}

    mutating func encode<T>(_ value: T) throws where T: Encodable {
        guard let objectId = objectId else {
            throw reportBestError()
        }

        switch value {
        case let date as Date:
            // Capture and override the default encodable pathing for Date since
            // Automerge supports it as a primitive value type.
            let valueToWrite = date.toScalarValue()
            if impl.cautiousWrite {
                try checkTypeMatch(value: valueToWrite, objectId: objectId, index: UInt64(count), type: .timestamp)
            }
            try document.insert(obj: objectId, index: UInt64(count), value: valueToWrite)
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case let data as Data:
            // Capture and override the default encodable pathing for Data since
            // Automerge supports it as a primitive value type.
            let valueToWrite = data.toScalarValue()
            if impl.cautiousWrite {
                try checkTypeMatch(value: valueToWrite, objectId: objectId, index: UInt64(count), type: .bytes)
            }
            try document.insert(obj: objectId, index: UInt64(count), value: valueToWrite)
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case let counter as Counter:
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            if impl.cautiousWrite {
                try checkTypeMatch(
                    value: counter.value,
                    objectId: objectId,
                    index: UInt64(count),
                    type: .counter
                )
            }
            if counter.doc == nil || counter.objId == nil {
                // instance is an unbound instance - implying a new reference into the Automerge
                // document. Attempt to serialize the unboundStorage into place.
                // Check to see if the document already has a scalar at this location
                if case .Scalar(.Counter) = try document.get(
                    obj: objectId,
                    index: UInt64(count)
                ) {
                    // an unbound counter value should be added to any existing
                    // document-based counter in order to preserve
                    // increments/decrement counts
                    try document.increment(
                        obj: objectId,
                        index: UInt64(count),
                        by: Int64(counter._unboundStorage)
                    )
                } else {
                    // Otherwise the counter is new to the document, and should be
                    // inserted with the value of it's unbound storage.
                    try document.insert(
                        obj: objectId,
                        index: UInt64(count),
                        value: .Counter(Int64(counter._unboundStorage))
                    )
                }
            } else {
                if case let .Scalar(.Counter(currentCounterValue)) = try document.get(
                    obj: objectId,
                    index: UInt64(count)
                ) {
                    let counterDifference = currentCounterValue - Int64(counter._unboundStorage)
                    try document.increment(obj: objectId, index: UInt64(count), by: counterDifference)
                } else {
                    try document.insert(
                        obj: objectId,
                        index: UInt64(count),
                        value: .Counter(Int64(counter._unboundStorage))
                    )
                }
            }
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case let text as AutomergeText:
            // Capture and override the default encodable pathing for AutomergeText since
            // Automerge supports it as a primitive value type.
            let textNodeId: ObjId
            if let existingNode = try document.get(obj: objectId, index: UInt64(count)) {
                guard case let .Object(textId, .Text) = existingNode else {
                    throw CodingKeyLookupError
                        .MismatchedSchema(
                            "Text Encoding on KeyedContainer at \(codingPath) exists and is \(existingNode), not Text."
                        )
                }
                textNodeId = textId
            } else {
                textNodeId = try document.insertObject(obj: objectId, index: UInt64(count), ty: .Text)
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
            impl.highestUnkeyedIndexWritten = UInt64(count)
        default:
            let newPath = impl.codingPath + [AnyCodingKey(UInt64(count))]
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
            impl.highestUnkeyedIndexWritten = UInt64(count)
        }
        count += 1
    }

    fileprivate func checkTypeMatch<T>(value: T, objectId: ObjId, index: UInt64, type: TypeOfAutomergeValue) throws {
        if let testCurrentValue = try document.get(obj: objectId, index: index),
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

    mutating func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) ->
        KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey
    {
        let newPath = impl.codingPath + [AnyCodingKey(UInt64(count))]
        let nestedContainer = AutomergeKeyedEncodingContainer<NestedKey>(
            impl: impl,
            codingPath: newPath,
            doc: document
        )
        return KeyedEncodingContainer(nestedContainer)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let newPath = impl.codingPath + [AnyCodingKey(UInt64(count))]
        let nestedContainer = AutomergeUnkeyedEncodingContainer(
            impl: impl,
            codingPath: newPath,
            doc: document
        )
        return nestedContainer
    }

    mutating func superEncoder() -> Encoder {
        preconditionFailure()
    }
}
