import Foundation

/// A opaque type that represents a location within an array or text object that adjusts with insertions and deletes to
/// maintain its relative position.
///
/// Set a cursor using ``Document/cursor(obj:position:)``, or ``Document/cursorAt(obj:position:heads:)`` to place a
/// cursor at a previous point in time.
/// Retrieve the cursor position from the document using ``Document/cursorPosition(obj:cursor:)``, or use
/// ``Document/cursorPositionAt(obj:cursor:heads:)`` to get the cursor position at a previous point in time.
public struct Cursor: Equatable, Hashable, Sendable {
    var bytes: [UInt8]
}

extension Cursor: CustomStringConvertible {
    /// The bytes that describe the cursor.
    public var description: String {
        bytes.map { Swift.String(format: "%02hhx", $0) }.joined().uppercased()
    }
}
