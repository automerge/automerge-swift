use super::UniffiCustomTypeConverter;
use automerge as am;

pub struct Cursor(Vec<u8>);

impl From<Cursor> for am::Cursor {
    fn from(value: Cursor) -> Self {
        am::Cursor::try_from(value.0).unwrap()
    }
}

impl From<am::Cursor> for Cursor {
    fn from(value: am::Cursor) -> Self {
        Cursor(value.to_bytes())
    }
}

impl UniffiCustomTypeConverter for Cursor {
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

