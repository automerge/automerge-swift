use super::UniffiCustomTypeConverter;
use automerge as am;

#[derive(Debug, Clone)]
pub struct ObjId(Vec<u8>);

impl From<ObjId> for automerge::ObjId {
    fn from(value: ObjId) -> Self {
        // There is no way to construct ObjId except in this library, where we always construct it
        // from a valid object ID byte array am::ObjId::try_from(&value.0[..]).unwrap()
        am::ObjId::try_from(value.0.as_slice()).unwrap()
    }
}

// automerge only uses an ObjId's actor index as a hint for finding the actor, and looks the actor
// up when the hint is wrong.
const NO_ACTOR_INDEX_HINT: usize = 0;

impl From<am::ObjId> for ObjId {
    fn from(value: am::ObjId) -> Self {
        // An object's ID is its counter and actor. automerge also carries the actor's index in the
        // document, but its `PartialEq` and `Hash` ignore it, and a merge can change it. Swift
        // compares and hashes the bytes, so they mustn't include it, or the same object can get
        // two unequal IDs.
        let id = match value {
            am::ObjId::Root => am::ObjId::Root,
            am::ObjId::Id(counter, actor, _) => am::ObjId::Id(counter, actor, NO_ACTOR_INDEX_HINT),
        };
        ObjId(id.to_bytes())
    }
}

pub fn root() -> ObjId {
    am::ROOT.into()
}

impl UniffiCustomTypeConverter for ObjId {
    type Builtin = Vec<u8>;

    fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
    where
        Self: Sized,
    {
        Ok(Self(val))
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        obj.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use am::transaction::Transactable;
    use am::{ActorId, AutoCommit, ReadDoc};

    #[test]
    fn ids_of_the_same_object_have_the_same_bytes_after_a_merge_moves_its_actor() {
        // The fork's actor sorts first, so merging it moves the document's actor from index 0 to 1.
        let mut doc = AutoCommit::new().with_actor(ActorId::from([0xFF; 16]));
        let text = doc.put_object(am::ROOT, "text", am::ObjType::Text).unwrap();
        let mut fork = doc.fork().with_actor(ActorId::from([0x00; 16]));
        fork.splice_text(&text, 0, 0, "hello").unwrap();
        doc.merge(&mut fork).unwrap();
        let (_, text_after_merge) = doc.get(am::ROOT, "text").unwrap().unwrap();

        assert_ne!(text.to_bytes(), text_after_merge.to_bytes());
        assert_eq!(ObjId::from(text.clone()).0, ObjId::from(text_after_merge).0);

        // The bytes still find the object, although its actor is no longer at index 0.
        let id = am::ObjId::from(ObjId::from(text));
        assert_eq!(doc.text(&id).unwrap(), "hello");
        assert_eq!(fork.text(&id).unwrap(), "hello");
    }

    #[test]
    fn root_bytes_are_unchanged() {
        assert_eq!(ObjId::from(am::ROOT).0, am::ROOT.to_bytes());
    }
}
