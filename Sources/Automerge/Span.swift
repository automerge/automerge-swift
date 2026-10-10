import enum AutomergeUniffi.Span

typealias FfiSpan = AutomergeUniffi.Span

/// A run of text with the marks that apply to it, or a block marker, read from a text object.
///
/// Rich text in Automerge divides a text object into blocks with block markers, and formats ranges of characters
/// with marks. Reading a text object as spans returns its contents in order: each block marker as a ``block(_:)``
/// span, and the text between them as ``text(_:marks:)`` spans, split wherever the marks that apply change.
///
/// A block marker counts as one position in the text object, and reads as the object replacement character
/// (`U+FFFC`) from ``Document/text(obj:)``.
/// By convention, shared with Automerge's JavaScript library, a block marker holds a `type` string, a `parents`
/// list of strings, and an `attrs` map.
public enum Span: Equatable, Hashable, Sendable {
    /// A run of text, and the marks that apply to all of it, by name.
    case text(String, marks: [String: ScalarValue])
    /// A block marker, and its contents.
    case block([String: AutomergeValue])

    static func fromFfi(_ span: FfiSpan) -> Self {
        switch span {
        case let .text(text, marks):
            return .text(text, marks: marks.mapValues { ScalarValue.fromFfi(value: $0) })
        case let .block(value):
            return .block(value.mapValues(AutomergeValue.fromFfi))
        }
    }
}
