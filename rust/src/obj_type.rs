use automerge as am;

#[derive(Copy, Clone)]
pub enum ObjType {
    Map,
    List,
    Text,
}

impl From<ObjType> for am::ObjType {
    fn from(value: ObjType) -> Self {
        match value {
            ObjType::Map => am::ObjType::Map,
            ObjType::List => am::ObjType::List,
            ObjType::Text => am::ObjType::Text,
        }
    }
}

impl From<am::ObjType> for ObjType {
    fn from(value: am::ObjType) -> Self {
        match value {
            am::ObjType::Map | am::ObjType::Table => ObjType::Map,
            am::ObjType::List => ObjType::List,
            am::ObjType::Text => ObjType::Text,
        }
    }
}
