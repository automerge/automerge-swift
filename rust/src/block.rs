use automerge as am;

pub struct Block {
    pub name: String,
    pub parents: Vec<String>,
}

impl<'a> From<&'a am::    ::block::Block<'a>> for Block {
    fn from(am_block: &'a am::block::Block<'a>) -> Block {
        Block {
            name: am_block.name.to_string(),
            parents: am_block.parents,
        }
    }
}
