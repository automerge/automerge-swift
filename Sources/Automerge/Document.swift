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
public class Document: @unchecked Sendable {
    private var doc: WrappedDoc
    fileprivate let queue = DispatchQueue(label: "automerge-sync-queue", qos: .userInteractive)
    var reportingLogLevel: LogVerbosity

    /// The actor ID of this document
    public var actor: ActorId {
        get {
            queue.sync {
                ActorId(bytes: self.doc.wrapErrors { $0.actorId() })
            }
        }
        set {
            queue.sync {
                self.doc.wrapErrors { $0.setActor(actor: newValue.bytes) }
            }
        }
    }

    /// Create an new empty document with a random actor ID
    public init(logLevel: LogVerbosity = .errorOnly) {
        doc = WrappedDoc(Doc())
        self.reportingLogLevel = logLevel
    }

    /// Load the document in `bytes`
    ///
    /// `bytes` can be either the result of calling ``save()`` or the
    /// concatenation of many calls to ``encodeChangesSince(heads:)``, or
    /// ``encodeNewChanges()`` or the concatenation of any of those, or really
    /// any sequence of bytes containing valid encodings of automerge changes.
    public init(_ bytes: Data, logLevel: LogVerbosity = .errorOnly) throws {
        doc = try WrappedDoc { try Doc.load(bytes: Array(bytes)) }
        self.reportingLogLevel = logLevel
    }

    private init(doc: Doc, logLevel: LogVerbosity = .errorOnly) {
        self.doc = WrappedDoc(doc)
        self.reportingLogLevel = logLevel
    }

    /// Set or update the  value at `key` in the map `obj` to `value`
    public func put(obj: ObjId, key: String, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.putInMap(obj: obj.bytes, key: key, value: value.toFfi()) }
        }
    }

    /// Set or update the value at `index` in the sequence `obj` to `value`
    public func put(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.putInList(obj: obj.bytes, index: index, value: value.toFfi()) }
        }
    }

    /// Set or update `key` in map `obj` to a new instance of `ty`
    public func putObject(obj: ObjId, key: String, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.putObjectInMap(obj: obj.bytes, key: key, objType: ty.toFfi()))
            }
        }
    }

    /// Set or update `index` in list `obj` to a new instance of `ty`
    public func putObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.putObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Insert `value` into the sequence `obj` at `index`
    public func insert(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.insertInList(obj: obj.bytes, index: index, value: value.toFfi())
            }
        }
    }

    /// Insert a new instance of `ty` in the list `obj` at `index`
    public func insertObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.insertObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Delete `key` from the map `obj`
    public func delete(obj: ObjId, key: String) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.deleteInMap(obj: obj.bytes, key: key) }
        }
    }

    /// Delete the value at `index` from `obj`
    public func delete(obj: ObjId, index: UInt64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.deleteInList(obj: obj.bytes, index: index) }
        }
    }

    /// Increment the counter at `key` in map `obj` by the amount `by`
    public func increment(obj: ObjId, key: String, by: Int64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.incrementInMap(obj: obj.bytes, key: key, by: by) }
        }
    }

    /// Increment the counter at `index` in list `obj` by the amount `by`
    public func increment(obj: ObjId, index: UInt64, by: Int64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.incrementInList(obj: obj.bytes, index: index, by: by) }
        }
    }

    /// Get the value at `key` from the map `obj`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAll(obj:key:)``
    public func get(obj: ObjId, key: String) throws -> Value? {
        try queue.sync {
            let val = try self.doc.wrapErrors { try $0.getInMap(obj: obj.bytes, key: key) }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the value at `index` from the list `obj`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAll(obj:index:)``
    public func get(obj: ObjId, index: UInt64) throws -> Value? {
        try queue.sync {
            let val = try self.doc.wrapErrors { try $0.getInList(obj: obj.bytes, index: index) }
            return val.map(Value.fromFfi)
        }
    }

    /// Get all the possibly conflicting values at `key` in the map `obj`
    public func getAll(obj: ObjId, key: String) throws -> Set<Value> {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.getAllInMap(obj: obj.bytes, key: key) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get all the possibly conflicting values at `index` in the list `obj`
    public func getAll(obj: ObjId, index: UInt64) throws -> Set<Value> {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.getAllInList(obj: obj.bytes, index: index) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get the value at `key` in map `obj` as at `heads`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAllAt(obj:key:heads:)``
    public func getAt(obj: ObjId, key: String, heads: Set<ChangeHash>) throws
        -> Value?
    {
        try queue.sync {
            let val = try self.doc.wrapErrors {
                try $0.getAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
            }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the value at `index` in list `obj` as at `heads`
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAllAt(obj:index:heads:)``
    public func getAt(obj: ObjId, index: UInt64, heads: Set<ChangeHash>) throws
        -> Value?
    {
        try queue.sync {
            let val = try self.doc.wrapErrors {
                try $0.getAtInList(obj: obj.bytes, index: index, heads: heads.map(\.bytes))
            }
            return val.map(Value.fromFfi)
        }
    }

    /// Get all the possibly conflicting values for `key` in map `obj` as at `heads`
    public func getAllAt(obj: ObjId, key: String, heads: Set<ChangeHash>) throws
        -> Set<Value>
    {
        try queue.sync {
            let vals = try self.doc.wrapErrors {
                try $0.getAllAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
            }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get all the possibly conflicting values for `index` in list `obj` as at `heads`
    public func getAllAt(obj: ObjId, index: UInt64, heads: Set<ChangeHash>)
        throws -> Set<Value>
    {
        try queue.sync {
            let vals = try self.doc.wrapErrors {
                try $0.getAllAtInList(obj: obj.bytes, index: index, heads: heads.map(\.bytes))
            }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get all the keys in the map `obj`
    public func keys(obj: ObjId) -> [String] {
        queue.sync {
            self.doc.wrapErrors { $0.mapKeys(obj: obj.bytes) }
        }
    }

    /// Get all the keys that were in the map `obj` as at `heads`
    public func keysAt(obj: ObjId, heads: Set<ChangeHash>) -> [String] {
        queue.sync {
            self.doc.wrapErrors { $0.mapKeysAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Get all the values in the map or list `obj`
    ///
    /// For a list this just returns the contents of the list, for a map this
    /// returns the values (and not the keys).
    public func values(obj: ObjId) throws -> [Value] {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.values(obj: obj.bytes) }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get the values in the map or list `obj` as at `heads`
    public func valuesAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Value] {
        try queue.sync {
            let vals = try self.doc.wrapErrors {
                try $0.valuesAt(obj: obj.bytes, heads: heads.map(\.bytes))
            }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get the (key,value) entries in the map `obj`
    public func mapEntries(obj: ObjId) throws -> [(String, Value)] {
        try queue.sync {
            let entries = try self.doc.wrapErrors { try $0.mapEntries(obj: obj.bytes) }
            return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
        }
    }

    /// Get the (key,value) entries in the map `obj` as at `heads`
    public func mapEntriesAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [(
        String, Value
    )] {
        try queue.sync {
            let entries = try self.doc.wrapErrors {
                try $0.mapEntriesAt(obj: obj.bytes, heads: heads.map(\.bytes))
            }
            return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
        }
    }

    /// The length of the list `obj`
    public func length(obj: ObjId) -> UInt64 {
        queue.sync {
            self.doc.wrapErrors { $0.length(obj: obj.bytes) }
        }
    }

    /// The length of the list `obj` as at `heads`
    public func lengthAt(obj: ObjId, heads: Set<ChangeHash>) -> UInt64 {
        queue.sync {
            self.doc.wrapErrors { $0.lengthAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Returns the object type for the object Id that you provide.
    /// - Parameter obj: The object Id to inspect.
    public func objectType(obj: ObjId) -> ObjType {
        queue.sync {
            self.doc.wrapErrors {
                ObjType.fromFfi(ty: $0.objectType(obj: obj.bytes))
            }
        }
    }

    /// Get the value of the text object `obj`
    public func text(obj: ObjId) throws -> String {
        try queue.sync {
            try self.doc.wrapErrors { try $0.text(obj: obj.bytes) }
        }
    }

    /// Get the value of the text object `obj` as at `heads`
    public func textAt(obj: ObjId, heads: Set<ChangeHash>) throws -> String {
        try queue.sync {
            try self.doc.wrapErrors { try $0.textAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Get a cursor at the position you specify in the list or text object you provide.
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - position: The index position in the list, or index of the UTF-8 view in the string for a text object.
    /// - Returns: A cursor that references the position you specified.
    public func cursor(obj: ObjId, position: UInt64) throws -> Cursor {
        try queue.sync {
            try Cursor(bytes: self.doc.wrapErrors { try $0.cursor(obj: obj.bytes, position: position) })
        }
    }

    /// Get a cursor at the position and point of time you specify in the list or text object you provide.
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - position: The index position in the list, or index of the UTF-8 view in the string for a text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: A cursor that references the position and point in time you specified.
    public func cursorAt(obj: ObjId, position: UInt64, heads: Set<ChangeHash>) throws -> Cursor {
        try queue.sync {
            try Cursor(bytes: self.doc.wrapErrors { try $0.cursorAt(
                obj: obj.bytes,
                position: position,
                heads: heads.map(\.bytes)
            ) })
        }
    }

    /// The current position of the cursor for the list or text object you provide.
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - cursor: The cursor created for this list or text object
    /// - Returns: The index position of a list, or the index position of the UTF-8 view in the string, of the cursor.
    public func cursorPosition(obj: ObjId, cursor: Cursor) throws -> UInt64 {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.cursorPosition(obj: obj.bytes, cursor: cursor.bytes)
            }
        }
    }

    /// The current position of the cursor for the list or text object you provide.
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - cursor: The cursor created for this list or text object
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The index position of a list, or the index position of the UTF-8 view in the string, of the cursor.
    public func cursorPositionAt(obj: ObjId, cursor: Cursor, heads: Set<ChangeHash>) throws -> UInt64 {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.cursorPositionAt(obj: obj.bytes, cursor: cursor.bytes, heads: heads.map(\.bytes))
            }
        }
    }

    /// Splice into the list `obj`
    ///
    /// - Parameters:
    ///   - obj: The list to into which to insert.
    ///   - start: The index where the function begins inserting or deleting.
    ///   - delete: The number of elements to delete from the `start` index.
    ///   If negative, the function deletes elements preceding `start` index, rather than following it.
    ///   - values: The values to insert after the `start` index.
    public func splice(obj: ObjId, start: UInt64, delete: Int64, values: [ScalarValue]) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.splice(
                    obj: obj.bytes, start: start, delete: delete, values: values.map { $0.toFfi() }
                )
            }
        }
    }

    /// Splice into the list `obj`
    ///
    /// - Parameters:
    ///   - obj: The list into which to insert.
    ///   - start: The index position, in UTF-8 code points, where the function begins inserting or deleting.
    ///   - delete: The number of UTF-8 code points to delete from the `start` index.
    ///   If negative, the function deletes characters preceding `start` index, rather than following it.
    ///   - values: The characters to insert after the `start` index.
    ///
    /// With `spliceText`, the `start` and `delete` parameters represent UTF-8
    /// code point indexes. Swift string indexes represent grapheme clusters, but Automerge works
    /// in terms of UTF-8 code points. This means if you receive indices from other parts
    /// of the application which are swift string indices you need to convert them.
    ///
    /// It can be convenient to access the `UTF8View` of the String through it's `utf8` property,
    /// or if you have a `String.Index` type,  you can convert that into a
    /// `String.UTF8View.Index` position using `samePosition` on the index with
    /// a reference to the UTF-8 view of the string through its `utf8` property.
    public func spliceText(obj: ObjId, start: UInt64, delete: Int64, value: String? = nil) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.spliceText(obj: obj.bytes, start: start, delete: delete, chars: value ?? "")
            }
        }
    }

    /// Add or remove a mark to a given range of text
    ///
    /// - Parameters:
    ///   - obj: The text object to which to add the mark.
    ///   - start: The index position, in UTF-8 code points, where the function starts the mark.
    ///   - end: The index position, in UTF-8 code points, where the function starts the mark.
    ///   - expand: How the mark should expand when text is inserted at the beginning or end of the range
    ///   - name: The name of the mark, for example "bold".
    ///   - value: The scalar value to associate with the mark.
    ///
    /// To remove an existing mark between two index positions, set the name to the same value
    /// as the existing mark and set the value to the scalar value ``ScalarValue/Null``.
    public func mark(
        obj: ObjId,
        start: UInt64,
        end: UInt64,
        expand: ExpandMark,
        name: String,
        value: ScalarValue
    ) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.mark(
                    obj: obj.bytes,
                    start: start,
                    end: end,
                    expand: expand.toFfi(),
                    name: name,
                    value: value.toFfi()
                )
            }
        }
    }

    /// Returns a list of marks for a text object.
    public func marks(obj: ObjId) throws -> [Mark] {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.marks(obj: obj.bytes).map(Mark.fromFfi)
            }
        }
    }

    /// Get the list of marks for a text object at the given heads.
    public func marksAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Mark] {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.marksAt(obj: obj.bytes, heads: heads.map(\.bytes)).map(Mark.fromFfi)
            }
        }
    }

    /// Encode this document in a compressed binary format.
    public func save() -> Data {
        queue.sync {
            self.doc.wrapErrors { Data($0.save()) }
        }
    }

    /// Generate a sync message to send to the peer represented by `state`.
    ///
    /// - Returns: A message to send to the peer, or `nil` if the Automerge documents are in sync.
    public func generateSyncMessage(state: SyncState) -> Data? {
        queue.sync {
            self.doc.wrapErrors {
                if let tempArr = $0.generateSyncMessage(state: state.ffi_state) {
                    return Data(tempArr)
                }
                return nil
            }
        }
    }

    /// Receive a sync message from the peer represented by `state`.
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the message use the function ``receiveSyncMessageWithPatches(state:message:)``.
    public func receiveSyncMessage(state: SyncState, message: Data) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.receiveSyncMessage(state: state.ffi_state, msg: Array(message))
            }
        }
    }

    /// Receive a sync message from the peer represented by `state`, returning patches.
    ///
    /// - Parameters:
    ///   - state: The state of another Automerge document.
    ///   - message: The sync message to integrate into this document.
    /// - Returns: a sequence of ``Patch`` representing the changes which were
    /// made to the document as a result of the message.
    public func receiveSyncMessageWithPatches(state: SyncState, message: Data) throws -> [Patch] {
        try queue.sync {
            let patches = try self.doc.wrapErrors {
                try $0.receiveSyncMessageWithPatches(state: state.ffi_state, msg: Array(message))
            }
            return patches.map { Patch($0) }
        }
    }

    /// Fork the document
    ///
    /// Returns: A copy of the document with a new actor ID, ready for concurrent
    /// use
    public func fork() -> Document {
        queue.sync {
            Document(doc: self.doc.wrapErrors { $0.fork() })
        }
    }

    /// Fork the document as at `heads`
    ///
    /// Fork the document but such that it only contains changes up to `heads`
    public func forkAt(heads: Set<ChangeHash>) throws -> Document {
        try queue.sync {
            try self.doc.wrapErrors { try Document(doc: $0.forkAt(heads: heads.map(\.bytes))) }
        }
    }

    /// Merge this document with `other`
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the merge try using ``mergeWithPatches(other:)``
    public func merge(other: Document) throws {
        try queue.sync {
            try self.doc.wrapErrorsWithOther(other: other.doc) { try $0.merge(other: $1) }
        }
    }

    /// Merge this document with other returning patches
    public func mergeWithPatches(other: Document) throws -> [Patch] {
        try queue.sync {
            let patches = try self.doc.wrapErrorsWithOther(other: other.doc) {
                try $0.mergeWithPatches(other: $1)
            }
            return patches.map { Patch($0) }
        }
    }

    /// Returns a set of change hashes that represent the current state of the document.
    ///
    /// The number of change hashes returned represents the number of concurrent changes the document tracks.
    public func heads() -> Set<ChangeHash> {
        queue.sync {
            Set(self.doc.wrapErrors { $0.heads().map { ChangeHash(bytes: $0) } })
        }
    }

    /// Returns an list of change hashes that represent the causal sequence of changes to the document.
    public func changes() -> [ChangeHash] {
        queue.sync {
            self.doc.wrapErrors { $0.changes().map { ChangeHash(bytes: $0) } }
        }
    }

    /// Get the path to `obj` in the document
    public func path(obj: ObjId) throws -> [PathElement] {
        try queue.sync {
            let elems = try self.doc.wrapErrors { try $0.path(obj: obj.bytes) }
            return elems.map { PathElement.fromFfi($0) }
        }
    }

    /// Encode any changes since the last call to `encodeNewChanges`
    ///
    /// Returns: encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``
    public func encodeNewChanges() -> Data {
        queue.sync {
            self.doc.wrapErrors { Data($0.encodeNewChanges()) }
        }
    }

    /// Encode any changes made since `heads`
    ///
    /// Returns: encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``
    public func encodeChangesSince(heads: Set<ChangeHash>) throws -> Data {
        try queue.sync {
            try self.doc.wrapErrors { try Data($0.encodeChangesSince(heads: heads.map(\.bytes))) }
        }
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
        try queue.sync {
            try self.doc.wrapErrors { try $0.applyEncodedChanges(changes: Array(encoded)) }
        }
    }

    /// Apply encoded changes to this document
    ///
    /// The input to this function can be anything returned by ``save()``,
    /// ``encodeNewChanges()``, ``encodeChangesSince(heads:)`` or any
    /// concatenation of those.
    public func applyEncodedChangesWithPatches(encoded: Data) throws -> [Patch] {
        try queue.sync {
            let patches = try self.doc.wrapErrors {
                try $0.applyEncodedChangesWithPatches(changes: Array(encoded))
            }
            return patches.map { Patch($0) }
        }
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
        doc = try wrappedErrors { try f() }
    }

    func wrapErrors<T>(f: (Doc) throws -> T) throws -> T {
        try wrappedErrors { try f(doc) }
    }

    func wrapErrors<T>(f: (Doc) -> T) -> T {
        f(doc)
    }

    func wrapErrorsWithOther<T>(other: Self, f: (Doc, Doc) throws -> T) throws -> T {
        try wrappedErrors { try f(doc, other.doc) }
    }
}
