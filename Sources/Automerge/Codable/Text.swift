import Foundation

/// A type that presents a string backed by a Sequential CRDT
public struct Text: Hashable, Codable {
    public var value: String

    // NOTE(heckj): The version Automerge after 2.0 is adding support for "marks"
    // that apply to runs of text within the .Text primitive. This should map
    // reasonably well to AttributedStrings. When it's merged, this type
    // should be a reasonable placeholder from which to derive `AttributedString` and
    // the flat `String` variations from the underlying data source in Automerge.

    /// Creates a new Text instance with the string value you provide.
    /// - Parameter value: The value for the text.
    public init(_ value: String) {
        self.value = value
    }
}

extension Text: CustomStringConvertible {
    public var description: String {
        value
    }
}
