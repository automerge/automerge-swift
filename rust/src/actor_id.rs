use automerge as am;

use super::UniffiCustomTypeConverter;

pub struct ActorId(Vec<u8>);

impl From<ActorId> for automerge::ActorId {
    fn from(value: ActorId) -> Self {
        am::ActorId::from(value.0)
    }
}

impl<'a> From<&'a am::ActorId> for ActorId {
    fn from(value: &'a am::ActorId) -> Self {
        ActorId(value.to_bytes().to_vec())
    }
}

impl UniffiCustomTypeConverter for ActorId {
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
