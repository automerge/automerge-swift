#if canImport(os)
import os
#endif

/// Convenience marker within AutomergeEncoderImpl to indicate the kind of associated container

/// The internal implementation of AutomergeEncoder.
///
/// Instances of the class capture one of the various kinds of schema value types - single value, array, or object.
/// The instance also tracks the dynamic state associated with that value as it encodes types you provide.
final class AutomergeEncoderImpl {
    let userInfo: [CodingUserInfoKey: Any]
    let codingPath: [CodingKey]
    let document: Document
    let schemaStrategy: SchemaStrategy
    let cautiousWrite: Bool
    let reportingLogLevel: LogVerbosity
    // indicator that the singleValue has written a value
    var singleValueWritten: Bool = false

    // Tracking details of what was written by Codable implementations
    // working with the container encode() calls. The details captured
    // in these variables allow us to "clean up" anything extraneous
    // in the data store that wasn't overwritten by an encode.
    var containerType: EncodingContainerType?
    var childEncoders: [AutomergeEncoderImpl] = []
    var highestUnkeyedIndexWritten: UInt64?
    var mapKeysWritten: [String] = []
    var objectIdForContainer: ObjId?

    init(
        userInfo: [CodingUserInfoKey: Any],
        codingPath: [CodingKey],
        doc: Document,
        strategy: SchemaStrategy,
        cautiousWrite: Bool,
        logLevel: LogVerbosity
    ) {
        self.userInfo = userInfo
        self.codingPath = codingPath
        document = doc
        schemaStrategy = strategy
        self.cautiousWrite = cautiousWrite
        reportingLogLevel = logLevel
    }

    func postencodeCleanup(below prefix: [AnyCodingKey] = []) {
        precondition(objectIdForContainer != nil)
        precondition(containerType != nil)
        guard let objectIdForContainer, let containerType else {
            return
        }
        if codingPath.map({ AnyCodingKey($0) }).starts(with: prefix) {
            switch containerType {
            case .Key:
                // Remove keys that exist in this objectId that weren't
                // written during encode. (clean up 'dead' keys from maps)
                let extraAutomergeKeys = document.keys(obj: objectIdForContainer)
                    .filter { keyValue in
                        !mapKeysWritten.contains(keyValue)
                    }
                for extraKey in extraAutomergeKeys {
                    do {
                        try document.delete(obj: objectIdForContainer, key: extraKey)
                    } catch {
                        fatalError("Unable to delete extra key \(extraKey) during post-encode cleanup: \(error)")
                    }
                }
            case .Index:
                var highestIndexWritten: Int64 = -1
                if let highestUnkeyedIndexWritten {
                    // If highestUnkeyedIndexWritten is nil, then a list/array was encoded
                    // with no items within it.
                    highestIndexWritten = Int64(highestUnkeyedIndexWritten)
                }
                let lengthOfAutomergeContainer = document.length(obj: objectIdForContainer)
                if lengthOfAutomergeContainer > 0 {
                    var highestAutomergeIndex = Int64(lengthOfAutomergeContainer - 1)
                    // Remove index elements that exist in this objectId beyond
                    // the max written during encode. (allow arrays to 'shrink')
                    while highestAutomergeIndex > highestIndexWritten {
                        do {
                            try document.delete(obj: objectIdForContainer, index: UInt64(highestAutomergeIndex))
                            highestAutomergeIndex -= 1
                        } catch {
                            fatalError(
                                "Unable to delete index position \(highestAutomergeIndex) during post-encode cleanup: \(error)"
                            )
                        }
                    }
                }
            case .Value:
                // no cleanup needed on a leaf node
                return
            }
        }
        // Recursively walk the encoded tree doing "cleanup".
        for child in childEncoders {
            child.postencodeCleanup()
        }
    }
}

// A bit of example code that someone might implement to provide Encodable conformance
// for their own type.
//
// extension Coordinate: Encodable {
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(latitude, forKey: .latitude)
//        try container.encode(longitude, forKey: .longitude)
//
//        var additionalInfo = container.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
//        try additionalInfo.encode(elevation, forKey: .elevation)
//    }
// }

extension AutomergeEncoderImpl: Encoder {
    /// Returns a KeyedCodingContainer that a developer uses when conforming to the Encodable protocol.
    /// - Parameter _: The CodingKey type that this keyed coding container expects when encoding properties.
    ///
    /// This method provides a generic, type-erased container that conforms to KeyedEncodingContainer, allowing
    /// either a developer, or compiler synthesized code, to encode single value properties or create nested containers,
    /// such as an array (nested unkeyed container) or dictionary (nested keyed container) while serializing/encoding
    /// their type.
    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        guard singleValueWritten == false else {
            preconditionFailure()
        }

        let container = AutomergeKeyedEncodingContainer<Key>(
            impl: self,
            codingPath: codingPath,
            doc: document
        )
        containerType = .Key
        return KeyedEncodingContainer(container)
    }

    /// Returns an UnkeyedEncodingContainer that a developer uses when conforming to the Encodable protocol.
    ///
    /// This method provides a generic, type-erased container that conforms to UnkeyedEncodingContainer, allowing
    /// either a developer, or compiler synthesized code, to encode single value properties or create nested containers,
    /// such as an array (nested unkeyed container) or dictionary (nested keyed container) while serializing/encoding
    /// their type.
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        guard singleValueWritten == false else {
            preconditionFailure()
        }

        containerType = .Index
        return AutomergeUnkeyedEncodingContainer(
            impl: self,
            codingPath: codingPath,
            doc: document
        )
    }

    /// Returns a SingleValueEncodingContainer that a developer uses when conforming to the Encodable protocol.
    ///
    /// This method provides a generic, type-erased container that conforms to KeyedEncodingContainer, allowing
    /// either a developer, or compiler synthesized code, to encode single value properties or create nested containers,
    /// such as an array (nested unkeyed container) or dictionary (nested keyed container) while serializing/encoding
    /// their type.
    func singleValueContainer() -> SingleValueEncodingContainer {
        guard singleValueWritten == false else {
            preconditionFailure()
        }

        containerType = .Value
        return AutomergeSingleValueEncodingContainer(
            impl: self,
            codingPath: codingPath,
            doc: document
        )
    }
}
