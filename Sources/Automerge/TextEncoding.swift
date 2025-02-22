import enum AutomergeUniffi.TextEncoding
import Foundation

/// An enumeration representing different types of text encoding.
///
/// Text encodings determine how text is processed across Automerge APIs.
public enum TextEncoding {
    /// Text encoding using Grapheme Cluster.
    /// Grapheme clusters represent user-perceived characters, which may consist of multiple Unicode scalars.
    /// For example:
    /// - "é" (a Latin small letter "e" followed by a combining acute accent) is a single grapheme cluster.
    /// - Emoji with modifiers, like "👨‍👩‍👧‍👦" (family emoji), are grapheme clusters combining multiple scalars.
    case graphemeCluster

    /// Text encoding using Unicode scalar values.
    /// Unicode scalars are the fundamental building blocks of Unicode text, but they are not directly stored as-is.
    /// Instead, they are encoded into binary formats like UTF-8 or UTF-16 for persistence.
    case unicodeScalar

    /// Text encoding using UTF-8.
    /// A variable-width encoding representing characters in 1–4 bytes.
    case utf8

    /// Text encoding using UTF-16.
    /// A variable-width encoding using one or two 16-bit code units.
    case utf16
}

// MARK: - Adapters
typealias FfiTextEncoding = AutomergeUniffi.TextEncoding

extension FfiTextEncoding {
    var textEncoding: TextEncoding {
        switch self {
        case .graphemeCluster: return .graphemeCluster
        case .unicodeCodePoint: return .unicodeScalar
        case .utf16CodeUnit: return .utf16
        case .utf8CodeUnit: return .utf8
        }
    }
}

extension TextEncoding {
    var ffi_textEncoding: FfiTextEncoding {
        switch self {
        case .graphemeCluster: return .graphemeCluster
        case .unicodeScalar: return .unicodeCodePoint
        case .utf16: return .utf16CodeUnit
        case .utf8: return .utf8CodeUnit
        }
    }
}
