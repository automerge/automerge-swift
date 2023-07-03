import enum AutomergeUniffi.ExpandMark
import struct AutomergeUniffi.Mark

typealias FfiMark = AutomergeUniffi.Mark
typealias FfiExpandMark = AutomergeUniffi.ExpandMark

/// A type that represents a marked range of text.
///
/// Marks are annotations to text, which can be used to identify additional formatting, or other indicators relevant to
/// the text at a specific location.
/// The are identified by a string `name` and have an associated ``ScalarValue``.
public struct Mark: Equatable, Hashable, Sendable {
    /// The utf-8 codepoint index of the start of the mark
    public let start: UInt64
    /// The utf-8 codepoint index of the end of the mark
    public let end: UInt64
    /// The name of the mark
    public let name: String
    /// The value associated with the mark
    public let value: Value

    public init(start: UInt64, end: UInt64, name: String, value: Value) {
        self.start = start
        self.end = end
        self.name = name
        self.value = value
    }

    static func fromFfi(_ ffiMark: FfiMark) -> Self {
        Self(start: ffiMark.start, end: ffiMark.end, name: ffiMark.name, value: Value.fromFfi(value: ffiMark.value))
    }
}

/// A type that indicates how a mark should expand when adding characters at the ends of the mark.
///
/// Typically there are two different kinds of mark: "bold" type marks, where
/// adding text at the ends of the mark is expected to expand the mark to
/// include the added text, and "link" type marks, where the marked text is _not_
/// expected to expand when adding new characters.
///
/// For more information on marks and how they expand,
/// see the [The Peritext Essay](https://www.inkandswitch.com/peritext/).
public enum ExpandMark {
    /// Characters added just before the mark should be inside the mark.
    case before
    /// Characters added just after the mark should be inside the mark.
    case after
    /// Characters added just before or just after the mark should be inside the mark.
    case both
    /// Characters added just before or just after the mark should never be added to it.
    case none

    static func fromFfi(_ ffiExp: FfiExpandMark) -> Self {
        switch ffiExp {
        case .before:
            return ExpandMark.before
        case .after:
            return ExpandMark.after
        case .both:
            return ExpandMark.both
        case .none:
            return ExpandMark.none
        }
    }

    internal func toFfi() -> FfiExpandMark {
        switch self {
        case .before:
            return FfiExpandMark.before
        case .after:
            return FfiExpandMark.after
        case .both:
            return FfiExpandMark.both
        case .none:
            return FfiExpandMark.none
        }
    }
}
