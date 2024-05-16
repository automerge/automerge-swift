use crate::ScalarValue;
use std::collections::HashMap;
use std::sync::Arc;
// use automerge as am;

// ?? not entirely clear on how to expose MarkSet - nothing in the existing API exposes
// a map-like type through uniFFI - it's all been enums, lists, and structs so far.
// in am, MarkSet uses BTreeMap, which is a standard collection type, indexed with smolStr
// pub struct BlockLikeThing {
//     pub parents: Vec<String>, // as Vec<AMValue> to convert through hydrate?
//     pub r#type: String,
//     pub attr: HashMap<String, AMValue>, // as MapValue
// }

// maps to am::iter::Span
// need to create From<> in to convert over
pub enum Span {
    /// A span of text and the marks that were active for that span
    Text {
        text: String,
        marks: Option<MarkSet>,
    },
    /// A block marker
    Block { value: MapValue },
}

// loosely maps to am::marks:MarkSet
// need to create From<> in to convert over
pub struct MarkSet {
    pub marks: HashMap<String, ScalarValue>,
}

// loosely maps to am::hydrate::Value
// need to create From<> in to convert over
pub enum AMValueType {
    Scalar,
    Map,
    List,
    Text,
}

// Joe's hacky version of Swift's "Indirect enum" setup - where it's always
// a reference type. The UniFFI UDL doesn't appear to allow us to model that,
// so I've backed in to implementing each instance of this 'generic tree' enumeration
// setup as an Object through the UDL interface (this translates to a Class instance in
// Swift)
//
// https://mozilla.github.io/uniffi-rs/udl/interfaces.html
// The UniFFI FFI interface expects that to be in the form of Arc<Something> due to
// its use of proxy objects.
// Details on how UniFFI manages it's object references at
// https://mozilla.github.io/uniffi-rs/internals/object_references.html
//
// Enums in Rust are concrete, there doesn't appear to be a direct
// mapping to what is (in Swift) an indirect enum where the data associated with
// an enum case is a reference to some other type, dependent upon the case.
// I previously tried to set this general object structure up as a tree of enums, but I
// hit multiple limits within the UDL representation:
// - because enums are concrete, you can't have a self-referential enum (Rust compiler fails
// that as an "infinite enum").
// - I tried to break that infinite struct up by adding a reference type,
// but a reference counted instance isn't allowed inside the UDL enum structure (by Ref not supported).
// - I tried making List (to be an object holding a Vec<List>) that I could use by reference,
// but then learned that Object types also aren't supported in Enum.
//
// Based on that, I think AMValue may need to be represented as an object, and the manually handling
// the type of value by an Enum that _is_ concrete, but any assocaited data something external
// to that enum that the object manages - since we've got a set of 4 possible values here,
// maybe 4 optional types, pushing the work to know what's returned to the developer? There may be
// other idiomatic patterns that could be used, but I'm not spotting what else might be possible
// right now, at least through the lens of what's allowed by the UDL.

pub struct AMValue {
    kind: AMValueType,
    scalar_value: Option<ScalarValue>,
    map_value: Option<MapValue>,
    list_value: Option<Vec<ListValue>>,
    text_value: Option<TextValue>,
}

impl AMValue {
    pub fn new(input: ScalarValue) -> Self {
        AMValue {
            kind: AMValueType::Scalar,
            scalar_value: Some(input),
            map_value: None,
            list_value: None,
            text_value: None,
        }
    }

    pub fn new_from_map(input: MapValue) -> Self {
        AMValue {
            kind: AMValueType::Map,
            scalar_value: None,
            map_value: Some(input),
            list_value: None,
            text_value: None,
        }
    }
}

// made an explicit type of this so that it could be referenced
// in Span as the internal data for a Block.
pub struct MapValue {
    pub value: HashMap<String, ScalarValue>,
}

// loosely maps to am::hydrate::ListValue
// need to create From<> in to convert over
pub struct ListValue {
    pub value: Arc<AMValue>,
    pub marks: HashMap<String, ScalarValue>,
    pub conflict: bool,
}

// loosely maps to am::hydrate::Text
// need to create From<> in to convert over
pub struct TextValue {
    pub value: String,
    pub marks: HashMap<String, ScalarValue>,
}
