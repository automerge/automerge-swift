use std::sync::{Arc, RwLock, RwLockWriteGuard};

use am::sync::SyncDoc;
use automerge as am;
use automerge::{transaction::Transactable, ReadDoc};

use crate::actor_id::ActorId;
use crate::cursor::Position;
use crate::mark::{ExpandMark, KeyValue, Mark};
use crate::patches::Patch;
use crate::text_encoding::TextEncoding;

use crate::{
    Change, ChangeHash, Cursor, ObjId, ObjType, PathElement, ScalarValue, SyncState, Value,
};

#[derive(Debug, thiserror::Error)]
pub enum DocError {
    #[error("WrongObjectType")]
    WrongObjectType,
    #[error("Internal error: {0}")]
    Internal(#[from] automerge::AutomergeError),
}

#[derive(Debug, thiserror::Error)]
pub enum LoadError {
    #[error(transparent)]
    Internal(#[from] automerge::AutomergeError),
}

#[derive(Debug, thiserror::Error)]
pub enum ReceiveSyncError {
    #[error(transparent)]
    Internal(#[from] am::AutomergeError),
    #[error("Invalid message")]
    InvalidMessage,
}

pub struct Doc(RwLock<automerge::AutoCommit>);

// These are okay because on the swift side we wrap all accesses of the
// document to ensure they are only accessed from a single thread
unsafe impl Send for Doc {}
unsafe impl Sync for Doc {}

impl Doc {
    pub(crate) fn new() -> Self {
        Self(RwLock::new(automerge::AutoCommit::default()))
    }

    pub(crate) fn new_with_actor(actor: ActorId) -> Self {
        Self(RwLock::new(
            am::AutoCommit::default().with_actor(actor.into()),
        ))
    }

    pub fn new_with_text_encoding(text_encoding: TextEncoding) -> Self {
        Self(RwLock::new(am::AutoCommit::new_with_encoding(
            text_encoding.into(),
        )))
    }

    pub fn text_encoding(&self) -> TextEncoding {
        self.0.read().unwrap().text_encoding().into()
    }

    pub fn actor_id(&self) -> ActorId {
        self.0.read().unwrap().get_actor().into()
    }

    pub fn set_actor(&self, actor: ActorId) {
        self.0.write().unwrap().set_actor(actor.into());
    }

    pub fn put_in_map(&self, obj: ObjId, key: String, value: ScalarValue) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_map(&*doc, &obj)?;
        doc.put(obj, key, value).map_err(|e| e.into())
    }

    pub fn put_object_in_map(
        &self,
        obj: ObjId,
        key: String,
        value: ObjType,
    ) -> Result<ObjId, DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_map(&*doc, &obj)?;
        let obj = doc.put_object(obj, key, value.into())?;
        Ok(obj.into())
    }

    pub fn put_in_list(&self, obj: ObjId, index: u64, value: ScalarValue) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        doc.put(obj, index as usize, value).map_err(|e| e.into())
    }

    pub fn put_object_in_list(
        &self,
        obj: ObjId,
        index: u64,
        value: ObjType,
    ) -> Result<ObjId, DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        let obj = doc.put_object(obj, index as usize, value.into())?;
        Ok(obj.into())
    }

    pub fn insert_in_list(
        &self,
        obj: ObjId,
        index: u64,
        value: ScalarValue,
    ) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        doc.insert(obj, index as usize, value).map_err(|e| e.into())
    }

    pub fn insert_object_in_list(
        &self,
        obj: ObjId,
        index: u64,
        value: ObjType,
    ) -> Result<ObjId, DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        let obj = doc.insert_object(obj, index as usize, value.into())?;
        Ok(obj.into())
    }

    pub fn delete_in_map(&self, obj: ObjId, key: String) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_map(&*doc, &obj)?;
        Ok(doc.delete(&obj, key)?)
    }

    pub fn delete_in_list(&self, obj: ObjId, index: u64) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        Ok(doc.delete(&obj, index as usize)?)
    }

    pub fn increment_in_map(&self, obj: ObjId, key: String, by: i64) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_map(&*doc, &obj)?;
        Ok(doc.increment(&obj, key, by)?)
    }

    pub fn increment_in_list(&self, obj: ObjId, index: u64, by: i64) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        Ok(doc.increment(&obj, index as usize, by)?)
    }

    pub fn get_in_map(&self, obj: ObjId, key: String) -> Result<Option<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_map(&*doc, &obj)?;
        Ok(doc.get(obj, key)?.map(|v| v.into()))
    }

    pub fn get_in_list(&self, obj: ObjId, idx: u64) -> Result<Option<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_list(&*doc, &obj)?;
        Ok(doc.get(obj, idx as usize)?.map(|v| v.into()))
    }

    pub fn get_at_in_map(
        &self,
        obj: ObjId,
        key: String,
        heads: Vec<ChangeHash>,
    ) -> Result<Option<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads.into_iter().map(|h| h.into()).collect::<Vec<_>>();
        assert_map(&*doc, &obj)?;
        Ok(doc.get_at(obj, key, &heads)?.map(|v| v.into()))
    }

    pub fn get_at_in_list(
        &self,
        obj: ObjId,
        idx: u64,
        heads: Vec<ChangeHash>,
    ) -> Result<Option<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads.into_iter().map(|h| h.into()).collect::<Vec<_>>();
        assert_list(&*doc, &obj)?;
        Ok(doc.get_at(obj, idx as usize, &heads)?.map(|v| v.into()))
    }

    pub fn get_all_in_map(&self, obj: ObjId, key: String) -> Result<Vec<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_map(&*doc, &obj)?;
        let vals = doc.get_all(&obj, key)?;
        Ok(vals
            .into_iter()
            .map(|(v, id)| Value::from((v, id)))
            .collect::<Vec<_>>())
    }

    pub fn get_all_in_list(&self, obj: ObjId, index: u64) -> Result<Vec<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_list(&*doc, &obj)?;
        let vals = doc.get_all(&obj, index as usize)?;
        Ok(vals
            .into_iter()
            .map(|(v, id)| Value::from((v, id)))
            .collect::<Vec<_>>())
    }

    pub fn get_all_at_in_map(
        &self,
        obj: ObjId,
        key: String,
        heads: Vec<ChangeHash>,
    ) -> Result<Vec<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        assert_map(&*doc, &obj)?;
        let vals = doc.get_all_at(&obj, key, heads.as_slice())?;
        Ok(vals.into_iter().map(Value::from).collect::<Vec<_>>())
    }

    pub fn get_all_at_in_list(
        &self,
        obj: ObjId,
        index: u64,
        heads: Vec<ChangeHash>,
    ) -> Result<Vec<Value>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        assert_list(&*doc, &obj)?;
        let vals = doc.get_all_at(&obj, index as usize, heads.as_slice())?;
        Ok(vals.into_iter().map(Value::from).collect::<Vec<_>>())
    }

    pub fn map_keys(&self, obj: ObjId) -> Vec<String> {
        self.0.read().unwrap().keys(am::ObjId::from(obj)).collect()
    }

    pub fn map_keys_at(&self, obj: ObjId, heads: Vec<ChangeHash>) -> Vec<String> {
        let obj = am::ObjId::from(obj);
        let heads = heads.into_iter().map(|h| h.into()).collect::<Vec<_>>();
        self.0.read().unwrap().keys_at(&obj, &heads).collect()
    }

    pub fn map_entries(&self, obj: ObjId) -> Result<Vec<KeyValue>, DocError> {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        assert_map(&*doc, &obj)?;
        Ok(doc
            .map_range(&obj, ..)
            .map(|am::iter::MapRangeItem { key, value, id, .. }| KeyValue {
                key: key.into(),
                value: (value, id).into(),
            })
            .collect::<Vec<_>>())
    }

    pub fn map_entries_at(
        &self,
        obj: ObjId,
        heads: Vec<ChangeHash>,
    ) -> Result<Vec<KeyValue>, DocError> {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        let heads = heads.into_iter().map(|h| h.into()).collect::<Vec<_>>();
        assert_map(&*doc, &obj)?;
        Ok(doc
            .map_range_at(&obj, .., &heads)
            .map(|am::iter::MapRangeItem { key, value, id, .. }| KeyValue {
                key: key.into(),
                value: (value, id).into(),
            })
            .collect::<Vec<_>>())
    }

    pub fn values(&self, obj: ObjId) -> Result<Vec<Value>, DocError> {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        Ok(doc.values(&obj).map(Value::from).collect::<Vec<_>>())
    }

    pub fn values_at(&self, obj: ObjId, heads: Vec<ChangeHash>) -> Result<Vec<Value>, DocError> {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        Ok(doc
            .values_at(&obj, &heads)
            .map(Value::from)
            .collect::<Vec<_>>())
    }

    pub fn length(&self, obj: ObjId) -> u64 {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        doc.length(obj) as u64
    }

    pub fn length_at(&self, obj: ObjId, heads: Vec<ChangeHash>) -> u64 {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        doc.length_at(obj, &heads) as u64
    }

    pub fn object_type(&self, obj: ObjId) -> ObjType {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        doc.object_type(obj).unwrap().into()
    }

    pub fn cursor(&self, obj: ObjId, position: u64) -> Result<Cursor, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        Ok(doc.get_cursor(obj, position as usize, None)?.into())
    }

    pub fn cursor_at(
        &self,
        obj: ObjId,
        position: u64,
        heads: Vec<ChangeHash>,
    ) -> Result<Cursor, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        Ok(doc.get_cursor(obj, position as usize, Some(&heads))?.into())
    }

    pub fn cursor_position(&self, obj: ObjId, cursor: Cursor) -> Result<u64, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        doc.get_cursor_position(obj, &cursor.into(), None)
            .map(|cursor| cursor as u64)
            .map_err(|error| DocError::Internal(error))
    }

    pub fn cursor_position_at(
        &self,
        obj: ObjId,
        cursor: Cursor,
        heads: Vec<ChangeHash>,
    ) -> Result<u64, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        doc.get_cursor_position(obj, &cursor.into(), Some(&heads))
            .map(|cursor| cursor as u64)
            .map_err(|error| DocError::Internal(error))
    }

    pub fn text(&self, obj: ObjId) -> Result<String, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_text(&*doc, &obj)?;
        Ok(doc.text(obj)?)
    }

    pub fn text_at(&self, obj: ObjId, heads: Vec<ChangeHash>) -> Result<String, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_text(&*doc, &obj)?;
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        Ok(doc.text_at(obj, &heads)?)
    }

    pub fn splice_text(
        &self,
        obj: ObjId,
        start: u64,
        delete: i64,
        value: String,
    ) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_text(&*doc, &obj)?;
        doc.splice_text(&obj, start as usize, delete as isize, value.as_str())?;
        Ok(())
    }

    pub fn update_text(&self, obj: ObjId, value: String) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_text(&*doc, &obj)?;
        doc.update_text(&obj, value)?;
        Ok(())
    }

    pub fn splice(
        &self,
        obj: ObjId,
        start: u64,
        delete: i64,
        values: Vec<ScalarValue>,
    ) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_list(&*doc, &obj)?;
        doc.splice(
            &obj,
            start as usize,
            delete as isize,
            values.into_iter().map(|i| i.into()),
        )?;
        Ok(())
    }

    pub fn mark(
        &self,
        obj: ObjId,
        start: u64,
        end: u64,
        expand: ExpandMark,
        name: String,
        value: ScalarValue,
    ) -> Result<(), DocError> {
        let obj = am::ObjId::from(obj);
        let mut doc = self.0.write().unwrap();
        assert_text(&*doc, &obj)?;
        let mark = am::marks::Mark::new(name, value, start as usize, end as usize);
        doc.mark(obj, mark, expand.into())?;
        Ok(())
    }

    pub fn marks(&self, obj: ObjId) -> Result<Vec<Mark>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.write().unwrap();
        assert_text(&*doc, &obj)?;
        Ok(doc
            .marks(obj)?
            .into_iter()
            .map(|m| Mark::from(&m))
            .collect())
    }

    pub fn marks_at(&self, obj: ObjId, heads: Vec<ChangeHash>) -> Result<Vec<Mark>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.write().unwrap();
        assert_text(&*doc, &obj)?;
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        Ok(doc
            .marks_at(obj, &heads)?
            .into_iter()
            .map(|m| Mark::from(&m))
            .collect())
    }

    pub fn marks_at_position(
        &self,
        obj: ObjId,
        position: Position,
        heads: Vec<ChangeHash>,
    ) -> Result<Vec<Mark>, DocError> {
        let obj = am::ObjId::from(obj);
        let doc = self.0.read().unwrap();
        assert_text(&*doc, &obj)?;
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        let index = match position {
            Position::Cursor { position: cursor } => doc
                .get_cursor_position(obj.clone(), &cursor.into(), Some(&heads))
                .unwrap() as usize,
            Position::Index { position: index } => index as usize,
        };
        let markset = doc.get_marks(obj, index, Some(&heads)).unwrap();
        Ok(Mark::from_markset(markset, index as u64))
    }

    pub fn split_block(&self, obj: ObjId, index: u32) -> Result<ObjId, DocError> {
        let mut doc = self.0.write().unwrap();
        let obj = am::ObjId::from(obj);
        let id = doc.split_block(obj, index.try_into().unwrap())?;
        Ok(id.into())
    }

    pub fn join_block(&self, obj: ObjId, index: u32) -> Result<(), DocError> {
        let mut doc = self.0.write().unwrap();
        let obj = am::ObjId::from(obj);
        doc.join_block(obj, index.try_into().unwrap())?;
        Ok(())
    }

    pub fn merge(&self, other: Arc<Self>) -> Result<(), DocError> {
        let mut doc = self.0.write().unwrap();
        let mut other = other.0.write().unwrap();
        doc.merge(&mut other)?;
        Ok(())
    }

    pub fn merge_with_patches(&self, other: Arc<Self>) -> Result<Vec<Patch>, DocError> {
        let doc = self.0.write().unwrap();
        let mut other = other.0.write().unwrap();
        Self::do_with_patches(doc, move |doc| {
            doc.merge(&mut other)?;
            Ok(())
        })
    }

    pub fn commit_with(&self, message: Option<String>, time: i64) {
        let mut doc = self.0.write().unwrap();
        let mut options = automerge::transaction::CommitOptions::default();
        options.set_time(time);
        if let Some(message) = message {
            options.set_message(message);
        }
        doc.commit_with(options);
    }

    pub fn save(&self) -> Vec<u8> {
        let mut doc = self.0.write().unwrap();
        doc.save()
    }

    pub fn load(bytes: Vec<u8>) -> Result<Self, LoadError> {
        let ac = automerge::AutoCommit::load(bytes.as_slice())?;
        Ok(Doc(RwLock::new(ac)))
    }

    pub fn generate_sync_message(&self, sync_state: Arc<SyncState>) -> Option<Vec<u8>> {
        let mut doc = self.0.write().unwrap();
        let mut state = sync_state.0.write().unwrap();
        let sync = doc.sync();
        sync.generate_sync_message(&mut state)
            .map(|msg| msg.encode())
    }

    pub fn receive_sync_message(
        &self,
        sync_state: Arc<SyncState>,
        message: Vec<u8>,
    ) -> Result<(), ReceiveSyncError> {
        let message =
            am::sync::Message::decode(&message).map_err(|_| ReceiveSyncError::InvalidMessage)?;
        let mut doc = self.0.write().unwrap();
        let mut state = sync_state.0.write().unwrap();
        doc.sync().receive_sync_message(&mut state, message)?;
        Ok(())
    }

    pub fn receive_sync_message_with_patches(
        &self,
        sync_state: Arc<SyncState>,
        message: Vec<u8>,
    ) -> Result<Vec<Patch>, ReceiveSyncError> {
        let message =
            am::sync::Message::decode(&message).map_err(|_| ReceiveSyncError::InvalidMessage)?;
        let doc = self.0.write().unwrap();
        let mut state = sync_state.0.write().unwrap();
        Self::do_with_patches(doc, move |doc| {
            doc.sync().receive_sync_message(&mut state, message)?;
            Ok(())
        })
    }

    pub fn fork(&self) -> Arc<Self> {
        let mut doc = self.0.write().unwrap();
        Arc::new(Self(RwLock::new(doc.fork())))
    }

    pub fn fork_at(&self, heads: Vec<ChangeHash>) -> Result<Arc<Self>, DocError> {
        let mut doc = self.0.write().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        let new = doc.fork_at(&heads)?;
        Ok(Arc::new(Self(RwLock::new(new))))
    }

    pub fn heads(&self) -> Vec<ChangeHash> {
        self.0
            .write()
            .unwrap()
            .get_heads()
            .into_iter()
            .map(|h| h.into())
            .collect()
    }

    pub fn changes(&self) -> Vec<ChangeHash> {
        let empty_heads: Vec<am::ChangeHash> = Vec::new();
        let mut doc = self.0.write().unwrap();
        let changes = doc.get_changes(&empty_heads);
        changes.into_iter().map(|h| h.hash().into()).collect()
    }

    pub fn difference(&self, before: Vec<ChangeHash>, after: Vec<ChangeHash>) -> Vec<Patch> {
        let lhs = before
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        let rhs = after
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        let mut doc = self.0.write().unwrap();
        let patches = doc.diff(&lhs, &rhs);
        patches.into_iter().map(Patch::from).collect()
    }

    pub fn change_by_hash(&self, hash: ChangeHash) -> Option<Change> {
        let doc = self.0.write().unwrap();
        doc.get_change_by_hash(&am::ChangeHash::from(hash))
            .map(|m| Change::from(m.clone()))
    }

    pub fn path(&self, obj: ObjId) -> Result<Vec<PathElement>, DocError> {
        let doc = self.0.read().unwrap();
        let obj = am::ObjId::from(obj);
        let path = doc.parents(obj)?.path();
        Ok(path
            .into_iter()
            .map(|(id, prop)| PathElement::new(prop, id))
            .collect::<Vec<_>>())
    }

    pub fn encode_new_changes(&self) -> Vec<u8> {
        let mut doc = self.0.write().unwrap();
        doc.save_incremental()
    }

    pub fn encode_changes_since(&self, heads: Vec<ChangeHash>) -> Result<Vec<u8>, DocError> {
        let mut doc = self.0.write().unwrap();
        let heads = heads
            .into_iter()
            .map(am::ChangeHash::from)
            .collect::<Vec<_>>();
        let changes = doc.get_changes(&heads);
        let mut result = Vec::new();
        for change in changes {
            result.extend(change.clone().bytes().as_ref());
        }
        Ok(result)
    }

    pub fn apply_encoded_changes(&self, changes: Vec<u8>) -> Result<(), DocError> {
        let mut doc = self.0.write().unwrap();
        doc.reset_diff_cursor();
        doc.load_incremental(&changes)?;
        Ok(())
    }

    pub fn apply_encoded_changes_with_patches(
        &self,
        changes: Vec<u8>,
    ) -> Result<Vec<Patch>, DocError> {
        let doc = self.0.write().unwrap();
        Self::do_with_patches(doc, move |doc| {
            doc.load_incremental(changes.as_slice())?;
            Ok(())
        })
    }

    fn do_with_patches<F, E>(
        mut doc: RwLockWriteGuard<am::AutoCommit>,
        f: F,
    ) -> Result<Vec<Patch>, E>
    where
        F: FnOnce(&mut RwLockWriteGuard<am::AutoCommit>) -> Result<(), E>,
    {
        // Note no early return so we get a chance to pop the patches
        doc.update_diff_cursor();
        let result = f(&mut doc);
        let am_patches = doc.diff_incremental();
        result?;
        let patches = am_patches.into_iter().map(|p| p.into()).collect();
        Ok(patches)
    }
}

fn assert_map<R: am::ReadDoc>(doc: &R, obj: &am::ObjId) -> Result<(), DocError> {
    match doc.object_type(obj)? {
        am::ObjType::Map | am::ObjType::Table => Ok(()),
        _ => Err(DocError::WrongObjectType),
    }
}

fn assert_list<R: am::ReadDoc>(doc: &R, obj: &am::ObjId) -> Result<(), DocError> {
    match doc.object_type(obj)? {
        am::ObjType::List => Ok(()),
        _ => Err(DocError::WrongObjectType),
    }
}

fn assert_text<R: am::ReadDoc>(doc: &R, obj: &am::ObjId) -> Result<(), DocError> {
    match doc.object_type(obj)? {
        am::ObjType::Text => Ok(()),
        _ => Err(DocError::WrongObjectType),
    }
}
