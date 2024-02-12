import Automerge

public enum AutomergeValue: Hashable, Equatable {
    case dict([String: AutomergeValue])
    case array([AutomergeValue])
    case text(String)
    case scalar(ScalarValue)
}

extension AutomergeValue: CustomStringConvertible {
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
    /// A testing function that dumps the vaguely-typed contents of an Automerge document for the purposes of debugging.
    ///
    /// The output is all through print to STDOUT.
    func schema() throws -> AutomergeValue {
        try parseToSchema(self, from: ObjId.ROOT)
    }

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
