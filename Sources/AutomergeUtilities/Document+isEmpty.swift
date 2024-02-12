import Automerge

public extension Document {
    /// Returns a Boolean value that indicates whether the document is empty.
    func isEmpty() throws -> Bool {
        let x = try mapEntries(obj: .ROOT)
        return x.count < 1
    }
}
