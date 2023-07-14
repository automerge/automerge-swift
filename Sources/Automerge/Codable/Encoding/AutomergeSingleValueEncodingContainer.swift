import Foundation // for Date support
import os // for structured logging

struct AutomergeSingleValueEncodingContainer: SingleValueEncodingContainer {
    let impl: AutomergeEncoderImpl
    let codingPath: [CodingKey]
    let document: Document
    /// The objectId that this keyed encoding container maps to within an Automerge document.
    ///
    /// If `document` is `nil`, the error attempting to retrieve should be in ``lookupError``.
    let objectId: ObjId?
    let codingkey: AnyCodingKey?
    /// An error captured when attempting to look up or create an objectId in Automerge based on the coding path
    /// provided.
    let lookupError: Error?

    init(impl: AutomergeEncoderImpl, codingPath: [CodingKey], doc: Document) {
        self.impl = impl
        self.codingPath = codingPath
        document = doc
        switch doc.retrieveObjectId(
            path: codingPath,
            containerType: .Value,
            strategy: impl.schemaStrategy
        ) {
        case let .success(objId):
            if let lastCodingKey = codingPath.last {
                objectId = objId
                codingkey = AnyCodingKey(lastCodingKey)
                lookupError = nil
            } else {
                objectId = objId
                codingkey = nil
                lookupError = CodingKeyLookupError
                    .NoPathForSingleValue("Attempting to encode a value with an empty coding path.")
            }
        case let .failure(capturedError):
            objectId = nil
            codingkey = nil
            lookupError = capturedError
        }
        if #available(macOS 11, iOS 14, *) {
            let logger = Logger(subsystem: "Automerge", category: "AutomergeEncoder")
            if impl.reportingLogLevel >= LogVerbosity.debug {
                logger
                    .debug(
                        "Establishing Single Value Encoding Container for path \(codingPath.map { AnyCodingKey($0) })"
                    )
            }
        }
    }

    mutating func encodeNil() throws {}

    mutating func encode(_ value: Bool) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Int) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Int8) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Int16) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Int32) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Int64) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: UInt) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: UInt8) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: UInt16) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: UInt32) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: UInt64) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Float) throws {
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: codingPath,
                debugDescription: "Unable to encode Float.\(value) directly in Automerge."
            ))
        }

        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: Double) throws {
        guard !value.isNaN, !value.isInfinite else {
            throw EncodingError.invalidValue(value, .init(
                codingPath: codingPath,
                debugDescription: "Unable to encode Double.\(value) directly in Automerge."
            ))
        }

        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode(_ value: String) throws {
        try scalarValueEncode(value: value)
        impl.singleValueWritten = true
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        preconditionCanEncodeNewValue()
        guard let objectId = objectId else {
            throw reportBestError()
        }
        switch T.self {
        case is Date.Type:
            // Capture and override the default encodable pathing for Date since
            // Automerge supports it as a primitive value type.
            let downcastDate = value as! Date
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            let valueToWrite = downcastDate.toScalarValue()
            if let indexToWrite = codingkey.intValue {
                if let testCurrentValue = try document.get(obj: objectId, index: UInt64(indexToWrite)),
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
                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: valueToWrite)
            } else {
                if let testCurrentValue = try document.get(obj: objectId, key: codingkey.stringValue),
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
                try document.put(obj: objectId, key: codingkey.stringValue, value: valueToWrite)
            }
        case is Data.Type:
            // Capture and override the default encodable pathing for Data since
            // Automerge supports it as a primitive value type.
            let downcastData = value as! Data
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            let valueToWrite = downcastData.toScalarValue()
            if let indexToWrite = codingkey.intValue {
                if impl.cautiousWrite {
                    if let testCurrentValue = try document.get(obj: objectId, index: UInt64(indexToWrite)),
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
                }

                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: valueToWrite)
            } else {
                if impl.cautiousWrite {
                    if let testCurrentValue = try document.get(obj: objectId, key: codingkey.stringValue),
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
                }

                try document.put(obj: objectId, key: codingkey.stringValue, value: valueToWrite)
            }
        case is Counter.Type:
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            let downcastCounter = value as! Counter
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            let valueToWrite = downcastCounter.toScalarValue()
            if let indexToWrite = codingkey.intValue {
                if impl.cautiousWrite {
                    if let testCurrentValue = try document.get(obj: objectId, index: UInt64(indexToWrite)),
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
                }
                try document.insert(obj: objectId, index: UInt64(indexToWrite), value: valueToWrite)
            } else {
                if impl.cautiousWrite {
                    if let testCurrentValue = try document.get(obj: objectId, key: codingkey.stringValue),
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
                }
                try document.put(obj: objectId, key: codingkey.stringValue, value: valueToWrite)
            }
        case is Text.Type:
            guard let codingkey = codingkey else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue(
                        "No coding key was found from looking up path \(codingPath) when encoding \(type(of: T.self))."
                    )
            }
            // Capture and override the default encodable pathing for Counter since
            // Automerge supports it as a primitive value type.
            let downcastText = value as! Text

            let existingValue: Value?
            // get any existing value - type of `get` based on the key type
            if let indexToWrite = codingkey.intValue {
                existingValue = try document.get(obj: objectId, index: UInt64(indexToWrite))
            } else {
                existingValue = try document.get(obj: objectId, key: codingkey.stringValue)
            }

            let textNodeId: ObjId
            if let existingNode = existingValue {
                guard case let .Object(textId, .Text) = existingNode else {
                    throw CodingKeyLookupError
                        .MismatchedSchema(
                            "Text Encoding on KeyedContainer at \(codingPath) exists and is \(existingNode), not Text."
                        )
                }
                textNodeId = textId
            } else {
                // no existing value is there, so create a Text node
                if let indexToWrite = codingkey.intValue {
                    textNodeId = try document.putObject(obj: objectId, index: UInt64(indexToWrite), ty: .Text)
                } else {
                    textNodeId = try document.putObject(obj: objectId, key: codingkey.stringValue, ty: .Text)
                }
            }

            // Iterate through
            let currentText = try! document.text(obj: textNodeId).utf8
            let diff: CollectionDifference<String.UTF8View.Element> = downcastText.value.utf8
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
        default:
            try value.encode(to: impl)
            impl.singleValueWritten = true
        }
    }

    private func scalarValueEncode(value: some ScalarValueRepresentable) throws {
        preconditionCanEncodeNewValue()
        guard let objectId = objectId, let codingkey = codingkey else {
            throw reportBestError()
        }
        let valueToWrite = value.toScalarValue()
        if let indexToWrite = codingkey.intValue {
            if impl.cautiousWrite {
                if let testCurrentValue = try document.get(obj: objectId, index: UInt64(indexToWrite)),
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
            }
            try document.insert(obj: objectId, index: UInt64(indexToWrite), value: valueToWrite)
        } else {
            if impl.cautiousWrite {
                if let testCurrentValue = try document.get(obj: objectId, key: codingkey.stringValue),
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
            }
            try document.put(obj: objectId, key: codingkey.stringValue, value: valueToWrite)
        }
    }

    func preconditionCanEncodeNewValue() {
        precondition(
            impl.singleValueWritten == false,
            "Attempt to encode value through single value container when previously value already encoded."
        )
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
}
