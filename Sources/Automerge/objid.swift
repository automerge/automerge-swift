import AutomergeUniffi

public struct ObjId: Equatable, Hashable {
    internal var bytes: [UInt8]
    public static let ROOT = ObjId(bytes: AutomergeUniffi.root())
}
