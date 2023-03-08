import AutomergeUniffi

public struct ChangeHash: Equatable, Hashable, CustomDebugStringConvertible {
    internal var bytes: [UInt8]

    public var debugDescription: String {
        bytes.map { String(format: "%02hhx", $0) }.joined()
    }
}
