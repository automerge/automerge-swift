use automerge as am;

use super::ObjId;

pub enum Prop {
    Key { value: String },
    Index { value: u64 },
}

impl From<am::Prop> for Prop {
    fn from(value: am::Prop) -> Self {
        match value {
            am::Prop::Map(k) => Prop::Key { value: k },
            am::Prop::Seq(i) => Prop::Index { value: i as u64 },
        }
    }
}

impl From<Prop> for am::Prop {
    fn from(value: Prop) -> Self {
        match value {
            Prop::Key { value } => am::Prop::Map(value),
            Prop::Index { value } => am::Prop::Seq(value as usize),
        }
    }
}

pub struct PathElement {
    pub prop: Prop,
    pub obj: ObjId,
}

impl PathElement {
    pub fn new<P: Into<Prop>, O: Into<ObjId>>(prop: P, obj: O) -> Self {
        Self {
            obj: obj.into(),
            prop: prop.into(),
        }
    }
}
