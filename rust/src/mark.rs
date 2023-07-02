use automerge as am;

use crate::Value;

pub enum ExpandMark {
    Before,
    After,
    None,
    Both,
}

impl From<ExpandMark> for am::marks::ExpandMark {
    fn from(value: ExpandMark) -> Self {
        match value {
            ExpandMark::Before => am::marks::ExpandMark::Before,
            ExpandMark::After => am::marks::ExpandMark::After,
            ExpandMark::None => am::marks::ExpandMark::None,
            ExpandMark::Both => am::marks::ExpandMark::Both,
        }
    }
}

pub struct Mark {
    pub start: u64,
    pub end: u64,
    pub name: String,
    pub value: Value,
}

impl<'a> From<&'a am::marks::Mark<'a>> for Mark {
    fn from(am_mark: &'a am::marks::Mark<'a>) -> Mark {
        Mark {
            start: am_mark.start as u64,
            end: am_mark.end as u64,
            name: am_mark.name().to_string(),
            value: Value::Scalar {
                value: am_mark.value().into(),
            },
        }
    }
}
