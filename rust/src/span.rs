use crate::ScalarValue;
use std::collections::HashMap;
// use automerge as am;

// maps to am::iter::Span
// need to create From<> in to convert over
pub enum Span {
    /// A span of text and the marks that were active for that span
    Text {
        text: String,
        marks: Option<MarkSet>,
    },
    /// A block marker
    Block { value: HashMap<String, AMValue> },
}

// loosely maps to am::marks:MarkSet
// need to create From<> in to convert over
pub struct MarkSet {
    pub marks: HashMap<String, ScalarValue>,
}

pub enum AMValue {
    Map { value: HashMap<String, AMValue> },
    Scalar { value: ScalarValue },
    List { value: Vec<HydratedList> },
    Text { value: HydratedText },
}

// loosely maps to am::hydrate::ListValue
// need to create From<> in to convert over
pub struct HydratedList {
    pub value: AMValue,
    pub marks: HashMap<String, ScalarValue>,
    pub conflict: bool,
}

// loosely maps to am::hydrate::Text
// need to create From<> in to convert over
pub struct HydratedText {
    pub value: String,
    pub marks: HashMap<String, ScalarValue>,
}
