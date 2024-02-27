import Automerge

/// A type that mirrors the Automerge internal types
public enum AutomergeValue: Hashable, Equatable {
    /// Represents a dictionary or map type.
    case dict([String: AutomergeValue])
    /// Represents an array or list type.
    case array([AutomergeValue])
    /// Represents an Automerge Text type.
    case text(String)
    /// Represents an Automerge scalar value.
    case scalar(ScalarValue)
}

extension AutomergeValue: CustomStringConvertible {
    /// A text representation of the schema type and value.
    public var description: String {
        switch self {
        case let .dict(dictionary):
            return "{\(dictionary.description)}"
        case let .array(array):
            return "[\(array.description)]"
        case let .text(string):
            return "T{\(string)}"
        case let .scalar(scalarValue):
            return scalarValue.description
        }
    }
}

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
