use crate::ScalarValue;
use std::collections::HashMap;
use automerge as am;

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

// impl From<Span> for am::iter::Spans<'_> {
//     fn from(value: Span) -> Self {
//         let inner: [u8; 32] = value.0.try_into().unwrap();
//         am::ChangeHash(inner)
//     }
// }

impl<'a> From<&'a am::iter::Span> for Span {
    fn from(value: &'a am::iter::Span) -> Self {
        match value {
            am::iter::Span::Text( t, m) => Self::Text { text: t.to_string(), marks: Option<Arc<am::marks::MarkSet>>::from() },
            am::iter::Span::Block( value ) => Self::Block { value: HashMap<String, AMValue>::from(value) }
        }
    }
}

impl<'a> From<&'a am::hydrate::Map> for HashMap<String, AMValue> {
    fn from(value: &'a am::hydrate::Map) -> Self {
        let mut new_hash_map:HashMap<String, AMValue> = HashMap::new();
        // fill in the middle bits...
        return new_hash_map;
    }
}

// loosely maps to am::marks:MarkSet
// need to create From<> in to convert over
pub struct MarkSet {
    pub marks: HashMap<String, ScalarValue>,
}

impl<'a> From<&'a am::marks::MarkSet> for MarkSet {
    fn from(value: &'a am::marks::MarkSet) -> Self {
        let mut new_hash:HashMap<String, ScalarValue> = HashMap::new();
        // iterate through MarkSet, building a hashmap for this MarkSet 
        for (k, v) in value.iter() {
            new_hash.insert(k.to_string(), v.into());
        }
        Self { marks: new_hash }
    }
}

pub enum AMValue {
    Map { value: HashMap<String, AMValue> },
    Scalar { value: ScalarValue },
    List { value: Vec<HydratedListItem> },
    Text { value: HydratedText },
}

// loosely maps to am::hydrate::ListValue
// need to create From<> in to convert over
pub struct HydratedListItem {
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
