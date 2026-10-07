use std::collections::HashMap;

use automerge as am;

use crate::ScalarValue;

/// A value read from or written to a document as a whole tree, such as a block marker's contents.
///
/// Mirrors `automerge::hydrate::Value`. Text is carried as its string; marks within nested text are not
/// represented.
pub enum HydratedValue {
    Scalar {
        value: ScalarValue,
    },
    Map {
        value: HashMap<String, HydratedValue>,
    },
    List {
        value: Vec<HydratedValue>,
    },
    Text {
        value: String,
    },
}

/// A run of text with the marks active over it, or a block marker, from a text object.
///
/// Mirrors `automerge::iter::Span`.
pub enum Span {
    Text {
        text: String,
        marks: HashMap<String, ScalarValue>,
    },
    Block {
        value: HashMap<String, HydratedValue>,
    },
}

impl<'a> From<&'a am::hydrate::Value> for HydratedValue {
    fn from(value: &'a am::hydrate::Value) -> Self {
        match value {
            am::hydrate::Value::Scalar(s) => HydratedValue::Scalar { value: s.into() },
            am::hydrate::Value::Map(m) => HydratedValue::Map {
                value: hydrated_map(m),
            },
            am::hydrate::Value::List(l) => HydratedValue::List {
                value: l.iter().map(|item| (&item.value).into()).collect(),
            },
            am::hydrate::Value::Text(t) => HydratedValue::Text { value: t.into() },
        }
    }
}

pub(crate) fn hydrated_map(map: &am::hydrate::Map) -> HashMap<String, HydratedValue> {
    map.iter()
        .map(|(key, item)| (key.clone(), (&item.value).into()))
        .collect()
}

impl From<am::iter::Span> for Span {
    fn from(value: am::iter::Span) -> Self {
        match value {
            am::iter::Span::Text { text, marks } => Span::Text {
                text,
                marks: marks
                    .map(|marks| {
                        marks
                            .iter()
                            .map(|(name, value)| (name.to_string(), value.into()))
                            .collect()
                    })
                    .unwrap_or_default(),
            },
            am::iter::Span::Block(map) => Span::Block {
                value: hydrated_map(&map),
            },
        }
    }
}

impl HydratedValue {
    /// Converts to the core's value, creating any text with the document's encoding.
    pub(crate) fn into_hydrate(self, encoding: am::TextEncoding) -> am::hydrate::Value {
        match self {
            HydratedValue::Scalar { value } => am::hydrate::Value::Scalar(value.into()),
            HydratedValue::Map { value } => map_into_hydrate(value, encoding),
            HydratedValue::List { value } => am::hydrate::Value::List(
                value
                    .into_iter()
                    .map(|v| v.into_hydrate(encoding))
                    .collect::<Vec<_>>()
                    .into(),
            ),
            HydratedValue::Text { value } => {
                am::hydrate::Value::Text(am::hydrate::Text::new(encoding, value))
            }
        }
    }
}

pub(crate) fn map_into_hydrate(
    map: HashMap<String, HydratedValue>,
    encoding: am::TextEncoding,
) -> am::hydrate::Value {
    am::hydrate::Value::Map(
        map.into_iter()
            .map(|(key, value)| (key, value.into_hydrate(encoding)))
            .collect::<HashMap<_, _>>()
            .into(),
    )
}
