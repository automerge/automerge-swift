use crate::Mark;
use crate::ScalarValue;
use std::collections::HashMap;
// use automerge as am;

// ?? not entirely clear on how to expose MarkSet - nothing in the existing API exposes
// a map-like type through uniFFI - it's all been enums, lists, and structs so far.
// in am, MarkSet uses BTreeMap, which is a standard collection type, indexed with smolStr

pub struct SpanThing {
    pub parents: Vec<String>, // as Vec<AMValue> to convert through hydrate?
    pub r#type: String,
    pub attr: HashMap<String, AMValue>, // as MapValue
}
// maps to am::iter::Span

pub enum Span {
    /// A span of text and the marks that were active for that span
    Text(TextValue),
    /// A block marker
    Block(MapValue),
}

// maps to am::hydrate::Value
pub enum AMValue {
    Scalar { value: ScalarValue },
    Map { value: MapValue },
    List { value: Vec<AMValue> },
    Text { value: TextValue },
}

// maps to am::hydrate::Map
pub struct MapValue {
    pub value: HashMap<String, AMValue>,
}
// maps to am::hydrate::Text
pub struct TextValue {
    pub value: String,
    pub marks: Vec<Mark>,
}
