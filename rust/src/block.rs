use automerge as am;

use crate::Value;

pub struct Block2 {
    pub name: String,
    pub parents: Vec<String>,
}

impl<'a> From<&'a am::block::Block<'a>> for Block2 {
    fn from(am_block: &'a am::block::Block<'a>) -> Block2 {
        Block2 {
            name: am_block.name.to_string(),
            parents: am_block.parents,
        }
    }
}
