use automerge as am;

use crate::{ObjId, ObjType, ScalarValue};

pub enum Value {
    Object { typ: ObjType, id: ObjId },
    Scalar { value: ScalarValue },
}

impl<'a> From<(am::Value<'a>, am::ObjId)> for Value {
    fn from(value: (am::Value<'a>, am::ObjId)) -> Self {
        match value {
            (am::Value::Object(ty), id) => Value::Object {
                typ: ObjType::from(ty),
                id: id.into(),
            },
            (am::Value::Scalar(s), _) => Value::Scalar {
                value: s.as_ref().into(),
            },
        }
    }
}
