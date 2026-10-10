import Automerge

public extension Document {
    /// A function that returns a tree-based structure of values that represents the current state of the document.
    func schema() throws -> AutomergeValue {
        try parseToSchema(self, from: ObjId.ROOT)
    }

    /// A function to walk an Automerge document from an initial object identifier that you provide, returning the
    /// schema below as a tree.
    /// - Parameters:
    ///   - doc: The Automerge document to parse.
    ///   - objId: The object identifier at which to start the parse
    /// - Returns: A tree that represents the schema and values.
    func parseToSchema(_ doc: Document, from objId: ObjId) throws -> AutomergeValue {
        switch doc.objectType(obj: objId) {
        case .Map:
            var dictValues: [String: AutomergeValue] = [:]
            for (key, value) in try doc.mapEntries(obj: objId) {
                if case let Value.Scalar(scalarValue) = value {
                    dictValues[key] = .scalar(scalarValue)
                }
                if case let Value.Object(childObjId, _) = value {
                    dictValues[key] = try parseToSchema(doc, from: childObjId)
                }
            }
            return .dict(dictValues)
        case .List:
            var arrayValues: [AutomergeValue] = []
            for value in try doc.values(obj: objId) {
                if case let Value.Scalar(scalarValue) = value {
                    arrayValues.append(.scalar(scalarValue))
                } else {
                    if case let Value.Object(childObjId, _) = value {
                        try arrayValues.append(parseToSchema(doc, from: childObjId))
                    }
                }
            }
            return .array(arrayValues)
        case .Text:
            let stringValue = try doc.text(obj: objId)
            return .text(stringValue)
        }
    }
}
