import Foundation // for Date support
import os // for structured logging

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

        switch T.self {
        case is Date.Type:
            // Capture and override the default encodable pathing for Date since
            // Automerge supports it as a primitive value type.
            let downcastDate = value as! Date
            let valueToWrite = downcastDate.toScalarValue()
            if let testCurrentValue = try document.get(obj: objectId, index: UInt64(count)),
               TypeOfAutomergeValue.from(testCurrentValue) != TypeOfAutomergeValue.from(valueToWrite)
            {
                // BLOW UP HERE
                throw EncodingError.invalidValue(
                    value,
                    EncodingError
                        .Context(
                            codingPath: codingPath,
                            debugDescription: "The type in the automerge document (\(TypeOfAutomergeValue.from(testCurrentValue))) doesn't match the type being written (\(TypeOfAutomergeValue.from(valueToWrite)))"
                        )
                )
            }
            try document.insert(obj: objectId, index: UInt64(count), value: valueToWrite)
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case is Data.Type:
            // Capture and override the default encodable pathing for Data since
            // Automerge supports it as a primitive value type.
            let downcastData = value as! Data
            let valueToWrite = downcastData.toScalarValue()
            if let testCurrentValue = try document.get(obj: objectId, index: UInt64(count)),
               TypeOfAutomergeValue.from(testCurrentValue) != TypeOfAutomergeValue.from(valueToWrite)
            {
                // BLOW UP HERE
                throw EncodingError.invalidValue(
                    value,
                    EncodingError
                        .Context(
                            codingPath: codingPath,
                            debugDescription: "The type in the automerge document (\(TypeOfAutomergeValue.from(testCurrentValue))) doesn't match the type being written (\(TypeOfAutomergeValue.from(valueToWrite)))"
                        )
                )
            }

            try document.insert(obj: objectId, index: UInt64(count), value: valueToWrite)
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case is Counter.Type:
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            let downcastCounter = value as! Counter
            let valueToWrite = downcastCounter.toScalarValue()
            if let testCurrentValue = try document.get(obj: objectId, index: UInt64(count)),
               TypeOfAutomergeValue.from(testCurrentValue) != TypeOfAutomergeValue.from(valueToWrite)
            {
                // BLOW UP HERE
                throw EncodingError.invalidValue(
                    value,
                    EncodingError
                        .Context(
                            codingPath: codingPath,
                            debugDescription: "The type in the automerge document (\(TypeOfAutomergeValue.from(testCurrentValue))) doesn't match the type being written (\(TypeOfAutomergeValue.from(valueToWrite)))"
                        )
                )
            }
            try document.insert(obj: objectId, index: UInt64(count), value: valueToWrite)
            impl.highestUnkeyedIndexWritten = UInt64(count)
        case is AutomergeText.Type:
            // Capture and override the default encodable pathing for AutomergeText since
            // Automerge supports it as a primitive value type.
            let downcastText = value as! AutomergeText

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
            if downcastText.doc == nil || downcastText.objId == nil {
                // instance is an unbound instance - implying a new reference into the Automerge
                // document. Attempt to serialize the unboundStorage into place.
                if !downcastText._unboundStorage.isEmpty {
                    // Iterate through
                    let currentText = try! document.text(obj: textNodeId).utf8
                    let diff: CollectionDifference<String.UTF8View.Element> = downcastText._unboundStorage.utf8
                        .difference(from: currentText)
                    for change in diff {
                        switch change {
                        case let .insert(offset, element, _):
                            let char = String(bytes: [element], encoding: .utf8)
                            try document.spliceText(obj: textNodeId, start: UInt64(offset), delete: 0, value: char)
                        case let .remove(offset, _, _):
                            try document.spliceText(obj: textNodeId, start: UInt64(offset), delete: 1)
                        }
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
