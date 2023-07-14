import os // for structured logging

// // MARK: Cache for Object Id Lookups
//
// typealias CacheKey = [AnyCodingKey]
// var cache: [CacheKey: ObjId] = [:]
//
// func upsert(_ key: CacheKey, value: ObjId) {
//    if cache[key] == nil {
//        cache[key] = value
//    }
// }

extension Document {
    @usableFromInline
    func tracePrint(indent: Int = 0, _ stringval: String) {
        #if DEBUG
        if reportingLogLevel >= .tracing {
            if #available(macOS 11, iOS 14, *) {
                let logger = Logger(subsystem: "Automerge", category: "AutomergeEncoder")
                let prefix = String(repeating: " ", count: indent)
                logger.debug("\(prefix, privacy: .public)\(stringval, privacy: .public)")
            }
        }
        #endif
    }

    /// Returns an Automerge objectId for the location within the document.
    ///
    /// The function looks up an Automerge Object Id for a specific schema location, optionally creating schema if
    /// needed.
    /// The combination of `path` and `containerType` determine the `ObjId` returned:
    /// - when requesting an objectId with the type ``EncodingContainerType/Value``, the object Id
    /// from the second to last coding key element is returned, expecting the call-site to do any further look ups based
    /// on the final coding key.
    /// - when requesting an objectId with types ``EncodingContainerType/Index`` or
    /// ``EncodingContainerType/Key``, the object Id is derived from the last coding key element,
    /// and the `containerType` is checked to verify it matches the Automerge schema.
    ///
    /// Control the pattern of when to create schema and what errors to throw by setting the `strategy` property.
    ///
    /// - Parameters:
    ///   - path: An array of instances conforming to CodingKey that make up the schema path.
    ///   - containerType: The container type for the lookup, which effects what is returned and at what level of the
    /// path.
    ///   - strategy: The strategy for creating schema during encoding if it doesn't exist or conflicts with existing
    /// schema. The strategy defaults to ``SchemaStrategy/default``.
    /// - Returns: A result type that contains a tuple of an Automerge object Id of the relevant container, or an error
    /// if the retrieval failed or there was conflicting schema within in the document.
    @inlinable func retrieveObjectId(
        path: [CodingKey],
        containerType: EncodingContainerType,
        strategy: SchemaStrategy
    ) -> Result<ObjId, CodingKeyLookupError> {
        // with .Value container type returning second-to-last ObjectId, and expecting the
        // caller to know they'll need to special case whatever they do with the final piece.

        // CONSIDER: making a method that takes an objectId and CodingKey and returns the Value?

        // This method returns a Result type because the Codable protocol constrains the
        // container initializers to not throw on initialization.
        // Instead we stash the lookup failure into the container, and throw the relevant
        // error on any call to one of the `.encode()` methods, which do throw.
        // This defers the error condition, and the container is essentially invalid in this
        // state, but it provides a smoother integration with Codable.

        // Path scenarios by the type of Codable container that invokes the lookup.
        //
        // [] + Key -> ObjId.ROOT
        // [] + Index = error
        // [] + Value = error
        // [foo] + Value = ObjId.Root
        // [foo] + Index = error
        // [foo] + Key = ObjId.lookup(/Root/foo)   (container)
        // [1] + (Value|Index|Key) = error (root is always a map)
        // [foo, 1] + Value = /Root/foo, index 1
        // [foo, 1] + Index = /Root/foo, index 1   (container)
        // [foo, 1] + Key = /Root/foo, index 1     (container)
        // [foo, bar] + Value = /Root/foo, key bar
        // [foo, bar] + Index = /Root/foo, key bar (container)
        // [foo, bar] + Key = /Root/foo, key bar   (container)

        // Pre-allocate an array the same length as `path` for ObjectId lookups
        var matchingObjectIds: [Int: ObjId] = [:]
        matchingObjectIds.reserveCapacity(path.count)

        tracePrint(
            "`retrieveObjectId` with path [\(path.map { AnyCodingKey($0) })] for container type \(containerType), with strategy: \(strategy)"
        )

        // - Efficiency boost using a cache
        // Iterate from the N-1 end of path, backwards - checking [] -> (ObjectId, ObjType) cache,
        // checking until we get a positive hit from the cache. Worst case there'll be nothing in
        // the cache and we iterate to the bottom. Save that as the starting cursor position.
        let startingPosition = 0
        var previousObjectId = ObjId.ROOT

        if strategy == .override {
            return .failure(CodingKeyLookupError.UnexpectedLookupFailure("Override strategy not yet implemented"))
        }

        // initial conditions if we're handed an empty path
        if path.isEmpty {
            switch containerType {
            case .Key:
                return .success(ObjId.ROOT)
            case .Index, .Value:
                return .failure(
                    CodingKeyLookupError
                        .InvalidIndexLookup("An empty path refers to ROOT and is always a map.")
                )
            }
        }

        // Iterate the cursor position forward doing lookups against the Automerge document
        // until we get to the second-to-last element. This range ensures that we're iterating
        // over "expected containers"
        for position in startingPosition ..< (path.count - 1) {
            tracePrint(indent: position, "Checking position \(position): '\(path[position])'")
            // Strategy to use while creating schema:
            // defined in SchemaStrategy

            // (default)
            // schema-create-on-nil: If the schema *doesn't* exist - nil lookups when searched - create
            // the relevant schema as it goes. This doesn't account for any specific value types or type checking.
            //
            // schema-error-on-type-mismatch: If schema in Automerge is a scalar value, Text, or mis-matched
            // list/object types, throw an error instead of overwriting the schema.

            // (!override!)
            // schema-overwrite: Disregard any schema that currently exists and overwrite values as needed to
            // establish the schema that is being encoded.

            // (?readonly?)
            // read-only/super-double-strict: Only allow encoding into schema that is ALREADY present within
            // Automerge. Adding additional values (to a map, or to a list) would be invalid in these cases.
            // In a large sense, it's an "update values only" kind of scenario.

            // Determine the type of the previous element by inspecting the current path.
            // If it's got an index value, then it's a reference in a list.
            // Otherwise it's a key on an object.
            if let indexValue = path[position].intValue {
                tracePrint(indent: position, "Checking against index position \(indexValue).")
                // If it's an index, verify that it doesn't represent an element beyond the end of an existing list.
                if indexValue > length(obj: previousObjectId) {
                    if strategy == .readonly {
                        return .failure(
                            CodingKeyLookupError
                                .IndexOutOfBounds(
                                    "Index value \(indexValue) is beyond the length: \(length(obj: previousObjectId)) and schema is read-only"
                                )
                        )
                    } else if indexValue > (length(obj: previousObjectId) + 1) {
                        return .failure(
                            CodingKeyLookupError
                                .IndexOutOfBounds(
                                    "Index value \(indexValue) is too far beyond the length: \(length(obj: previousObjectId)) to append a new item."
                                )
                        )
                    }
                }

                // Look up Automerge `Value` matching this index within the list
                do {
                    if let value = try get(obj: previousObjectId, index: UInt64(indexValue)) {
                        switch value {
                        case let .Object(objId, objType):
                            //                EncoderPathCache.upsert(extendedPath, value: (objId, objType))
                            // if the type of Object is Text, we should error here because the schema can't extend
                            // through a
                            // leaf node
                            if objType == .Text {
                                // If the looked up Value is a Text node, then it's a leaf on the schema structure.
                                // If there's remaining values to be looked up, the overall path is invalid.
                                return .failure(
                                    CodingKeyLookupError
                                        .PathExtendsThroughText(
                                            "Path at \(path[0 ... position]) is a Text object, which is not a container - and the path has additional elements: \(path[(position + 1)...])."
                                        )
                                )
                            }
                            matchingObjectIds[position] = objId
                            previousObjectId = objId
                            tracePrint(
                                indent: position,
                                "Found \(path[0 ... position]) as objectId \(objId) of type \(objType)"
                            )
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .PathExtendsThroughScalar(
                                        "Path at \(path[0 ... position]) is a single value, not a container - and the path has additional elements: \(path[(position + 1)...])."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        tracePrint(
                            indent: position,
                            "Nothing pre-existing in schema at \(path[0 ... position]), will need to create a container."
                        )
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .SchemaMissing(
                                        "Nothing in schema exists at \(path[0 ... position]) - look u returns nil"
                                    )
                            )
                        } else { // couldn't find the object via lookup, so we need to create it
                            // Look up the kind of object to create by inspecting the "next path" element
                            tracePrint(indent: position, "Need to create a container at \(path[0 ... position]).")
                            tracePrint(indent: position, "Next path element is '\(path[position + 1])'.")
                            if let _ = path[position + 1].intValue {
                                // the next item is a list, so create a new list within this list at the index value the
                                // current position indicates.
                                let newObjectId = try insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .List
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint(
                                    indent: position,
                                    "created \(path[0 ... position]) as objectId \(newObjectId) of type List"
                                )
                                // add to cache
                                //                        EncoderPathCache.upsert(extendedPath,value: (newObjectId,
                                //                        .List))
                            } else {
                                // need to create an object
                                let newObjectId = try insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .Map
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint(
                                    indent: position,
                                    "created \(path[0 ... position]) as objectId \(newObjectId) of type Map"
                                )
                                // add to cache
                                //                        EncoderPathCache.upsert(extendedPath,value: (newObjectId,
                                //                        .Map))
                                // carry on with remaining path elements
                            }
                        }
                    }
                } catch {
                    return .failure(.AutomergeDocError(error))
                }
            } else { // path[position] is a string-based key, so we need to get - or insert - an Object
                let keyValue = path[position].stringValue
                tracePrint(indent: position, "Checking against key \(keyValue).")
                do {
                    if let value = try get(obj: previousObjectId, key: keyValue) {
                        switch value {
                        case let .Object(objId, objType):
                            //                EncoderPathCache.upsert(extendedPath, value: (objId, objType))

                            // If the looked up Value is a Text node, then it's a leaf on the schema structure.
                            // If there's remaining values to be looked up, the overall path is invalid.
                            if objType == .Text {
                                return .failure(
                                    CodingKeyLookupError
                                        .PathExtendsThroughText(
                                            "Path at \(path[0 ... position]) is a Text object, which is not a container - and the path has additional elements: \(path[(position + 1)...])."
                                        )
                                )
                            }
                            matchingObjectIds[position] = objId
                            previousObjectId = objId
                            tracePrint(
                                indent: position,
                                "Found \(path[0 ... position]) as objectId \(objId) of type \(objType)"
                            )
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            // If there's remaining values to be looked up, the overall path is invalid.
                            return .failure(
                                CodingKeyLookupError
                                    .PathExtendsThroughScalar(
                                        "Path at \(path[0 ... position]) is a single value, not a container - and the path has additional elements: \(path[(position + 1)...])."
                                    )
                            )
                        }
                    } else { // value returned from doc.get() is nil, we'll need to create it
                        tracePrint(
                            indent: position,
                            "Nothing pre-existing in schema at \(path[0 ... position]), will need to create a container."
                        )
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .SchemaMissing(
                                        "Nothing in schema exists at \(path[0 ... position]) - look u returns nil"
                                    )
                            )
                        } else { // looked-up value was nil AND we're not read-only, create the object
                            tracePrint(indent: position, "Need to create a container at \(path[0 ... position]).")
                            tracePrint(indent: position, "Next path element is \(path[position + 1]).")
                            // Look up the kind of object to create by inspecting the "next path" element
                            if let _ = path[position + 1].intValue {
                                // the next item is a list, so create a new list within this object using the key value
                                // the current position indicates.
                                let newObjectId = try putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .List
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint(
                                    indent: position,
                                    "created \(path[0 ... position]) as objectId \(newObjectId) of type List"
                                )
                                // add to cache
                                //                       EncoderPathCache.upsert(extendedPath, value: (newObjectId,
                                //                        .List))
                            } else {
                                // the next item is an object, so create a new object within this object using the key
                                // value the current position indicates.
                                let newObjectId = try putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .Map
                                )
                                matchingObjectIds[position] = newObjectId
                                previousObjectId = newObjectId
                                tracePrint(
                                    indent: position,
                                    "created \(path[0 ... position]) as objectId \(newObjectId) of type Map"
                                )
                                // add to cache
                                //                       EncoderPathCache.upsert(extendedPath, value: (newObjectId,
                                //                        .Map))
                                // carry on with remaining pathelements
                            }
                        }
                    }
                } catch {
                    return .failure(.AutomergeDocError(error))
                }
            }
        }

        #if DEBUG
        tracePrint("All prior containers created or found:")
        for position in startingPosition ..< (path.count - 1) {
            tracePrint("   \(position) -> \(String(describing: matchingObjectIds[position]))")
        }
        #endif

        // Then what we do depends on the type of lookup.
        // - on SingleValueContainer, we return the second-to-last objectId and the key and/or Index
        // - on KeyedContainer or UnkeyedContainer, we look up and return the final objectId
        let finalpiece = path[path.count - 1]
        switch containerType {
        case .Index, .Key: // the element that we're looking up (or creating) is for a key or index container
            if let indexValue = finalpiece.intValue { // The value within the CodingKey indicates it's a List
                tracePrint(
                    indent: path.count - 1,
                    "Final piece of the path is '\(finalpiece)', index \(indexValue) of a List."
                )
                // short circuit beyond-length of array
                if indexValue > length(obj: previousObjectId) {
                    if strategy == .readonly {
                        return .failure(
                            CodingKeyLookupError
                                .IndexOutOfBounds(
                                    "Index value \(indexValue) is beyond the length: \(length(obj: previousObjectId)) and schema is read-only"
                                )
                        )
                    } else if indexValue > (length(obj: previousObjectId) + 1) {
                        return .failure(
                            CodingKeyLookupError
                                .IndexOutOfBounds(
                                    "Index value \(indexValue) is too far beyond the length: \(length(obj: previousObjectId)) to append a new item."
                                )
                        )
                    }
                }

                // Look up Automerge `Value` matching this index within the list
                do {
                    tracePrint(
                        indent: path.count - 1,
                        "Look up what's at index \(indexValue) of objectId: \(previousObjectId):"
                    )
                    if let value = try get(obj: previousObjectId, index: UInt64(indexValue)) {
                        switch value {
                        case let .Object(objId, objType):
                            switch objType {
                            case .Text:
                                return .failure(
                                    CodingKeyLookupError
                                        .MismatchedSchema(
                                            "Path at \(path) is a Text object, which is not the List container that we expected."
                                        )
                                )
                            case .Map:
                                if containerType == .Key {
                                    tracePrint("Found Object container with ObjectId \(objId).")
                                    return .success(objId)
                                } else {
                                    return .failure(
                                        CodingKeyLookupError
                                            .MismatchedSchema(
                                                "Path at \(path) is an object container, not the List container that we expected."
                                            )
                                    )
                                }
                            case .List:
                                //                            EncoderPathCache.upsert(extendedPath, value: (objId,
                                //                            objType))
                                if containerType == .Index {
                                    tracePrint("Found List container with ObjectId \(objId).")
                                    return .success(objId)
                                } else {
                                    return .failure(
                                        CodingKeyLookupError
                                            .MismatchedSchema(
                                                "Path at \(path) is a list container, not the Object container that we expected."
                                            )
                                    )
                                }
                            }
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .MismatchedSchema(
                                        "Path at \(path) is an scalar value, which is not the List container that we expected."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        tracePrint(indent: path.count - 1, "Need to create a container at \(path).")
                        tracePrint(indent: path.count - 1, "Path type to create is \(containerType).")
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .SchemaMissing(
                                        "Nothing in schema exists at \(path) - look u returns nil"
                                    )
                            )
                        } else {
                            if containerType == .Index {
                                // need to create a list within the list
                                let newObjectId = try insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .List
                                )
                                //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                                tracePrint(
                                    indent: path.count - 1,
                                    "Created new List container with ObjectId \(newObjectId)."
                                )
                                return .success(newObjectId)
                            } else {
                                // need to create a map within the list
                                let newObjectId = try insertObject(
                                    obj: previousObjectId,
                                    index: UInt64(indexValue),
                                    ty: .Map
                                )
                                //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                                tracePrint(
                                    indent: path.count - 1,
                                    "Created new Map container with ObjectId \(newObjectId)."
                                )
                                return .success(newObjectId)
                            }
                        }
                    }
                } catch {
                    return .failure(.AutomergeDocError(error))
                }
            } else { // final path element is a key
                let keyValue = finalpiece.stringValue

                // Look up Automerge `Value` matching this key on an object
                do {
                    tracePrint(
                        indent: path.count - 1,
                        "Look up what's at key '\(keyValue)' of objectId: \(previousObjectId)."
                    )
                    if let value = try get(obj: previousObjectId, key: keyValue) {
                        switch value {
                        case let .Object(objId, objType):
                            switch objType {
                            case .Text:
                                return .failure(
                                    CodingKeyLookupError
                                        .MismatchedSchema(
                                            "Container at \(path) is a Text object, which is not the Object container expected."
                                        )
                                )
                            case .Map:
                                if containerType == .Key {
                                    //                            EncoderPathCache.upsert(extendedPath, value: (objId,
                                    //                            objType))
                                    tracePrint(indent: path.count - 1, "Found Map container with ObjectId \(objId).")
                                    return .success(objId)
                                } else {
                                    return .failure(
                                        CodingKeyLookupError
                                            .MismatchedSchema(
                                                "Container at \(path) is a Map container, not the List container that we expected."
                                            )
                                    )
                                }
                            case .List:
                                if containerType == .Index {
                                    //                            EncoderPathCache.upsert(extendedPath, value: (objId,
                                    //                            objType))
                                    tracePrint(indent: path.count - 1, "Found List container with ObjectId \(objId).")
                                    return .success(objId)
                                } else {
                                    return .failure(
                                        CodingKeyLookupError
                                            .MismatchedSchema(
                                                "Container at \(path) is a List container, not the object container that we expected."
                                            )
                                    )
                                }
                            }
                        case .Scalar:
                            // If the looked up Value is a Scalar value, then it's a leaf on the schema structure.
                            return .failure(
                                CodingKeyLookupError
                                    .MismatchedSchema(
                                        "Item at \(path) is an scalar value, which is not the List container that we expected."
                                    )
                            )
                        }
                    } else { // value returned from the lookup in Automerge at this position is `nil`
                        tracePrint(indent: path.count - 1, "Need to create a container at \(path).")
                        tracePrint(indent: path.count - 1, "Path type to create is \(containerType).")
                        if strategy == .readonly {
                            // path is a valid request, there's just nothing there
                            return .failure(
                                CodingKeyLookupError
                                    .SchemaMissing(
                                        "Nothing in schema exists at \(path) - look u returns nil"
                                    )
                            )
                        } else {
                            if containerType == .Index {
                                // need to create a list within the list
                                let newObjectId = try putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .List
                                )
                                //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                                tracePrint(
                                    indent: path.count - 1,
                                    "Created new List container with ObjectId \(newObjectId)."
                                )
                                return .success(newObjectId)
                            } else {
                                // need to create a map within the list
                                let newObjectId = try putObject(
                                    obj: previousObjectId,
                                    key: keyValue,
                                    ty: .Map
                                )
                                //                        EncoderPathCache.upsert(extendedPath, value: (objId, .List))
                                tracePrint(
                                    indent: path.count - 1,
                                    "Created new Map container with ObjectId \(newObjectId)."
                                )
                                return .success(newObjectId)
                            }
                        }
                    }
                } catch {
                    return .failure(.AutomergeDocError(error))
                }
            }
        case .Value:
            if path.count < 2 {
                // corner case where the root encoder (equivalent to position -1 in the matchingObjectIds) isn't in the
                // lookup list
                return .success(ObjId.ROOT)
            } else {
                guard let containerObjectId = matchingObjectIds[path.count - 2] else {
                    fatalError(
                        "objectId lookups failed to identify an object Id for the last element in path: \(path)"
                    )
                }
                return .success(containerObjectId)
            }
        }
    }
}
