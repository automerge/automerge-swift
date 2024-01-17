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
    /// The distance from the start of the string in unicode scalars where the function starts the mark.
    public let start: UInt64
    /// The distance from the start of the string in unicode scalars where the function ends the mark.
    public let end: UInt64
    /// The name of the mark.
    public let name: String
    /// The value associated with the mark.
    public let value: Value

    /// Creates a new mark.
    ///
    /// - Parameters:
    ///   - start: The distance from the start of the string in unicode scalars where the function starts the mark.
    ///   - end: The distance from the start of the string in unicode scalars where the function ends the mark.
    ///   - name: The name of the mark.
    ///   - value: The value associated with the mark.
    ///
    /// If you use or receive a Swift `String.Index` convert it to an index position usable by Automerge through
    /// `UnicodeScalarView`, accessible through the `unicodeScalars` property on the string.
    /// To determine Automerge index position from a `String.Index`, convert the index position into a
    /// `String.UnicodeScalarView.Index` and calculate the distance from the `startIndex` value.
    ///
    /// An example of deriving the automerge start position from a Swift string's index:
    /// ```swift
    /// extension String {
    ///    @inlinable func automergeIndexPosition(index: String.Index) -> UInt64? {
    ///        guard let unicodeScalarIndex = index.samePosition(in: self.unicodeScalars) else {
    ///            return nil
    ///        }
    ///        let intPositionInUnicodeScalar = self.unicodeScalars.distance(
    ///            from: self.unicodeScalars.startIndex,
    ///            to: unicodeScalarIndex)
    ///        return UInt64(intPositionInUnicodeScalar)
    ///    }
    /// }
    /// ```
    ///
    /// For the length of index updates in Automerge, use the count of the string's `UnicodeScalarView`, converted to
    /// `Int64`.
    /// For example:
    /// ```swift
    /// Int64("🇬🇧".unicodeScalars.count)
    /// ```
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
public enum ExpandMark: Equatable, Hashable, Sendable {
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

    func toFfi() -> FfiExpandMark {
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
