import Foundation

/* Code flow example from a user-defined Decoder implementation

    let values = try decoder.container(keyedBy: CodingKeys.self)
    latitude = try values.decode(Double.self, forKey: .latitude)
    longitude = try values.decode(Double.self, forKey: .longitude)

    let additionalInfo = try values.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
    elevation = try additionalInfo.decode(Double.self, forKey: .elevation)

 */

@usableFromInline struct AutomergeDecoderImpl {
    @usableFromInline let doc: Document
    @usableFromInline let codingPath: [CodingKey]
    @usableFromInline let userInfo: [CodingUserInfoKey: Any]

    @inlinable init(
        doc: Document,
        userInfo: [CodingUserInfoKey: Any],
        codingPath: [CodingKey]
    ) {
        self.doc = doc
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    @inlinable public func decode<T: Decodable>(_: T.Type) throws -> T {
        switch T.self {
        case is AutomergeText.Type:
            let container = try container(keyedBy: AutomergeText.CodingKeys.self)
            return try container.decode(T.self, forKey: .value)
        case is Counter.Type:
            let directContainer = try singleValueContainer()
            return try directContainer.decode(T.self)
        case is Data.Type:
            let directContainer = try singleValueContainer()
            return try directContainer.decode(T.self)
        case is Date.Type:
            let directContainer = try singleValueContainer()
            return try directContainer.decode(T.self)
        default:
            return try T(from: self)
        }
    }
}

extension AutomergeDecoderImpl: Decoder {
    @usableFromInline func container<Key>(keyedBy _: Key.Type) throws ->
        KeyedDecodingContainer<Key> where Key: CodingKey
    {
        let result = doc.retrieveObjectId(
            path: codingPath,
            containerType: .Key,
            strategy: .readonly
        )
        switch result {
        case let .success(objectId):
            let objectType = doc.objectType(obj: objectId)
            guard case .Map = objectType else {
                throw DecodingError.typeMismatch([String: Value].self, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "ObjectId \(objectId) returned an type of \(objectType)."
                ))
            }

            let container = AutomergeKeyedDecodingContainer<Key>(
                impl: self,
                codingPath: codingPath,
                objectId: objectId
            )
            return KeyedDecodingContainer(container)
        case let .failure(err):
            throw err
        }
    }

    @usableFromInline func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let result = doc.retrieveObjectId(
            path: codingPath,
            containerType: .Index,
            strategy: .readonly
        )
        switch result {
        case let .success(objectId):
            let objectType = doc.objectType(obj: objectId)
            guard case .List = objectType else {
                throw DecodingError.typeMismatch([String: Value].self, DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: "ObjectId \(objectId) returned an type of \(objectType)."
                ))
            }

            return AutomergeUnkeyedDecodingContainer(
                impl: self,
                codingPath: codingPath,
                objectId: objectId
            )
        case let .failure(err):
            throw err
        }
    }

    @usableFromInline func singleValueContainer() throws -> SingleValueDecodingContainer {
        let result = doc.retrieveObjectId(
            path: codingPath,
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success(objectId):
            guard let finalKey = codingPath.last else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue("Attempting to establish a single value container with an empty coding path.")
            }
            let finalAutomergeValue: Value?
            if let indexValue = finalKey.intValue {
                finalAutomergeValue = try doc.get(obj: objectId, index: UInt64(indexValue))
            } else {
                finalAutomergeValue = try doc.get(obj: objectId, key: finalKey.stringValue)
            }
            guard let value = finalAutomergeValue else {
                return AutomergeSingleValueDecodingContainer(
                    impl: self,
                    codingPath: codingPath,
                    automergeValue: .Scalar(.Null),
                    objectId: objectId
                )
            }
            if case let .Object(textObjectId, .Text) = finalAutomergeValue {
                // if we're creating a singleValueContainer to retrieve an
                // Automerge Text node, then correct the objectId in the container
                // and retrieve the text to make our lives easier in the decoding.
                let stringValue = try doc.text(obj: textObjectId)
                return AutomergeSingleValueDecodingContainer(
                    impl: self,
                    codingPath: codingPath,
                    automergeValue: .Scalar(.String(stringValue)),
                    objectId: textObjectId
                )
            } else {
                return AutomergeSingleValueDecodingContainer(
                    impl: self,
                    codingPath: codingPath,
                    automergeValue: value,
                    objectId: objectId
                )
            }

        case let .failure(err):
            throw err
        }
    }
}
