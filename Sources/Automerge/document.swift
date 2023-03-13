import class AutomergeUniffi.Doc
import protocol AutomergeUniffi.DocProtocol
import Foundation

/// The entry point to automerge, a ``Document`` presents a key/value interface to
/// the data it contains; as well as methods for loading and saving documents, and
/// taking part in the sync protocol.
///
/// Typically there are four things you will want to do with a document:
///
/// - Read data using the various methods in the "Reading section"
/// - Inserting or modifying data using the methods in the "creating and modifying
///  values" section
/// - Reading historical data - i.e. data which has since changed - using the
///  the methods in the "Reading old values" section
/// - Interacting with concurrent documents (via the sync protocol or otherwise)
///  using the methods in "Saving, syncing, forking, and merging"
public class Document {
    private var doc: WrappedDoc

    /// The actor ID of this document
    public var actor: ActorId {
        get {
            ActorId(bytes: self.doc.wrapErrors { $0.actorId() })
        }
        set {
            self.doc.wrapErrors { $0.setActor(actor: newValue.bytes) }
        }
    }

    /// Create an new empty document with a random actor ID
    public init() {
        doc = WrappedDoc(Doc())
    }

    /// Load the document in `bytes`
    ///
    /// `bytes` can be either the result of calling ``save()`` or the
    /// concatenation of many calls to ``encodeChangesSince(heads:)``, or
    /// ``encodeNewChanges()`` or the concatenation of any of those, or really
    /// any sequence of bytes containing valid encodings of automerge changes.
    public init(_ bytes: Data) throws {
        doc = try WrappedDoc { try Doc.load(bytes: Array(bytes)) }
    }

    private init(doc: Doc) {
        self.doc = WrappedDoc(doc)
    }

    /// Set or update the  value at `key` in the map `obj` to `value`
    public func put(obj: ObjId, key: String, value: ScalarValue) throws {
        try self.doc.wrapErrors { try $0.putInMap(obj: obj.bytes, key: key, value: value.toFfi()) }
    }

    /// Set or update the value at `index` in the sequence `obj` to `value`
    public func put(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try self.doc.wrapErrors { try $0.putInList(obj: obj.bytes, index: index, value: value.toFfi()) }
    }

    /// Set or update `key` in map `obj` to a new instance of `ty`
    public func putObject(obj: ObjId, key: String, ty: ObjType) throws -> ObjId {
        try self.doc.wrapErrors {
            try ObjId(bytes: $0.putObjectInMap(obj: obj.bytes, key: key, objType: ty.toFfi()))
        }
    }

    /// Set or update `index` in list `obj` to a new instance of `ty`
    public func putObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try self.doc.wrapErrors {
            try ObjId(bytes: $0.putObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
        }
    }

    /// Insert `value` into the sequence `obj` at `index`
    public func insert(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try self.doc.wrapErrors {
            try $0.insertInList(obj: obj.bytes, index: index, value: value.toFfi())
        }
    }

    /// Insert a new instance of `ty` in the list `obj` at `index`
    public func insertObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try self.doc.wrapErrors {
            try ObjId(bytes: $0.insertObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
        }
    }

    /// Delete `key` from the map `obj`
    public func delete(obj: ObjId, key: String) throws {
        try self.doc.wrapErrors { try $0.deleteInMap(obj: obj.bytes, key: key) }
    }

    /// Delete the value at `index` from `obj`
    public func delete(obj: ObjId, index: UInt64) throws {
        try self.doc.wrapErrors { try $0.deleteInList(obj: obj.bytes, index: index) }
    }

    /// Increment the counter at `key` in map `obj` by the amount `by`
    public func increment(obj: ObjId, key: String, by: Int64) throws {
        try self.doc.wrapErrors { try $0.incrementInMap(obj: obj.bytes, key: key, by: by) }
    }

    /// Increment the counter at `index` in list `obj` by the amount `by`
    public func increment(obj: ObjId, index: UInt64, by: Int64) throws {
        try self.doc.wrapErrors { try $0.incrementInList(obj: obj.bytes, index: index, by: by) }
    }

    /// Get the value at `key` from the map `obj`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAll(obj:key:)``
    public func get(obj: ObjId, key: String) throws -> Value? {
        let val = try self.doc.wrapErrors { try $0.getInMap(obj: obj.bytes, key: key) }
        return val.map(Value.fromFfi)
    }

    /// Get the value at `index` from the list `obj`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAll(obj:index:)``
    public func get(obj: ObjId, index: UInt64) throws -> Value? {
        let val = try self.doc.wrapErrors { try $0.getInList(obj: obj.bytes, index: index) }
        return val.map(Value.fromFfi)
    }

    /// Get all the possibly conflicting values at `key` in the map `obj`
    public func getAll(obj: ObjId, key: String) throws -> Set<Value> {
        let vals = try self.doc.wrapErrors { try $0.getAllInMap(obj: obj.bytes, key: key) }
        return Set(vals.map { Value.fromFfi(value: $0) })
    }

    /// Get all the possibly conflicting values at `index` in the list `obj`
    public func getAll(obj: ObjId, index: UInt64) throws -> Set<Value> {
        let vals = try self.doc.wrapErrors { try $0.getAllInList(obj: obj.bytes, index: index) }
        return Set(vals.map { Value.fromFfi(value: $0) })
    }

    /// Get the value at `key` in map `obj` as at `heads`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAllAt(obj:key:heads:)``
    public func getAt<Heads: Collection<ChangeHash>>(obj: ObjId, key: String, heads: Heads) throws
        -> Value?
    {
        let val = try self.doc.wrapErrors {
            try $0.getAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
        }
        return val.map(Value.fromFfi)
    }

    /// Get the value at `index` in list `obj` as at `heads`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAllAt(obj:index:heads:)``
    public func getAt<Heads: Collection<ChangeHash>>(obj: ObjId, index: UInt64, heads: Heads) throws
        -> Value?
    {
        let val = try self.doc.wrapErrors {
            try $0.getAtInList(obj: obj.bytes, index: index, heads: heads.map(\.bytes))
        }
        return val.map(Value.fromFfi)
    }

    /// Get all the possibly conflicting values for `key` in map `obj` as at `heads`
    public func getAllAt<Heads: Collection<ChangeHash>>(obj: ObjId, key: String, heads: Heads) throws
        -> Set<Value>
    {
        let vals = try self.doc.wrapErrors {
            try $0.getAllAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
        }
        return Set(vals.map { Value.fromFfi(value: $0) })
    }

    /// Get all the possibly conflicting values for `index` in list `obj` as at `heads`
    public func getAllAt<Heads: Collection<ChangeHash>>(obj: ObjId, index: UInt64, heads: Heads)
        throws -> Set<Value>
    {
        let vals = try self.doc.wrapErrors {
            try $0.getAllAtInList(obj: obj.bytes, index: index, heads: heads.map(\.bytes))
        }
        return Set(vals.map { Value.fromFfi(value: $0) })
    }

    /// Get all the keys in the map `obj`
    public func keys(obj: ObjId) -> [String] {
        self.doc.wrapErrors { $0.mapKeys(obj: obj.bytes) }
    }

    /// Get all the keys that were in the map `obj` as at `heads`
    public func keysAt<Heads: Collection<ChangeHash>>(obj: ObjId, heads: Heads) -> [String] {
        self.doc.wrapErrors { $0.mapKeysAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
    }

    /// Get all the values in the map or list `obj`
    ///
    /// For a list this just returns the contents of the list, for a map this
    /// returns the values (and not the keys).
    public func values(obj: ObjId) throws -> [Value] {
        let vals = try self.doc.wrapErrors { try $0.values(obj: obj.bytes) }
        return vals.map { Value.fromFfi(value: $0) }
    }

    /// Get the values in the map or list `obj` as at `heads`
    public func valuesAt<Heads: Collection<ChangeHash>>(obj: ObjId, heads: Heads) throws -> [Value] {
        let vals = try self.doc.wrapErrors {
            try $0.valuesAt(obj: obj.bytes, heads: heads.map(\.bytes))
        }
        return vals.map { Value.fromFfi(value: $0) }
    }

    /// Get the (key,value) entries in the map `obj`
    public func mapEntries(obj: ObjId) throws -> [(String, Value)] {
        let entries = try self.doc.wrapErrors { try $0.mapEntries(obj: obj.bytes) }
        return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
    }

    /// Get the (key,value) entries in the map `obj` as at `heads`
    public func mapEntriesAt<Heads: Collection<ChangeHash>>(obj: ObjId, heads: Heads) throws -> [(
        String, Value
    )] {
        let entries = try self.doc.wrapErrors {
            try $0.mapEntriesAt(obj: obj.bytes, heads: heads.map(\.bytes))
        }
        return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
    }

    /// The length of the list `obj`
    public func length(obj: ObjId) -> UInt64 {
        self.doc.wrapErrors { $0.length(obj: obj.bytes) }
    }

    /// The length of the list `obj` as at `heads`
    public func lengthAt<Heads: Collection<ChangeHash>>(obj: ObjId, heads: Heads) -> UInt64 {
        self.doc.wrapErrors { $0.lengthAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
    }

    /// Get the value of the text object `obj`
    public func text(obj: ObjId) throws -> String {
        try self.doc.wrapErrors { try $0.text(obj: obj.bytes) }
    }

    /// Get the value of the text object `obj` as at `heads`
    public func textAt<Heads: Collection<ChangeHash>>(obj: ObjId, heads: Heads) throws -> String {
        try self.doc.wrapErrors { try $0.textAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
    }

    /// Splice into the list `obj`
    ///
    /// - Parameters:
    ///   - obj: The list to insert into
    ///   - start: the index to begin inserting at
    ///   - delete: the number of elements to delete
    ///   - values: the values to insert
    public func splice(obj: ObjId, start: UInt64, delete: UInt64, values: [ScalarValue]) throws {
        try self.doc.wrapErrors {
            try $0.splice(
                obj: obj.bytes, start: start, delete: delete, values: values.map { $0.toFfi() }
            )
        }
    }

    /// Splice into the list `obj`
    ///
    /// - Parameters:
    ///   - obj: The list to insert into
    ///   - start: the index to begin inserting at IN UNICODE CODE POINTS
    ///   - delete: the number of elements to delete IN UNICODE CODE POINTS
    ///   - values: the characters to insert
    ///
    /// # Indexes
    /// Swift string indexes represent graphaeme clusters, but automerge works
    /// in terms of UTF-8 code points. The indices to this method are utf-8
    /// code point indices. This means if you receive indices from other parts
    /// of the application which are swift string indices you will need to
    /// convert them.
    public func spliceText(obj: ObjId, start: UInt64, delete: UInt64, value: String? = nil) throws {
        try self.doc.wrapErrors {
            try $0.spliceText(obj: obj.bytes, start: start, delete: delete, chars: value ?? "")
        }
    }

    /// Encode this document in a compressed binary format
    public func save() -> Data {
        self.doc.wrapErrors { Data($0.save()) }
    }

    /// Generate a sync message to send to the peer represented by `state`
    ///
    /// - Returns: A message to send to the peer, or `nil` if we are in sync
    public func generateSyncMessage(state: SyncState) -> Data? {
        self.doc.wrapErrors {
            if let tempArr = $0.generateSyncMessage(state: state.ffi_state) {
                return Data(tempArr)
            }
            return nil
        }
    }

    /// Receive a sync message from the peer represented by `state`
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the message try using ``receiveSyncMessageWithPatches(state:message:)``
    public func receiveSyncMessage(state: SyncState, message: Data) throws {
        try self.doc.wrapErrors {
            try $0.receiveSyncMessage(state: state.ffi_state, msg: Array(message))
        }
    }

    /// Receive a sync message from the peer represented by `state`, returning patches
    ///
    /// Returns: a sequence of ``Patch`` representing the changes which were
    /// made to the document as a result of the message.
    public func receiveSyncMessageWithPatches(state: SyncState, message: Data) throws -> [Patch] {
        let patches = try self.doc.wrapErrors {
            try $0.receiveSyncMessageWithPatches(state: state.ffi_state, msg: Array(message))
        }
        return patches.map { Patch($0) }
    }

    /// Fork the document
    ///
    /// Returns: A copy of the document with a new actor ID, ready for concurrent
    /// use
    public func fork() -> Document {
        Document(doc: self.doc.wrapErrors { $0.fork() })
    }

    /// Fork the document as at `heads`
    ///
    /// Fork the document but such that it only contains changes up to `heads`
    public func forkAt<Heads: Collection<ChangeHash>>(heads: Heads) throws -> Document {
        try self.doc.wrapErrors { try Document(doc: $0.forkAt(heads: heads.map(\.bytes))) }
    }

    /// Merge this document with `other`
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the merge try using ``mergeWithPatches(other:)``
    public func merge(other: Document) throws {
        try self.doc.wrapErrorsWithOther(other: other.doc) { try $0.merge(other: $1) }
    }

    /// Merge this document with other returning patches
    public func mergeWithPatches(other: Document) throws -> [Patch] {
        let patches = try self.doc.wrapErrorsWithOther(other: other.doc) {
            try $0.mergeWithPatches(other: $1)
        }
        return patches.map { Patch($0) }
    }

    /// Returns: a sequence of ``ChangeHash`` representing the changes which were
    /// made to the document as a result of the merge
    public func heads() -> Set<ChangeHash> {
        Set(self.doc.wrapErrors { $0.heads().map { ChangeHash(bytes: $0) } })
    }

    /// Get the path to `obj` in the document
    public func path(obj: ObjId) throws -> [PathElement] {
        let elems = try self.doc.wrapErrors { try $0.path(obj: obj.bytes) }
        return elems.map { PathElement.fromFfi($0) }
    }

    /// Encode any changes since the last call to `encodeNewChanges`
    ///
    /// Returns: encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``
    public func encodeNewChanges() -> Data {
        self.doc.wrapErrors { Data($0.encodeNewChanges()) }
    }

    /// Encode any changes made since `heads`
    ///
    /// Returns: encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``
    public func encodeChangesSince<Heads: Collection<ChangeHash>>(heads: Heads) throws -> Data {
        try self.doc.wrapErrors { try Data($0.encodeChangesSince(heads: heads.map(\.bytes))) }
    }

    /// Apply encoded changes to this document
    ///
    /// The input to this function can be anything returned by ``save()``,
    /// ``encodeNewChanges()``, ``encodeChangesSince(heads:)`` or any
    /// concatenation of those.
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the applied changes try using ``applyEncodedChangesWithPatches(encoded:)``
    public func applyEncodedChanges(encoded: Data) throws {
        try self.doc.wrapErrors { try $0.applyEncodedChanges(changes: Array(encoded)) }
    }

    /// Apply encoded changes to this document
    ///
    /// The input to this function can be anything returned by ``save()``,
    /// ``encodeNewChanges()``, ``encodeChangesSince(heads:)`` or any
    /// concatenation of those.
    public func applyEncodedChangesWithPatches(encoded: Data) throws -> [Patch] {
        let patches = try self.doc.wrapErrors {
            try $0.applyEncodedChangesWithPatches(changes: Array(encoded))
        }
        return patches.map { Patch($0) }
    }
}

/// A wrapper to force all throwing calls to return wrapped errors
///
/// Any throwing call from `Doc` could return errors from AutomergeUniffi
/// which we don't want to expose as part of our public API. This wrapper
/// forces any throwing call to go through a closure which converts the error.
struct WrappedDoc {
    private let doc: Doc

    init(_ doc: Doc) {
        self.doc = doc
    }

    init(_ f: () throws -> Doc) throws {
        self.doc = try wrappedErrors { try f() }
    }

    func wrapErrors<T>(f: (Doc) throws -> T) throws -> T {
        try wrappedErrors { try f(self.doc) }
    }

    func wrapErrors<T>(f: (Doc) -> T) -> T {
        f(self.doc)
    }

    func wrapErrorsWithOther<T>(other: Self, f: (Doc, Doc) throws -> T) throws -> T {
        try wrappedErrors { try f(self.doc, other.doc) }
    }
}
