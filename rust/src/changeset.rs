//use super::UniffiCustomTypeConverter;
use automerge as am;
use am::Change;

pub struct ChangeSet(Vec<Change>);


#[derive(Debug, thiserror::Error)]
pub enum DecodeChangeSetError {
    #[error(transparent)]
    Internal(#[from] am::LoadChangeError),
}

impl ChangeSet {
    pub fn new() -> Self {
        Self(Vec::new())
    }

    pub fn decode(bytes: Vec<u8>) -> Result<Self, DecodeChangeSetError> {
        // let ac = automerge::AutoCommit::load(bytes.as_slice())?;
        // Ok(Doc(RwLock::new(ac)))
        let result_vector: Vec<Change> = Vec::new();

        // example of Parsing a change from bytes:
        let _change = am::Change::try_from(bytes.as_slice())
            .map(Change::from)
            .map_err(DecodeChangeSetError::from);
    
        let x = ChangeSet(result_vector);
        return Ok(x);    

    // storage is 'private' - code replicated from load_incremental_log_patches in Autocommit.rs
    // let changes = match am::storage::load::load_changes(storage::parse::Input::new(data)) {
    //     load::LoadedChanges::Complete(c) => c,
    //     load::LoadedChanges::Partial { error, loaded, .. } => {
    //         tracing::warn!(successful_chunks=loaded.len(), err=?error, "partial load");
    //         loaded
    //     }
    // };

    }
}

impl Default for ChangeSet {
    fn default() -> Self {
        Self::new()
    }
}

// The following methods are for converting types from the Automerge module
// impl From<Cursor> for am::Cursor {
//     fn from(value: Cursor) -> Self {
//         am::Cursor::try_from(value.0).unwrap()
//     }
// }

// impl From<am::Cursor> for Cursor {
//     fn from(value: am::Cursor) -> Self {
//         Cursor(value.to_bytes())
//     }
// }

// impl UniffiCustomTypeConverter for Cursor {
//     type Builtin = Vec<u8>;

//     fn into_custom(val: Self::Builtin) -> uniffi::Result<Self>
//     where
//         Self: Sized,
//     {
//         Ok(Self(val))
//     }

//     fn from_custom(obj: Self) -> Self::Builtin {
//         obj.0
//     }
// }
