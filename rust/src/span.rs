use automerge as am;
use std::sync::Arc;

use crate::mark
// ?? not entirely clear on how to expose MarkSet - nothing in the existing API exposes
// a map-like type through uniFFI - it's all been enums, lists, and structs so far.
// in am, MarkSet uses BTreeMap, which is a standard collection type, indexed with smolStr


pub enum Span {
    /// A span of text and the marks that were active for that span
    Text(String, Option<Arc<MarkSet>>),
    /// A block marker
    Block(am::hydrate::Map)
}

