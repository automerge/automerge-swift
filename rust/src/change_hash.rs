use super::UniffiCustomTypeConverter;
use automerge as am;

pub struct ChangeHash(Vec<u8>);

impl From<ChangeHash> for am::ChangeHash {
    fn from(value: ChangeHash) -> Self {
        let inner: [u8; 32] = value.0.try_into().unwrap();
        am::ChangeHash(inner)
    }
}

impl From<am::ChangeHash> for ChangeHash {
    fn from(value: am::ChangeHash) -> Self {
        Self(value.0.to_vec())
    }
}

impl<'a> From<&'a am::ChangeHash> for ChangeHash {
    fn from(value: &'a am::ChangeHash) -> Self {
        Self(value.0.to_vec())
    }
}

impl UniffiCustomTypeConverter for ChangeHash {
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
