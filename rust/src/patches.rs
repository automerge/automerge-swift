use std::collections::HashMap;

use automerge as am;

use crate::{
    mark::Mark,
    obj_id::ObjId,
    path::{PathElement, Prop},
    value::Value,
};

pub struct Patch {
    pub path: Vec<PathElement>,
    pub action: PatchAction,
}

impl From<am::Patch> for Patch {
    fn from(p: am::Patch) -> Self {
        let action = PatchAction::from_am(p.obj, p.action);
        Patch {
            path: convert_path(p.path),
            action,
        }
    }
}

pub enum PatchAction {
    Put {
        obj: ObjId,
        prop: Prop,
        value: Value,
    },
    Insert {
        obj: ObjId,
        index: u64,
        values: Vec<Value>,
    },
    SpliceText {
        obj: ObjId,
        index: u64,
        value: String,
        marks: HashMap<String, Value>,
    },
    JoinBlock {
        index: u64,
        // ? cursor
    },
    SplitBlock {
        index: u64,
        // ? cursor
    }, 
    UpdateBlock {
        //? patch
    },
    Increment {
        obj: ObjId,
        prop: Prop,
        value: i64,
    },
    Conflict {
        obj: ObjId,
        prop: Prop,
    },
    DeleteMap {
        obj: ObjId,
        key: String,
    },
    DeleteSeq {
        obj: ObjId,
        index: u64,
        length: u64,
    },
    Marks {
        obj: ObjId,
        marks: Vec<Mark>,
    },
}

impl PatchAction {
    fn from_am(obj: am::ObjId, am_action: am::PatchAction) -> PatchAction {
        match am_action {
            am::PatchAction::PutMap { key, value, .. } => PatchAction::Put {
                obj: obj.into(),
                prop: Prop::Key { value: key },
                value: value.into(),
            },
            am::PatchAction::PutSeq { index, value, .. } => PatchAction::Put {
                obj: obj.into(),
                prop: Prop::Index {
                    value: index as u64,
                },
                value: value.into(),
            },
            am::PatchAction::Insert {
                index,
                values,
            } => PatchAction::Insert {
                obj: obj.into(),
                index: index as u64,
                values: values
                    .into_iter()
                    .map(|(v, id, _conflict)| Value::from((v.clone(), id.clone())))
                    .collect(),
            },
            am::PatchAction::JoinBlock { 
                index, 
                cursor 
            } => PatchAction::JoinBlock {
                 index: index as u64 
            },
            am::PatchAction::SplitBlock {
                 index, 
                 cursor, 
                 conflict 
            } => PatchAction::SplitBlock {
                     index: index as u64
            },
            am::PatchAction::UpdateBlock {
                 patch 
            } => PatchAction::UpdateBlock {    

            },
            am::PatchAction::SpliceText {
                index,
                value,
                marks,
            } => PatchAction::SpliceText {
                obj: obj.into(),
                index: index as u64,
                value: value.make_string(),
                marks: convert_marks(marks),
            },
            am::PatchAction::Increment { prop, value } => PatchAction::Increment {
                obj: obj.into(),
                prop: prop.into(),
                value,
            },
            am::PatchAction::Conflict { prop } => PatchAction::Conflict {
                prop: prop.into(),
                obj: obj.into(),
            },
            am::PatchAction::DeleteMap { key } => PatchAction::DeleteMap {
                obj: obj.into(),
                key,
            },
            am::PatchAction::DeleteSeq { index, length } => PatchAction::DeleteSeq {
                obj: obj.into(),
                index: index as u64,
                length: length as u64,
            },
            am::PatchAction::Mark { marks } => PatchAction::Marks {
                obj: obj.into(),
                marks: marks.into_iter().map(|m| Mark::from(&m)).collect(),
            },
        }
    }
}

fn convert_marks(am_richtext: Option<am::marks::RichText>) -> HashMap<String, Value> {
    let mut result = HashMap::new();
    if let Some(richtext) = am_richtext {
        for (name, value) in richtext.iter_marks() {
            result.insert(
                name.to_string(),
                Value::Scalar {
                    value: value.into(),
                },
            );
        }
    }
    result
}

fn convert_path(p: Vec<(am::ObjId, am::Prop)>) -> Vec<PathElement> {
    p.into_iter()
        .map(|(obj, prop)| PathElement {
            obj: obj.into(),
            prop: prop.into(),
        })
        .collect()
}
