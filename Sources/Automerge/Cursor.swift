import enum AutomergeUniffi.Position

typealias FfiPosition = AutomergeUniffi.Position

/// A opaque type that represents a stable location of the character following the location reference at creation within an array or text object that adjusts with insertions and deletions to
/// maintain its relative position.
///
/// Create a cursor using ``Document/cursor(obj:position:)``, or ``Document/cursor(obj:position:heads:)`` to place a
/// cursor at the point in time indicated by the `heads` parameter.
/// Retrieve the position of the cursor reference from the document using ``Document/position(obj:cursor:)``, or use
/// ``Document/position(obj:cursor:heads:)`` to get the position at a previous point in time.
public struct Cursor: Equatable, Hashable, Sendable {
    var bytes: [UInt8]
}

extension Cursor: CustomStringConvertible {
    /// The bytes that describe the cursor.
    public var description: String {
        bytes.map { Swift.String(format: "%02hhx", $0) }.joined().uppercased()
    }
}

/// An umbrella type that represents a location within an array or text object.
///
/// ### See Also
/// - ``Document/cursor(obj:position:)``
/// - ``Document/cursor(obj:position:heads:)``
public enum Position {
    case cursor(Cursor)
    case index(UInt64)
}

extension Position {
    func toFfi() -> FfiPosition {
        switch self {
        case let .cursor(cursor):
            return .cursor(position: cursor.bytes)
        case let .index(index):
            return .index(position: index)
        }
    }
}
