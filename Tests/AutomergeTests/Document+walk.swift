import Automerge

extension Document {
    /// A testing function that dumps the vaguely-typed contents of an Automerge document for the purposes of debugging.
    ///
    /// The output is all through print to STDOUT.
    func walk() throws {
        print("{")
        try walk(self, from: ObjId.ROOT)
        print("}")
    }

    private func walk(_ doc: Document, from objId: ObjId, indent: Int = 1) throws {
        let indentString = String(repeating: " ", count: indent * 2)
        let whitequote = "\""
        switch doc.objectType(obj: objId) {
        case .Map:
            print("\(indentString){")
            for (key, value) in try doc.mapEntries(obj: objId) {
                if case let Value.Scalar(scalarValue) = value {
                    print(
                        "\(indentString)\(whitequote)\("\(key)")\(whitequote) :\("\(scalarValue)")"
                    )
                }
                if case let Value.Object(childObjId, _) = value {
                    print("\(indentString)\(whitequote)\("\(key)")\(whitequote) : \("{")")
                    try walk(doc, from: childObjId, indent: indent + 1)
                    print("\(indentString)}")
                }
            }
            print("\(indentString)}")
        case .List:
            if doc.length(obj: objId) == 0 {
                print("\(indentString)[]")
            } else {
                print("\(indentString)[")
                for value in try doc.values(obj: objId) {
                    if case let Value.Scalar(scalarValue) = value {
                        print("\(indentString)  \("\(scalarValue)")")
                    } else {
                        if case let Value.Object(childObjId, _) = value {
                            try walk(doc, from: childObjId, indent: indent + 1)
                        }
                    }
                }
                print("\(indentString)]")
            }
        case .Text:
            let stringValue = try doc.text(obj: objId)
            print("\(indentString)\("Text[")\(whitequote)\(stringValue)\(whitequote)\("]")")
        }
    }
}
