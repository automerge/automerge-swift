public extension Document {
    /// Looks up the objectId represented by the schema path string you provide.
    /// - Parameter path: A string representation of the location within an Automerge document.
    /// - Returns: The objectId at the schema location you provide, or nil if the path is valid and no object exists in
    /// the document.
    ///
    /// The method throws errors when used with an invalid path.
    func lookupPath(path: String) throws -> ObjId? {
        let codingPath = try AnyCodingKey.parsePath(path)
        if codingPath.isEmpty {
            return ObjId.ROOT
        }
        let result = retrieveObjectId(
            path: codingPath,
            containerType: .Value,
            strategy: .readonly
        )
        switch result {
        case let .success(objectId):
            let existingValue: Value?
            guard let finalCodingKey = codingPath.last else {
                throw CodingKeyLookupError
                    .NoPathForSingleValue("Attempting to establish a single value container with an empty coding path.")
            }
            // get any existing value - type of the `get` call is based on the key type
            if let indexValue = finalCodingKey.intValue {
                let indexSize = length(obj: objectId)
                if indexValue > indexSize {
                    throw CodingKeyLookupError
                        .IndexOutOfBounds("Attempted to look up index \(indexValue) from a list of size \(indexSize).")
                }
                existingValue = try get(obj: objectId, index: UInt64(indexValue))
            } else {
                existingValue = try get(obj: objectId, key: finalCodingKey.stringValue)
            }
            // if the result found is an Automerge container (Text, List, or Object)
            // then return the value
            if case let .Object(finalObjectId, _) = existingValue {
                return finalObjectId
            } else {
                // Otherwise, return nil for any leaf nodes (scalar values or missing schema)
                return nil
            }
        case let .failure(lookupError):
            throw lookupError
        }
    }
}

public extension Sequence where Element == Automerge.PathElement {
    /// Returns a string that represents the schema path.
    func stringPath() -> String {
        let path = map { pathElement in
            switch pathElement.prop {
            case let .Index(idx):
                return String("[\(idx)]")
            case let .Key(key):
                return key
            }
        }.joined(separator: ".")
        return ".\(path)"
    }
}
