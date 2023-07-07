use std::sync::RwLock;

use automerge as am;

use crate::ChangeHash;

#[derive(Debug, thiserror::Error)]
pub enum DecodeSyncStateError {
    #[error(transparent)]
    Internal(#[from] am::sync::DecodeStateError),
}

pub struct SyncState(pub(crate) RwLock<am::sync::State>);

impl SyncState {
    pub fn new() -> Self {
        Self(RwLock::new(am::sync::State::new()))
    }

    pub fn decode(bytes: Vec<u8>) -> Result<Self, DecodeSyncStateError> {
        Ok(SyncState(RwLock::new(am::sync::State::decode(
            bytes.as_slice(),
        )?)))
    }

    pub fn encode(&self) -> Vec<u8> {
        self.0.read().unwrap().encode()
    }

    pub fn reset(&self) {
        let mut s = self.0.write().unwrap();
        let encoded = s.encode();
        let decoded = am::sync::State::decode(encoded.as_slice()).unwrap();
        *s = decoded
    }

    pub fn their_heads(&self) -> Option<Vec<ChangeHash>> {
        let sync = self.0.read().unwrap();
        sync.their_heads
            .as_ref()
            .map(|heads| heads.iter().map(ChangeHash::from).collect())
    }
}

impl Default for SyncState {
    fn default() -> Self {
        Self::new()
    }
}
