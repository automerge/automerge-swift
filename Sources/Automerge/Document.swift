import class AutomergeUniffi.Doc
import protocol AutomergeUniffi.DocProtocol
import Foundation

/// The entry point to Automerge, a ``Document`` presents an interface to
/// the data it contains; as well as methods for loading and saving documents, and
/// taking part in the sync protocol.
/// 
/// Data stored within Document is structured in a document-based format, similar to a JSON file in that it is made up of nested dictionaries and arrays, each of which may store values or other container objects.
/// For more information about the types that Automerge stores, see <doc:ModelingData>.
/// 
/// Methods for interacting with the low-level document structure are included on `Document`, organized by the type of internal type you are read or write.
/// The Automerge-swift library also provides ``AutomergeEncoder`` and ``AutomergeDecoder`` to support more conveniently mapping your own `Codable` types into an Automerge document.
public final class Document: @unchecked Sendable {
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

    /// Creates an new, empty Automerge document.
    /// - Parameter logLevel: The level at which to generate logs into unified logging from actions within this document.
    public init(logLevel: LogVerbosity = .errorOnly) {
        doc = WrappedDoc(Doc())
        self.reportingLogLevel = logLevel
    }

    /// Creates a new document from the data that you provide.
    /// 
    /// Generate the data for a document by calling ``save()``,
    /// The raw data format of an Automerge document is a series of changes, as such, you can concatenate multiple calls of
    /// ``encodeChangesSince(heads:)``, ``encodeNewChanges()``, or
    /// any sequence of bytes containing valid encodings of automerge changes.
    /// - Parameters:
    ///   - bytes: A data buffer of encoded automerge changes.
    ///   - logLevel: The level at which to generate logs into unified logging from actions within this document.
    public init(_ bytes: Data, logLevel: LogVerbosity = .errorOnly) throws {
        doc = try WrappedDoc { try Doc.load(bytes: Array(bytes)) }
        self.reportingLogLevel = logLevel
    }

    private init(doc: Doc, logLevel: LogVerbosity = .errorOnly) {
        self.doc = WrappedDoc(doc)
        self.reportingLogLevel = logLevel
    }

    /// Set or update a value within a dictionary object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object to update.
    ///   - key: The key of the property to update.
    ///   - value: The value to set for the key you provide.
    ///
    /// If the object you update is a ``ScalarValue/Counter(_:)``, calling this function uniformly sets the value
    /// and ignores any previous increments or decrements of the value. If you intent to update the counter by a fixed amount,
    /// use the method ``increment(obj:key:by:)`` instead.
    public func put(obj: ObjId, key: String, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.putInMap(obj: obj.bytes, key: key, value: value.toFfi()) }
        }
    }

    /// Set or update a value within an array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - value: The value to set for the index you provide.
    ///
    /// If the index position doesn't yet exist within the array, this method will throw an error.
    /// To add an object that extends the array, use the method ``insert(obj:index:value:)``
    ///
    /// If the object you update is a ``ScalarValue/Counter(_:)``, calling this function uniformly sets the value
    /// and ignores any previous increments or decrements of the value. If you intent to update the counter by a fixed amount,
    /// use the method ``increment(obj:key:by:)`` instead.
    public func put(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.putInList(obj: obj.bytes, index: index, value: value.toFfi()) }
        }
    }

    /// Set or update an object within a dictionary object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object to update.
    ///   - key: The key of the property to update.
    ///   - ty: The type of object to add to the dictionary.
    /// - Returns: The object Id that references the object added.
    public func putObject(obj: ObjId, key: String, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.putObjectInMap(obj: obj.bytes, key: key, objType: ty.toFfi()))
            }
        }
    }

    /// Set or update an object within an array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - ty: The type of object to add to the array.
    /// - Returns: The object Id that references the object added.
    ///
    /// If the index position doesn't yet exist within the array, this method will throw an error.
    /// To add an object that extends the array, use the method ``insertObject(obj:index:ty:)``.
    public func putObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.putObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Insert a value into the array object you specify, at the index you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - value: The value to insert for the index you provide.
    public func insert(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.insertInList(obj: obj.bytes, index: index, value: value.toFfi())
            }
        }
    }

    /// Insert an object into the array object you specify, at the index you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - ty: The type of object to add to the array.
    /// - Returns: The object Id that references the object added.
    ///
    /// This method extends the array by inserting a new object.
    /// If you want to change an existing index, use the ``putObject(obj:index:ty:)`` to put in an object or ``put(obj:index:value:)`` to put in a value.
    public func insertObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try queue.sync {
            try self.doc.wrapErrors {
                try ObjId(bytes: $0.insertObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Deletes the key you provide, and its associated value or object, from the dictionary object you specify.
    /// - Parameters:
    ///   - obj: The identifier of the dictionary to update.
    ///   - key: The key to delete.
    public func delete(obj: ObjId, key: String) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.deleteInMap(obj: obj.bytes, key: key) }
        }
    }

    /// Deletes the object or value at the index you provide from the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array to update.
    ///   - index: The index position to remove.
    ///
    /// This method shrinks the length of the array object.
    public func delete(obj: ObjId, index: UInt64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.deleteInList(obj: obj.bytes, index: index) }
        }
    }

    /// Increment or decrement a counter stored at the key you provide in the dictionary object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object that holds the counter.
    ///   - key: The key in the dictionary object that references the counter.
    ///   - by: The amount to increment, or decrement, the counter.
    public func increment(obj: ObjId, key: String, by: Int64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.incrementInMap(obj: obj.bytes, key: key, by: by) }
        }
    }

    /// Increment or decrement a counter stored at the index you provide in the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object that holds the counter.
    ///   - index: The index position in the array object that references the counter.
    ///   - by: The amount to increment, or decrement, the counter.
    public func increment(obj: ObjId, index: UInt64, by: Int64) throws {
        try queue.sync {
            try self.doc.wrapErrors { try $0.incrementInList(obj: obj.bytes, index: index, by: by) }
        }
    }

    /// Get the value of the key you provide from the dictionary object you specify.
    /// 
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    /// - Returns: The value of the key, or `nil` if the key doesn't exist in the dictionary.
    ///
    /// Inspect the ``Value`` returned to determine if the value represents an object or a scalar value.
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

    /// Get the value at the index you provide from the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    /// - Returns: The value of the key, or `nil` if the key doesn't exist in the dictionary.
    ///
    /// If you request a index beyond the bounds of the array, this method throws an error.
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

    /// Get all the possibly conflicting values at the key you provide within the dictionary object that you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    /// - Returns: A set of value objects.
    public func getAll(obj: ObjId, key: String) throws -> Set<Value> {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.getAllInMap(obj: obj.bytes, key: key) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get all the possibly conflicting values at the index you provide within the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    /// - Returns: A set of the values at that index.
    ///
    /// If you request a index beyond the bounds of the array, this method throws an error.
    public func getAll(obj: ObjId, index: UInt64) throws -> Set<Value> {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.getAllInList(obj: obj.bytes, index: index) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get the value of the key you provide, in the dictionary object you specify, with its historical value as identified by the heads you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The value of the key at the point in time you provide, or `nil` if the key doesn't exist in the dictionary.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
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

    /// Get the value at of the index you provide, in the array object you specify, with its historical value as identified by the heads you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The value of the index at the point in time you provide, or `nil` if the value doesn't exist.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
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

    /// Get the the set of possibly conflicting values of the key you provide, in the dictionary object you specify, with its historical value as marks by the heads you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The set of value for the key at the point in time you provide, or `nil` if the key doesn't exist in the dictionary.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
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

    /// Get the value at of the index you provide, in the array object you specify, with its historical value as identified by the heads you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The set of possibly conflicting values of the index at the point in time you provide.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
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

    /// Get a list of all the current keys available for the dictionary object you specify.
    ///
    /// - Parameter obj: The identifier of the dictionary object.
    /// - Returns: The keys for that dictionary.
    public func keys(obj: ObjId) -> [String] {
        queue.sync {
            self.doc.wrapErrors { $0.mapKeys(obj: obj.bytes) }
        }
    }

    /// Get a list of all the keys available for the dictionary object you specify, at the historical point in time identified by the heads you provide.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The set of keys for the dictionary at the point in time you specify.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func keysAt(obj: ObjId, heads: Set<ChangeHash>) -> [String] {
        queue.sync {
            self.doc.wrapErrors { $0.mapKeysAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Get a list of all the current values for the array or dictionary object you specify.
    ///
    /// - Parameter obj: The identifier of an array or dictionary object.
    /// - Returns: For an array object, the list of all current values.
    /// For a dictionary object, the list of the values for all the keys.
    public func values(obj: ObjId) throws -> [Value] {
        try queue.sync {
            let vals = try self.doc.wrapErrors { try $0.values(obj: obj.bytes) }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get a list of the all the values at the historical point in you specify, for the array or dictionary object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of an array or dictionary object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: For an array object, the list of all current values.
    /// For a dictionary object, the list of the values for all the keys.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func valuesAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Value] {
        try queue.sync {
            let vals = try self.doc.wrapErrors {
                try $0.valuesAt(obj: obj.bytes, heads: heads.map(\.bytes))
            }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get a list of the current key and values from the dictionary object you specify.
    /// - Parameter obj: The identifier of the dictionary object.
    /// - Returns: An array of `(String, Value)` that represents the key and value combinations of the dictionary object.
    public func mapEntries(obj: ObjId) throws -> [(String, Value)] {
        try queue.sync {
            let entries = try self.doc.wrapErrors { try $0.mapEntries(obj: obj.bytes) }
            return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
        }
    }

    /// Get a list of the key and values at the historical point in time you specify, from the dictionary object you specify.
    /// - Parameter obj: The identifier of the dictionary object.
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: An array of `(String, Value)` that represents the key and value combinations of the dictionary object.
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

    /// Returns the current length of the array, dictionary, or text object you specify.
    /// - Parameter obj: The identifier of an array, dictionary, or text object.
    public func length(obj: ObjId) -> UInt64 {
        queue.sync {
            self.doc.wrapErrors { $0.length(obj: obj.bytes) }
        }
    }

    /// Returns the length of the array, dictionary, or text object you specify at the historical point of time you specify.
    /// - Parameters:
    ///   - obj: The identifier of an array, dictionary, or text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    public func lengthAt(obj: ObjId, heads: Set<ChangeHash>) -> UInt64 {
        queue.sync {
            self.doc.wrapErrors { $0.lengthAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Returns the object type for the object Id that you provide.
    /// - Parameter obj: The identifier of an array, dictionary, or text object.
    public func objectType(obj: ObjId) -> ObjType {
        queue.sync {
            self.doc.wrapErrors {
                ObjType.fromFfi(ty: $0.objectType(obj: obj.bytes))
            }
        }
    }

    /// Get the current value of the text object you specify.
    /// - Parameter obj: The identifier of a text object.
    /// - Returns: The current string value that the text object contains.
    public func text(obj: ObjId) throws -> String {
        try queue.sync {
            try self.doc.wrapErrors { try $0.text(obj: obj.bytes) }
        }
    }

    /// Get the value of the text object you specify at the historical point in time that you specify.
    /// - Parameters:
    ///   - obj: The identifier of a text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: The string value that the text object contains at the point in time you specify.
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

    /// Splice an array of values into the array object you specify.
    /// 
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - start: The index where the splice method begins inserting or deleting.
    ///   - delete: The number of elements to delete from the `start` index.
    ///   If negative, the function deletes elements preceding `start` index, rather than following it.
    ///   - values: An array of values to insert after the `start` index.
    public func splice(obj: ObjId, start: UInt64, delete: Int64, values: [ScalarValue]) throws {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.splice(
                    obj: obj.bytes, start: start, delete: delete, values: values.map { $0.toFfi() }
                )
            }
        }
    }

    /// Splice characters into the text object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object to update.
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
    ///   - obj: The identifier of the text object to which to add the mark.
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

    /// Returns the current list of marks for a text object.
    /// - Parameter obj: The identifier of the text object.
    /// - Returns: The current list of ``Mark`` for the text object.
    public func marks(obj: ObjId) throws -> [Mark] {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.marks(obj: obj.bytes).map(Mark.fromFfi)
            }
        }
    }

    /// Get the list of marks for a text object at the given heads.
    /// - Parameters:
    ///   - obj: The identifier of the text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: A list of ``Mark`` for the text object at the point in time you specify.
    public func marksAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Mark] {
        try queue.sync {
            try self.doc.wrapErrors {
                try $0.marksAt(obj: obj.bytes, heads: heads.map(\.bytes)).map(Mark.fromFfi)
            }
        }
    }

    /// Encode this document in a compressed binary format.
    /// - Returns: The data that represents all the changes within this document.
    ///
    /// The `save` function also compacts the memory footprint of an Automerge document and increments the result of ``heads()``, which indicates a specific point in time for the history of the document.
    public func save() -> Data {
        queue.sync {
            self.doc.wrapErrors { Data($0.save()) }
        }
    }

    /// Generate a sync message to send to a peer.
    ///
    /// - Parameter state: The instance of ``SyncState`` that represents the peer you're syncing with.
    /// - Returns: A message to send to the peer, or `nil` if the Automerge documents are in sync.
    ///
    /// Generate a new ``SyncState`` instance to start a new sync protocol session with a peer.
    /// The sync state maintains the knowledge of this peer and the peer you are syncing with.
    /// Use ``receiveSyncMessage(state:message:)`` to update the sync state with the state, and possibly changes, from the peer.
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
    /// - Parameters:
    ///   - state: The instance of ``SyncState`` that represents the peer you're syncing with.
    ///   - message: The message from the peer to update this document and sync state.
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
    ///   - state: The instance of ``SyncState`` that represents the peer you're syncing with.
    ///   - message: The message from the peer to update this document and sync state.
    /// - Returns: An array of ``Patch`` that represent the changes applied from the peer.
    public func receiveSyncMessageWithPatches(state: SyncState, message: Data) throws -> [Patch] {
        try queue.sync {
            let patches = try self.doc.wrapErrors {
                try $0.receiveSyncMessageWithPatches(state: state.ffi_state, msg: Array(message))
            }
            return patches.map { Patch($0) }
        }
    }

    /// Fork the document.
    ///
    /// - Returns: A copy of the document with a new actor ID.
    public func fork() -> Document {
        queue.sync {
            Document(doc: self.doc.wrapErrors { $0.fork() })
        }
    }

    /// Fork the document at the point in time you specify.
    ///
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: A copy of the document with a new actor ID that contains the changes up to the point in time you specify.
    public func forkAt(heads: Set<ChangeHash>) throws -> Document {
        try queue.sync {
            try self.doc.wrapErrors { try Document(doc: $0.forkAt(heads: heads.map(\.bytes))) }
        }
    }

    /// Merge this document with another.
    /// 
    /// - Parameter other: another ``Document``
    ///
    /// > Tip: If you need to know what changed in the document as a result of
    /// the merge, use the method ``mergeWithPatches(other:)`` instead.
    public func merge(other: Document) throws {
        try queue.sync {
            try self.doc.wrapErrorsWithOther(other: other.doc) { try $0.merge(other: $1) }
        }
    }

    /// Merge this document with other returning patches
    /// - Parameter other: another ``Document``
    /// - Returns: A list of ``Patch`` the represent the changes applied when merging the other document.
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
    /// The number of change hashes in the returned set represents the number of concurrent changes the document tracks.
    public func heads() -> Set<ChangeHash> {
        queue.sync {
            Set(self.doc.wrapErrors { $0.heads().map { ChangeHash(bytes: $0) } })
        }
    }

    /// Returns an list of change hashes that represent the causal sequence of changes to the document.
    /// - Returns: An array of ``ChangeHash`` that represents the sequence of change hashes in the document.
    public func getHistory() -> [ChangeHash] {
        queue.sync {
            self.doc.wrapErrors { $0.changes().map { ChangeHash(bytes: $0) } }
        }
    }

    /// Get the path to an object within the document.
    ///
    /// - Parameter obj: The identifier of an array, dictionary or text object.
    /// - Returns: An array of ``PathElement`` that represents the schema location of the object within the document.
    public func path(obj: ObjId) throws -> [PathElement] {
        try queue.sync {
            let elems = try self.doc.wrapErrors { try $0.path(obj: obj.bytes) }
            return elems.map { PathElement.fromFfi($0) }
        }
    }

    /// Returns the binary encoding of the changes since the last call to this method.
    ///
    /// - Returns: Encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``.
    public func encodeNewChanges() -> Data {
        queue.sync {
            self.doc.wrapErrors { Data($0.encodeNewChanges()) }
        }
    }

    /// Encode any changes made since the point in time you specify.
    /// 
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time within the document.
    /// - Returns: Encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``.
    public func encodeChangesSince(heads: Set<ChangeHash>) throws -> Data {
        try queue.sync {
            try self.doc.wrapErrors { try Data($0.encodeChangesSince(heads: heads.map(\.bytes))) }
        }
    }

    /// Apply encoded changes to this document.
    /// 
    /// - Parameter encoded: The encoded changes to apply.
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

    /// Apply encoded changes to this document, returning patches.
    /// 
    /// - Parameter encoded: The encoded changes to apply.
    /// - Returns: An array of ``Patch`` that represent the changes applied.
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
