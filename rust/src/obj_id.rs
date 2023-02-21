use super::UniffiCustomTypeConverter;
use automerge as am;

pub struct ObjId(Vec<u8>);

impl From<ObjId> for automerge::ObjId {
    fn from(value: ObjId) -> Self {
        // There is no way to construct ObjId except in this library, where we always construct it
        // from a valid object ID byte array am::ObjId::try_from(&value.0[..]).unwrap()
        am::ObjId::try_from(value.0.as_slice()).unwrap()
    }
}

impl From<am::ObjId> for ObjId {
    fn from(value: am::ObjId) -> Self {
        ObjId(value.to_bytes())
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
