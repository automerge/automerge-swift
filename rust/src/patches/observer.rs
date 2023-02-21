use super::SequenceTree;
use automerge as am;
use automerge::ReadDoc;

#[derive(Debug, Clone, Default)]
pub(crate) struct Observer {
    enabled: bool,
    patches: Vec<Patch>,
}

impl Observer {
    pub(crate) fn take_patches(&mut self) -> Vec<super::Patch> {
        std::mem::take(&mut self.patches)
            .into_iter()
            .map(super::Patch::from)
            .collect()
    }

    pub(crate) fn enable(&mut self, enable: bool) -> bool {
        if self.enabled && !enable {
            self.patches.truncate(0)
        }
        let old_enabled = self.enabled;
        self.enabled = enable;
        old_enabled
    }

    fn get_path<R: ReadDoc>(
        &mut self,
        doc: &R,
        obj: &am::ObjId,
    ) -> Option<Vec<(am::ObjId, am::Prop)>> {
        match doc.parents(obj) {
            Ok(parents) => parents.visible_path(),
            Err(e) => {
                automerge::log!("error generating patch : {:?}", e);
                None
            }
        }
    }
}

#[derive(Debug, Clone)]
pub(crate) enum Patch {
    PutMap {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        key: String,
        value: (am::Value<'static>, am::ObjId),
    },
    PutSeq {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        index: usize,
        value: (am::Value<'static>, am::ObjId),
    },
    Insert {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        index: usize,
        values: SequenceTree<(am::Value<'static>, am::ObjId)>,
    },
    SpliceText {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        index: usize,
        value: SequenceTree<char>,
    },
    Increment {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        prop: am::Prop,
        value: i64,
    },
    DeleteMap {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        key: String,
    },
    DeleteSeq {
        obj: am::ObjId,
        path: Vec<(am::ObjId, am::Prop)>,
        index: usize,
        length: usize,
    },
}

impl am::OpObserver for Observer {
    fn insert<R: ReadDoc>(
        &mut self,
        doc: &R,
        obj: am::ObjId,
        index: usize,
        tagged_value: (am::Value<'_>, am::ObjId),
    ) {
        if self.enabled {
            let value = (tagged_value.0.to_owned(), tagged_value.1);
            if let Some(Patch::Insert {
                obj: tail_obj,
                index: tail_index,
                values,
                ..
            }) = self.patches.last_mut()
            {
                let range = *tail_index..=*tail_index + values.len();
                if tail_obj == &obj && range.contains(&index) {
                    values.insert(index - *tail_index, value);
                    return;
                }
            }
            if let Some(path) = self.get_path(doc, &obj) {
                let mut values = SequenceTree::new();
                values.push(value);
                let patch = Patch::Insert {
                    path,
                    obj,
                    index,
                    values,
                };
                self.patches.push(patch);
            }
        }
    }

    fn splice_text<R: ReadDoc>(&mut self, doc: &R, obj: am::ObjId, index: usize, value: &str) {
        if self.enabled {
            if let Some(Patch::SpliceText {
                obj: tail_obj,
                index: tail_index,
                value: prev_value,
                ..
            }) = self.patches.last_mut()
            {
                let range = *tail_index..=*tail_index + prev_value.len();
                if tail_obj == &obj && range.contains(&index) {
                    let i = index - *tail_index;
                    for (n, ch) in value.chars().enumerate() {
                        prev_value.insert(i + n, ch)
                    }
                    return;
                }
            }
            if let Some(path) = self.get_path(doc, &obj) {
                let mut v = SequenceTree::new();
                for ch in value.chars() {
                    v.push(ch)
                }
                let patch = Patch::SpliceText {
                    path,
                    obj,
                    index,
                    value: v,
                };
                self.patches.push(patch);
            }
        }
    }

    fn delete_seq<R: ReadDoc>(&mut self, doc: &R, obj: am::ObjId, index: usize, length: usize) {
        if self.enabled {
            match self.patches.last_mut() {
                Some(Patch::SpliceText {
                    obj: tail_obj,
                    index: tail_index,
                    value,
                    ..
                }) => {
                    let range = *tail_index..*tail_index + value.len();
                    if tail_obj == &obj
                        && range.contains(&index)
                        && range.contains(&(index + length - 1))
                    {
                        for _ in 0..length {
                            value.remove(index - *tail_index);
                        }
                        return;
                    }
                }
                Some(Patch::Insert {
                    obj: tail_obj,
                    index: tail_index,
                    values,
                    ..
                }) => {
                    let range = *tail_index..*tail_index + values.len();
                    if tail_obj == &obj
                        && range.contains(&index)
                        && range.contains(&(index + length - 1))
                    {
                        for _ in 0..length {
                            values.remove(index - *tail_index);
                        }
                        return;
                    }
                }
                Some(Patch::DeleteSeq {
                    obj: tail_obj,
                    index: tail_index,
                    length: tail_length,
                    ..
                }) => {
                    if tail_obj == &obj && index == *tail_index {
                        *tail_length += length;
                        return;
                    }
                }
                _ => {}
            }
            if let Some(path) = self.get_path(doc, &obj) {
                let patch = Patch::DeleteSeq {
                    path,
                    obj,
                    index,
                    length,
                };
                self.patches.push(patch)
            }
        }
    }

    fn delete_map<R: ReadDoc>(&mut self, doc: &R, obj: am::ObjId, key: &str) {
        if self.enabled {
            if let Some(path) = self.get_path(doc, &obj) {
                let patch = Patch::DeleteMap {
                    path,
                    obj,
                    key: key.to_owned(),
                };
                self.patches.push(patch)
            }
        }
    }

    fn put<R: ReadDoc>(
        &mut self,
        doc: &R,
        obj: am::ObjId,
        prop: am::Prop,
        tagged_value: (am::Value<'_>, am::ObjId),
        _conflict: bool,
    ) {
        if self.enabled {
            if let Some(path) = self.get_path(doc, &obj) {
                let value = (tagged_value.0.to_owned(), tagged_value.1);
                let patch = match prop {
                    am::Prop::Map(key) => Patch::PutMap {
                        path,
                        obj,
                        key,
                        value,
                    },
                    am::Prop::Seq(index) => Patch::PutSeq {
                        path,
                        obj,
                        index,
                        value,
                    },
                };
                self.patches.push(patch);
            }
        }
    }

    fn expose<R: ReadDoc>(
        &mut self,
        doc: &R,
        obj: am::ObjId,
        prop: am::Prop,
        tagged_value: (am::Value<'_>, am::ObjId),
        _conflict: bool,
    ) {
        if self.enabled {
            if let Some(path) = self.get_path(doc, &obj) {
                let value = (tagged_value.0.to_owned(), tagged_value.1);
                let patch = match prop {
                    am::Prop::Map(key) => Patch::PutMap {
                        path,
                        obj,
                        key,
                        value,
                    },
                    am::Prop::Seq(index) => Patch::PutSeq {
                        path,
                        obj,
                        index,
                        value,
                    },
                };
                self.patches.push(patch);
            }
        }
    }

    fn increment<R: ReadDoc>(
        &mut self,
        doc: &R,
        obj: am::ObjId,
        prop: am::Prop,
        tagged_value: (i64, am::ObjId),
    ) {
        if self.enabled {
            if let Some(path) = self.get_path(doc, &obj) {
                let value = tagged_value.0;
                self.patches.push(Patch::Increment {
                    path,
                    obj,
                    prop,
                    value,
                })
            }
        }
    }

    fn text_as_seq(&self) -> bool {
        false
    }
}

impl automerge::op_observer::BranchableObserver for Observer {
    fn merge(&mut self, other: &Self) {
        self.patches.extend_from_slice(other.patches.as_slice())
    }

    fn branch(&self) -> Self {
        Observer {
            patches: vec![],
            enabled: self.enabled,
        }
    }
}
