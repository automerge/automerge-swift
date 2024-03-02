use automerge as am;

use crate::{ActorId, ChangeHash};

pub struct Change {
    pub actor_id: ActorId,
    pub message: Option<String>,
    pub deps: Vec<ChangeHash>,
    pub timestamp: i64,
    pub bytes: Vec<u8>,
    pub hash: ChangeHash,
}

impl From<am::Change> for Change {
    fn from(mut value: am::Change) -> Self {
        Change {
            actor_id: value.actor_id().into(),
            message: value.message().cloned(),
            deps: value.deps().into_iter().map(ChangeHash::from).collect(),
            timestamp: value.timestamp(),
            bytes: value.bytes().into_owned(),
            hash: value.hash().into(),
        }
    }
}

impl From<Change> for am::Change {
    fn from(value: Change) -> Self {
        am::Change::try_from(value.bytes.as_slice()).unwrap()
    }
}

#[derive(Debug, thiserror::Error)]
pub enum DecodeChangeError {
    #[error(transparent)]
    Internal(#[from] am::LoadChangeError),
}

pub fn decode_change(bytes: Vec<u8>) -> Result<Change, DecodeChangeError> {
    am::Change::try_from(bytes.as_slice())
        .map(Change::from)
        .map_err(DecodeChangeError::from)
}

pub fn valid_change(bytes: Vec<u8>) -> bool {
    let x = decode_change(bytes);
    return x.is_ok();
}