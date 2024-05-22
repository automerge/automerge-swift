uniffi::include_scaffolding!("automerge");

mod actor_id;
use actor_id::ActorId;
mod cursor;
use cursor::Cursor;
mod change;
use change::Change;
mod change_hash;
use change_hash::ChangeHash;
mod doc;
use doc::{Doc, DocError, KeyValue, LoadError, ReceiveSyncError};
mod mark;
use mark::{ExpandMark, Mark};
mod obj_id;
use obj_id::{root, ObjId};
mod obj_type;
use obj_type::ObjType;
mod patches;
use patches::{Patch, PatchAction};
mod path;
use path::{PathElement, Prop};
mod scalar_value;
use scalar_value::ScalarValue;
mod sync_state;
use sync_state::{DecodeSyncStateError, SyncState};
mod value;
use value::Value;
mod span;
use span::{AMValue, Span, MapValue, TextValue};
