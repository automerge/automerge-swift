use crate::ScalarValue;
use automerge as am;
use std::collections::HashMap;

// ?? not entirely clear on how to expose MarkSet - nothing in the existing API exposes
// a map-like type through uniFFI - it's all been enums, lists, and structs so far.
// in am, MarkSet uses BTreeMap, which is a standard collection type, indexed with smolStr

pub enum Span {
    /// A span of text and the marks that were active for that span
    Text(TextValue),
    /// A block marker
    Block(MapValue),
}

pub enum AMValue {
    Scalar(ScalarValue),
    Map(MapValue),
    List(Vec<AMValue>),
    Text(TextValue),
}

pub struct MapValue {
    value: HashMap<String, AMValue>
}
pub struct TextValue {
    value: String,
    marks: HashMap<String, ScalarValue>,
}
