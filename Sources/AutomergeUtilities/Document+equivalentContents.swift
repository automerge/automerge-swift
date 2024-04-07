import Automerge

public extension Document {
    /// Returns a Boolean value that indicates whether the latest contents another document are equivalent.
    func equivalentContents(_ anotherDoc: Document) -> Bool {
        do {
            let doc1Contents = try self.parseToSchema(self, from: .ROOT)
            let doc2Contents = try anotherDoc.parseToSchema(anotherDoc, from: .ROOT)
            return doc1Contents == doc2Contents
        } catch {
            return false
        }
    }
}
