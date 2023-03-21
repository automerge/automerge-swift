import AutomergeUniffi

/// The unique internal identifier for an object stored in an Automerge document.
public struct ObjId: Equatable, Hashable {
    internal var bytes: [UInt8]
    /// The root identifier for an Automerge document.
    public static let ROOT = ObjId(bytes: AutomergeUniffi.root())
}
