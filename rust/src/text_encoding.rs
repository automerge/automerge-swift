use automerge as am;

#[derive(Debug, PartialEq, Clone, Copy)]
pub enum TextEncoding {
    UnicodeCodePoint,
    Utf8CodeUnit,
    Utf16CodeUnit,
    GraphemeCluster,
}

impl From<TextEncoding> for am::TextEncoding {
    fn from(value: TextEncoding) -> Self {
        match value {
            TextEncoding::UnicodeCodePoint => am::TextEncoding::UnicodeCodePoint,
            TextEncoding::Utf8CodeUnit => am::TextEncoding::Utf8CodeUnit,
            TextEncoding::Utf16CodeUnit => am::TextEncoding::Utf16CodeUnit,
            TextEncoding::GraphemeCluster => am::TextEncoding::GraphemeCluster,
        }
    }
}

impl From<am::TextEncoding> for TextEncoding {
    fn from(value: am::TextEncoding) -> Self {
        match value {
            am::TextEncoding::UnicodeCodePoint => TextEncoding::UnicodeCodePoint,
            am::TextEncoding::Utf8CodeUnit => TextEncoding::Utf8CodeUnit,
            am::TextEncoding::Utf16CodeUnit => TextEncoding::Utf16CodeUnit,
            am::TextEncoding::GraphemeCluster => TextEncoding::GraphemeCluster,
        }
    }
}

impl std::fmt::Display for TextEncoding {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnicodeCodePoint => write!(f, "Unicode Scalar"),
            Self::Utf8CodeUnit => write!(f, "UTF-8"),
            Self::Utf16CodeUnit => write!(f, "UTF-16"),
            Self::GraphemeCluster => write!(f, "Grapheme Cluster"),
        }
    }
}
