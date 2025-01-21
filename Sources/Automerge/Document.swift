import class AutomergeUniffi.Doc
import protocol AutomergeUniffi.DocProtocol
import Foundation

/// An Automerge document that provides an interface to the document-structured data it contains.
///
/// Store your data in the document-based data structure that Automerge provides, similar to representing it with JSON.
/// Like JSON, you structure data with a combination of nested dictionaries and arrays, each of which store values or
/// other container objects.
/// For more detailed information about the types that Automerge stores, see <doc:ModelingData>.
///
/// Use methods on `Document` to save, load, fork, merge, and sync Automerge documents.
/// In addition to working with the low-level methods, this library provides ``AutomergeEncoder`` and
/// ``AutomergeDecoder``, which provide support for mapping your own `Codable` types into an Automerge document.
public final class Document: @unchecked Sendable {
    private var doc: WrappedDoc

    #if !os(WASI)
    let lock = NSRecursiveLock()
    fileprivate func lock<T>(execute work: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
    #else
    fileprivate func lock<T>(execute work: () throws -> T) rethrows -> T {
        try work()
    }
    #endif
    
    #if canImport(Combine)
    private let objectDidChangeSubject: PassthroughSubject<(), Never> = .init()

    /// A publisher that emits after the document has changed.
    ///
    /// This publisher and ``objectWillChange()`` are always paired. Unlike that
    /// publisher, this one fires after the document update is complete, allowing you to
    /// read any changed values.
    ///
    /// An example that uses this publisher to observe granular patch changes:
    ///
    /// ```swift
    /// var observedHeads = doc.heads()
    /// doc.objectDidChange.sink {
    ///     let changes = doc.difference(since: observedHeads)
    ///     observedHeads = doc.heads()
    ///     if !changes.isEmpty {
    ///         processChanges(changes)
    ///     }
    /// }.store(in: &cancellables)
    public lazy var objectDidChange: AnyPublisher<(), Never> = {
        objectDidChangeSubject.eraseToAnyPublisher()
    }()
    #endif

    var reportingLogLevel: LogVerbosity

    /// The actor ID of this document
    public var actor: ActorId {
        get {
            lock {
                ActorId(ffi: self.doc.wrapErrors { $0.actorId() })
            }
        }
        set {
            lock {
                self.doc.wrapErrors { $0.setActor(actor: [UInt8](newValue.data)) }
            }
        }
    }

    /// Retrieve the current text encoding used by the document.
    public var textEncoding: TextEncoding {
        lock {
            self.doc.wrapErrors { $0.textEncoding().textEncoding }
        }
    }

    /// Creates an new, empty Automerge document.
    /// - Parameters:
    ///   - textEncoding: The encoding type for text within the document. Defaults to `.unicodeCodePoint`.
    ///   - logLevel: The level at which to generate logs into unified logging from actions within this document.
    public init(textEncoding: TextEncoding = .unicodeScalar, logLevel: LogVerbosity = .errorOnly) {
        doc = WrappedDoc(Doc.newWithTextEncoding(textEncoding: textEncoding.ffi_textEncoding))
        self.reportingLogLevel = logLevel
    }

    /// Creates a new document from the data that you provide.
    ///
    /// Generate the data for a document by calling ``save()``,
    /// The raw data format of an Automerge document is a series of changes, as such, you can concatenate multiple calls
    /// of
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
    /// and ignores any previous increments or decrements of the value. If you intent to update the counter by a fixed
    /// amount,
    /// use the method ``increment(obj:key:by:)`` instead.
    public func put(obj: ObjId, key: String, value: ScalarValue) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.putInMap(obj: obj.bytes, key: key, value: value.toFfi())
            }
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
    /// and ignores any previous increments or decrements of the value. If you intent to update the counter by a fixed
    /// amount,
    /// use the method ``increment(obj:key:by:)`` instead.
    public func put(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.putInList(obj: obj.bytes, index: index, value: value.toFfi())
            }
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
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return try self.doc.wrapErrors {
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
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return try self.doc.wrapErrors {
                try ObjId(bytes: $0.putObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Insert a value, at the index you provide, into the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - value: The value to insert for the index you provide.
    public func insert(obj: ObjId, index: UInt64, value: ScalarValue) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.insertInList(obj: obj.bytes, index: index, value: value.toFfi())
            }
        }
    }

    /// Insert an object, at the index you provide, into the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object to update.
    ///   - index: The index value of the array to update.
    ///   - ty: The type of object to add to the array.
    /// - Returns: The object Id that references the object added.
    ///
    /// This method extends the array by inserting a new object.
    /// If you want to change an existing index, use the ``putObject(obj:index:ty:)`` to put in an object or
    /// ``put(obj:index:value:)`` to put in a value.
    public func insertObject(obj: ObjId, index: UInt64, ty: ObjType) throws -> ObjId {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return try self.doc.wrapErrors {
                try ObjId(bytes: $0.insertObjectInList(obj: obj.bytes, index: index, objType: ty.toFfi()))
            }
        }
    }

    /// Deletes the key you provide, and its associated value or object, from the dictionary object you specify.
    /// - Parameters:
    ///   - obj: The identifier of the dictionary to update.
    ///   - key: The key to delete.
    public func delete(obj: ObjId, key: String) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.deleteInMap(obj: obj.bytes, key: key)
            }
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
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.deleteInList(obj: obj.bytes, index: index)
            }
        }
    }

    /// Increment or decrement the counter referenced by the key you provide in the dictionary object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object that holds the counter.
    ///   - key: The key in the dictionary object that references the counter.
    ///   - by: The amount to increment, or decrement, the counter.
    public func increment(obj: ObjId, key: String, by: Int64) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.incrementInMap(obj: obj.bytes, key: key, by: by)
            }
        }
    }

    /// Increment or decrement a counter refrerenced at the index you provide in the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object that holds the counter.
    ///   - index: The index position in the array object that references the counter.
    ///   - by: The amount to increment, or decrement, the counter.
    public func increment(obj: ObjId, index: UInt64, by: Int64) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.incrementInList(obj: obj.bytes, index: index, by: by)
            }
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
        try lock {
            let val = try self.doc.wrapErrors { try $0.getInMap(obj: obj.bytes, key: key) }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the value at the index position you provide from the array object you specify.
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
        try lock {
            let val = try self.doc.wrapErrors { try $0.getInList(obj: obj.bytes, index: index) }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the set of possibly conflicting values at the key you provide for the dictionary object that you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    /// - Returns: A set of value objects.
    public func getAll(obj: ObjId, key: String) throws -> Set<Value> {
        try lock {
            let vals = try self.doc.wrapErrors { try $0.getAllInMap(obj: obj.bytes, key: key) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get the set of possibly conflicting values at the index you provide for the array object you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    /// - Returns: A set of the values at that index.
    ///
    /// If you request a index beyond the bounds of the array, this method throws an error.
    public func getAll(obj: ObjId, index: UInt64) throws -> Set<Value> {
        try lock {
            let vals = try self.doc.wrapErrors { try $0.getAllInList(obj: obj.bytes, index: index) }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get the historical value of the key you provide, in the dictionary object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The value of the key at the point in time you provide, or `nil` if the key doesn't exist in the
    /// dictionary.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    ///
    /// > Tip: Note that if there are multiple conflicting values this method
    /// will return one of them  arbitrarily (but deterministically). If you
    /// need all the conflicting values see ``getAllAt(obj:key:heads:)``
    public func getAt(obj: ObjId, key: String, heads: Set<ChangeHash>) throws
        -> Value?
    {
        try lock {
            let val = try self.doc.wrapErrors {
                try $0.getAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
            }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the historical value at of the index you provide in the array object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
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
        try lock {
            let val = try self.doc.wrapErrors {
                try $0.getAtInList(obj: obj.bytes, index: index, heads: heads.map(\.bytes))
            }
            return val.map(Value.fromFfi)
        }
    }

    /// Get the the historical set of possibly conflicting values of the key you provide, in the dictionary object and
    /// point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - key: The key within the dictionary.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The set of value for the key at the point in time you provide, or `nil` if the key doesn't exist in
    /// the dictionary.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func getAllAt(obj: ObjId, key: String, heads: Set<ChangeHash>) throws
        -> Set<Value>
    {
        try lock {
            let vals = try self.doc.wrapErrors {
                try $0.getAllAtInMap(obj: obj.bytes, key: key, heads: heads.map(\.bytes))
            }
            return Set(vals.map { Value.fromFfi(value: $0) })
        }
    }

    /// Get the historical value at of the index you provide, in the array object and point of time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the array object.
    ///   - index: The index position within the array.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The set of possibly conflicting values of the index at the point in time you provide.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func getAllAt(obj: ObjId, index: UInt64, heads: Set<ChangeHash>)
        throws -> Set<Value>
    {
        try lock {
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
        lock {
            self.doc.wrapErrors { $0.mapKeys(obj: obj.bytes) }
        }
    }

    /// Get a historical list of the keys available for the dictionary object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the dictionary object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The set of keys for the dictionary at the point in time you specify.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func keysAt(obj: ObjId, heads: Set<ChangeHash>) -> [String] {
        lock {
            self.doc.wrapErrors { $0.mapKeysAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Get a list of all the current values for the array or dictionary object you specify.
    ///
    /// - Parameter obj: The identifier of an array or dictionary object.
    /// - Returns: For an array object, the list of all current values.
    /// For a dictionary object, the list of the values for all the keys.
    public func values(obj: ObjId) throws -> [Value] {
        try lock {
            let vals = try self.doc.wrapErrors { try $0.values(obj: obj.bytes) }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get a historical list of the values for the array or dictionary object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of an array or dictionary object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: For an array object, the list of all current values.
    /// For a dictionary object, the list of the values for all the keys.
    ///
    /// Use the method ``heads()`` to capture a specific point in time in order to use this method.
    public func valuesAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Value] {
        try lock {
            let vals = try self.doc.wrapErrors {
                try $0.valuesAt(obj: obj.bytes, heads: heads.map(\.bytes))
            }
            return vals.map { Value.fromFfi(value: $0) }
        }
    }

    /// Get a list of the current key and values from the dictionary object you specify.
    ///
    /// - Parameter obj: The identifier of the dictionary object.
    /// - Returns: An array of `(String, Value)` that represents the key and value combinations of the dictionary
    /// object.
    public func mapEntries(obj: ObjId) throws -> [(String, Value)] {
        try lock {
            let entries = try self.doc.wrapErrors { try $0.mapEntries(obj: obj.bytes) }
            return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
        }
    }

    /// Get a historical list of the keys and values from the dictionary object and point in time you specify.
    ///
    /// - Parameter obj: The identifier of the dictionary object.
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: An array of `(String, Value)` that represents the key and value combinations of the dictionary
    /// object.
    public func mapEntriesAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [(
        String, Value
    )] {
        try lock {
            let entries = try self.doc.wrapErrors {
                try $0.mapEntriesAt(obj: obj.bytes, heads: heads.map(\.bytes))
            }
            return entries.map { ($0.key, Value.fromFfi(value: $0.value)) }
        }
    }

    /// Returns the current length of the array, dictionary, or text object you specify.
    ///
    /// - Parameter obj: The identifier of an array, dictionary, or text object.
    public func length(obj: ObjId) -> UInt64 {
        lock {
            self.doc.wrapErrors { $0.length(obj: obj.bytes) }
        }
    }

    /// Returns the historical length of the array, dictionary, or text object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of an array, dictionary, or text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    public func lengthAt(obj: ObjId, heads: Set<ChangeHash>) -> UInt64 {
        lock {
            self.doc.wrapErrors { $0.lengthAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Returns the object type for the object Id that you provide.
    ///
    /// - Parameter obj: The identifier of an array, dictionary, or text object.
    public func objectType(obj: ObjId) -> ObjType {
        lock {
            self.doc.wrapErrors {
                ObjType.fromFfi(ty: $0.objectType(obj: obj.bytes))
            }
        }
    }

    /// Get the current value of the text object you specify.
    ///
    /// - Parameter obj: The identifier of a text object.
    /// - Returns: The current string value that the text object contains.
    public func text(obj: ObjId) throws -> String {
        try lock {
            try self.doc.wrapErrors { try $0.text(obj: obj.bytes) }
        }
    }

    /// Get the historical value of the text object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of a text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The string value that the text object contains at the point in time you specify.
    public func textAt(obj: ObjId, heads: Set<ChangeHash>) throws -> String {
        try lock {
            try self.doc.wrapErrors { try $0.textAt(obj: obj.bytes, heads: heads.map(\.bytes)) }
        }
    }

    /// Establish a cursor at the position you specify in the list or text object you provide.
    ///
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - position: The index position in the list, or index for a text object based on ``TextEncoding``.
    /// - Returns: A cursor that references the position you specified.
    public func cursor(obj: ObjId, position: UInt64) throws -> Cursor {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return try Cursor(bytes: self.doc.wrapErrors { try $0.cursor(obj: obj.bytes, position: position) })
        }
    }

    /// Establish a cursor at the position and point of time you specify in the list or text object you provide.
    ///
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - position: The index position in the list, or index for a text object based on ``TextEncoding``.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: A cursor that references the position and point in time you specified.
    public func cursorAt(obj: ObjId, position: UInt64, heads: Set<ChangeHash>) throws -> Cursor {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return try Cursor(bytes: self.doc.wrapErrors { try $0.cursorAt(
                obj: obj.bytes,
                position: position,
                heads: heads.map(\.bytes)
            ) })
        }
    }

    /// The current position of the cursor for the list or text object you provide.
    ///
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - cursor: The cursor created for this list or text object
    /// - Returns: The index position of a list, or index for a text object based on ``TextEncoding``, of the cursor.
    public func cursorPosition(obj: ObjId, cursor: Cursor) throws -> UInt64 {
        try lock {
            try self.doc.wrapErrors {
                try $0.cursorPosition(obj: obj.bytes, cursor: cursor.bytes)
            }
        }
    }

    /// The historical position of the cursor for the list or text object and point in time you provide.
    ///
    /// - Parameters:
    ///   - obj: The object identifier of the list or text object.
    ///   - cursor: The cursor created for this list or text object
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: The index position of a list, or index for a text object based on ``TextEncoding``, of the cursor.
    public func cursorPositionAt(obj: ObjId, cursor: Cursor, heads: Set<ChangeHash>) throws -> UInt64 {
        try lock {
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
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
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
    ///   - start: The distance from the start of the string where the function begins inserting or deleting.
    ///   - delete: Text length to delete from the `start` index. It depends on the picked ``TextEncoding`` in Document creation.
    ///   If negative, the function deletes characters preceding `start` index, rather than following it.
    ///   - value: The characters to insert after the `start` index.
    ///
    /// With `spliceText`, the `start` and `delete` parameters represent integer distances of the Swift strings. This distance will change
    /// based on the text encoding chosen during at Document creation.
    ///
    /// If you use or receive a Swift `String.Index` convert it to an index position usable by Automerge through `Foundation.String.View`
    /// APIs. Indices in Automerge are based on the ``TextEncoding`` chosen at document creation.
    ///
    /// An example of deriving the automerge start position from a Swift string's index:
    /// ```swift
    /// extension String {
    ///    /// Given: Automerge.Document(textEncoding: .unicodeScalars)
    ///    @inlinable func automergeIndexPosition(index: String.Index) -> UInt64? {
    ///        guard let unicodeScalarIndex = index.samePosition(in: self.unicodeScalars) else {
    ///            return nil
    ///        }
    ///        let intPositionInUnicodeScalar = self.unicodeScalars.distance(
    ///            from: self.unicodeScalars.startIndex,
    ///            to: unicodeScalarIndex)
    ///        return UInt64(intPositionInUnicodeScalar)
    ///    }
    /// }
    /// ```
    ///
    /// For the length of index updates in Automerge, use the count in picked text encoding converted to `Int64`.
    /// For example:
    /// ```swift
    /// Int64("🇬🇧".unicodeScalars.count)
    /// Int64("🇬🇧".utf8.count)
    /// Int64("🇬🇧".utf16.count)
    /// ```
    public func spliceText(obj: ObjId, start: UInt64, delete: Int64, value: String? = nil) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.spliceText(obj: obj.bytes, start: start, delete: delete, chars: value ?? "")
            }
        }
    }

    /// Updates the text object with the value you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object to update.
    ///   - value: The string value for the text
    ///
    /// You can use updateText as an alternative to spliceText for low-level text updates.
    /// This method creates a diff of the text, using Grapheme clusters, to apply updates to change the stored text to
    /// what you provide.
    public func updateText(obj: ObjId, value: String) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors { doc in
                try doc.updateText(obj: obj.bytes, chars: value)
            }
        }
    }

    /// Add or remove a mark to a given range of text
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object to which to add the mark.
    ///   - start: The distance from the start of the string where the function begins inserting or deleting.
    ///   - end: The distance from the start of the string where the function ends the mark.
    ///   - expand: How the mark should expand when text is inserted at the beginning or end of the range
    ///   - name: The name of the mark, for example "bold".
    ///   - value: The scalar value to associate with the mark.
    ///
    /// To remove an existing mark between two index positions, set the name to the same value
    /// as the existing mark and set the value to the scalar value ``ScalarValue/Null``.
    ///
    /// If you use or receive a Swift `String.Index` convert it to an index position usable by Automerge through `Foundation.String.View`
    /// APIs. Indices depends on picked ``TextEncoding`` during Automerge.Document creation.
    ///
    /// An example of deriving the automerge start position from a Swift string's index:
    /// ```swift
    /// extension String {
    ///    /// Given: Automerge.Document(textEncoding: .unicodeScalars)
    ///    @inlinable func automergeIndexPosition(index: String.Index) -> UInt64? {
    ///        guard let unicodeScalarIndex = index.samePosition(in: self.unicodeScalars) else {
    ///            return nil
    ///        }
    ///        let intPositionInUnicodeScalar = self.unicodeScalars.distance(
    ///            from: self.unicodeScalars.startIndex,
    ///            to: unicodeScalarIndex)
    ///        return UInt64(intPositionInUnicodeScalar)
    ///    }
    /// }
    /// ```
    ///
    /// For the length of index updates in Automerge, use the count in picked text encoding converted to `UInt64`.
    /// For example:
    /// ```swift
    /// UInt64("🇬🇧".unicodeScalars.count)
    /// UInt64("🇬🇧".utf8.count)
    /// UInt64("🇬🇧".utf16.count)
    /// ```
    public func mark(
        obj: ObjId,
        start: UInt64,
        end: UInt64,
        expand: ExpandMark,
        name: String,
        value: ScalarValue
    ) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
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
    ///
    /// - Parameter obj: The identifier of the text object.
    /// - Returns: The current list of ``Mark`` for the text object.
    public func marks(obj: ObjId) throws -> [Mark] {
        try lock {
            try self.doc.wrapErrors {
                try $0.marks(obj: obj.bytes).map(Mark.fromFfi)
            }
        }
    }

    /// Get the historical list of marks for a text object and point in time you specify.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object.
    ///   - heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: A list of ``Mark`` for the text object at the point in time you specify.
    public func marksAt(obj: ObjId, heads: Set<ChangeHash>) throws -> [Mark] {
        try lock {
            try self.doc.wrapErrors {
                try $0.marksAt(obj: obj.bytes, heads: heads.map(\.bytes)).map(Mark.fromFfi)
            }
        }
    }

    /// Retrieves the list of marks within a text object at the specified position and point in time.
    ///
    /// This method allows you to get the marks present at a specific position in a text object.
    /// Marks can represent various formatting or annotations applied to the text.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object, represented by an ``ObjId``.
    ///   - position: The position within the text, represented by a ``Position`` enum which can be a ``Cursor`` or an
    /// `UInt64` as a fixed position.
    ///   - heads: A set of `ChangeHash` values that represents a point in time in the document's history.
    /// - Returns: An array of `Mark` objects for the text object at the specified position.
    ///
    /// # Example Usage
    /// ```
    /// let doc = Document()
    /// let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
    ///
    /// let cursor = try doc.cursor(obj: textId, position: 0)
    /// let marks = try doc.marksAt(obj: textId, position: .cursor(cursor), heads: doc.heads())
    /// ```
    ///
    /// ## Recommendation
    ///
    /// Use this method to query the marks applied to a text object at a specific position.
    /// This can be useful for retrieving the list of ``Automerge/Mark`` related to a character without
    /// traversing the full document.
    ///
    /// ## When to Use Cursor vs. Index
    ///
    /// While you can specify the position either with a `Cursor` or an `Index`, there are important distinctions:
    ///
    /// - **Cursor**: Use a `Cursor` when you need to track a position that might change over time due to edits in the
    /// text object. A `Cursor` provides a way to maintain a reference to a logical position within the text even if the
    /// text content changes, making it more robust in collaborative or frequently edited documents.
    ///
    /// - **Index**: Use an `Index` when you have a fixed position and you are sure that the text content will not
    /// change, or changes are irrelevant to your current operation. An index is a straightforward approach for static
    /// text content.
    ///
    /// # See Also
    /// ``marksAt(obj:position:)``
    /// ``marksAt(obj:heads:)``
    ///
    public func marksAt(obj: ObjId, position: Position, heads: Set<ChangeHash>) throws -> [Mark] {
        try lock {
            try self.doc.wrapErrors {
                try $0.marksAtPosition(
                    obj: obj.bytes,
                    position: position.toFfi(),
                    heads: heads.map(\.bytes)
                ).map(Mark.fromFfi)
            }
        }
    }

    /// Retrieves the list of marks within a text object at the specified position.
    ///
    /// This method allows you to get the marks present at a specific position in a text object.
    /// Marks can represent various formatting or annotations applied to the text.
    ///
    /// - Parameters:
    ///   - obj: The identifier of the text object, represented by an ``ObjId``.
    ///   - position: The position within the text, represented by a ``Position`` enum which can be a ``Cursor`` or an
    /// `UInt64` as a fixed position.
    /// - Returns: An array of `Mark` objects for the text object at the specified position.
    /// - Note: This method retrieves marks from the latest version of the document.
    /// If you need to specify a point in the document's history, refer to ``marksAt(obj:position:heads:)``.
    ///
    /// # Example Usage
    /// ```
    /// let doc = Document()
    /// let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
    ///
    /// let cursor = try doc.cursor(obj: textId, position: 0)
    /// let marks = try doc.marksAt(obj: textId, position: .cursor(cursor), heads: doc.heads())
    /// ```
    ///
    /// ## Recommendation
    /// Use this method to query the marks applied to a text object at a specific position.
    /// This can be useful for retrieving the list of ``Automerge/Mark`` related to a character without
    /// traversing the full document.
    ///
    /// ## When to Use Cursor vs. Index
    ///
    /// While you can specify the position either with a `Cursor` or an `Index`, there are important distinctions:
    ///
    /// - **Cursor**: Use a `Cursor` when you need to track a position that might change over time due to edits in the
    /// text object. A `Cursor` provides a way to maintain a reference to a logical position within the text even if the
    /// text content changes, making it more robust in collaborative or frequently edited documents.
    ///
    /// - **Index**: Use an `Index` when you have a fixed position and you are sure that the text content will not
    /// change, or changes are irrelevant to your current operation. An index is a straightforward approach for static
    /// text content.
    ///
    /// # See Also
    /// ``marksAt(obj:position:heads:)``
    /// ``marksAt(obj:heads:)``
    ///
    public func marksAt(obj: ObjId, position: Position) throws -> [Mark] {
        try marksAt(obj: obj, position: position, heads: heads())
    }

    /// Commit the auto-generated transaction with options.
    ///
    /// - Parameters:
    ///   - message: An optional message to attach to the auto-committed change (if any).
    ///   - timestamp: A timestamp to attach to the auto-committed change (if any), defaulting to Date().
    public func commitWith(message: String? = nil, timestamp: Date = Date()) {
        lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            self.doc.wrapErrors {
                $0.commitWith(msg: message, time: Int64(timestamp.timeIntervalSince1970))
            }
        }
    }

    /// Encode the Automerge document in a compressed binary format.
    ///
    /// - Returns: The data that represents all the changes within this document.
    ///
    /// The `save` function also compacts the memory footprint of an Automerge document and increments the result of
    /// ``heads()``, which indicates a specific point in time for the history of the document.
    public func save() -> Data {
        lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            return self.doc.wrapErrors {
                Data($0.save())
            }
        }
    }

    /// Update the sync state you provide and return a sync message to send to a peer.
    ///
    /// - Parameter state: The instance of ``SyncState`` that represents the peer you're syncing with.
    /// - Returns: A message to send to the peer, or `nil` if the Automerge documents are in sync.
    ///
    /// Generate a new ``SyncState`` instance to start a new sync protocol session with a peer.
    /// The sync state maintains the knowledge of this peer and the peer you are syncing with.
    /// Use ``receiveSyncMessage(state:message:)`` to update the sync state with the state, and possibly changes, from
    /// the peer.
    public func generateSyncMessage(state: SyncState) -> Data? {
        lock {
            self.doc.wrapErrors {
                if let tempArr = $0.generateSyncMessage(state: state.ffi_state) {
                    return Data(tempArr)
                }
                return nil
            }
        }
    }

    /// Apply the sync message to update the sync state and Automerge document with the sync message from a peer.
    ///
    /// - Parameters:
    ///   - state: The instance of ``SyncState`` that represents the peer you're syncing with.
    ///   - message: The message from the peer to update this document and sync state.
    ///
    /// > Tip: if you need to know what changed in the document as a result of
    /// the message use the function ``receiveSyncMessageWithPatches(state:message:)``.
    public func receiveSyncMessage(state: SyncState, message: Data) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.receiveSyncMessage(state: state.ffi_state, msg: Array(message))
            }
        }
    }

    /// Apply the sync message to update the sync state and Automerge document with the sync message from a peer,
    /// returning a list of patches applied.
    ///
    /// - Parameters:
    ///   - state: The instance of ``SyncState`` that represents the peer you're syncing with.
    ///   - message: The message from the peer to update this document and sync state.
    /// - Returns: An array of ``Patch`` that represent the changes applied from the peer.
    public func receiveSyncMessageWithPatches(state: SyncState, message: Data) throws -> [Patch] {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
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
        lock {
            Document(doc: self.doc.wrapErrors { $0.fork() })
        }
    }

    /// Fork the document at the point in time you specify.
    ///
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: A copy of the document with a new actor ID that contains the changes up to the point in time you
    /// specify.
    public func forkAt(heads: Set<ChangeHash>) throws -> Document {
        try lock {
            try self.doc.wrapErrors {
                try Document(doc: $0.forkAt(heads: heads.map(\.bytes)))
            }
        }
    }

    /// Merge this document with another.
    ///
    /// - Parameter other: another ``Document``
    ///
    /// > Tip: If you need to know what changed in the document as a result of
    /// the merge, use the method ``mergeWithPatches(other:)`` instead.
    public func merge(other: Document) throws {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrorsWithOther(other: other.doc) { try $0.merge(other: $1) }
        }
    }

    /// Merge this document with other, returning a list of patches applied by the merge.
    ///
    /// - Parameter other: another ``Document``
    /// - Returns: A list of ``Patch`` the represent the changes applied when merging the other document.
    public func mergeWithPatches(other: Document) throws -> [Patch] {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            let patches = try self.doc.wrapErrorsWithOther(other: other.doc) {
                try $0.mergeWithPatches(other: $1)
            }
            return patches.map { Patch($0) }
        }
    }

    /// Returns a set of change hashes that represents the current state of the document.
    ///
    /// The number of change hashes in the returned set represents the number of concurrent changes the document tracks.
    /// The heads returned are the tips of the change graph managed by Automerge, so the number of heads is the number
    /// of concurrent changes at the tips of the graph.
    ///
    /// For example, if two peers make a change concurrently and sync with each other then the synced document will have
    /// two heads.
    /// As soon as one of them makes a change on top of the synced document it will return to one head,
    /// because the new change is not concurrent with the previous changes but causally succeeds them.
    ///
    /// In many ways `heads` returned by Automerge are analogous to heads in `git`
    /// in that the hashes returned identify commits in a graph of commits.
    /// The difference from git is that in git the heads can identify multiple points in the graph.
    ///
    /// Implementation details:
    ///
    /// The number of hashes in the document does increase linearly with the number of changes, but Automerge doesn't
    /// encode the hashes into the output of that is provided when you invoke ``save()``.
    /// Instead Automerge encodes the heads of the tips of the change graph and re-computes internal hashes, which means
    /// there is no storage cost for these hashes.
    public func heads() -> Set<ChangeHash> {
        lock {
            Set(self.doc.wrapErrors { $0.heads().map { ChangeHash(bytes: $0) } })
        }
    }

    /// Returns an list of change hashes that represent the causal sequence of changes to the document.
    ///
    /// - Returns: An array of ``ChangeHash`` that represents the sequence of change hashes in the document.
    public func getHistory() -> [ChangeHash] {
        lock {
            self.doc.wrapErrors { $0.changes().map { ChangeHash(bytes: $0) } }
        }
    }

    /// Returns the contents of the change associated with the change hash you provide.
    public func change(hash: ChangeHash) -> Change? {
        lock {
            guard let change = self.doc.wrapErrors(f: { $0.changeByHash(hash: hash.bytes) }) else {
                return nil
            }
            return .init(change)
        }
    }

    /// Generates patches between two points in the document history.
    ///
    /// Use:
    /// ```
    /// let doc = Document()
    /// let textId = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
    /// let before = doc.heads()
    ///
    /// try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
    /// let after = doc.heads()
    ///
    /// let patches = doc.difference(from: before, to: after)
    /// ```
    ///
    /// - Parameters:
    ///   - before: The set of heads at beginning point in the documents history.
    ///   - after: The set of heads at ending point in the documents history.
    /// - Note: `from` and `to` do not have to be chronological. Document state can move backward.
    /// - Returns: The difference needed to produce a document at `to` when it is set at `from` in history.
    public func difference(from before: Set<ChangeHash>, to after: Set<ChangeHash>) -> [Patch] {
        lock {
            let patches = self.doc.wrapErrors { doc in
                doc.difference(before: before.map(\.bytes), after: after.map(\.bytes))
            }
            return patches.map { Patch($0) }
        }
    }

    /// Generates patches **since** a given point in the document history.
    ///
    /// Use:
    /// ```
    /// let doc = Document()
    /// doc.difference(since: doc.heads())
    /// ```
    ///
    /// - Parameters:
    ///     - lhs: The set of heads at the point in the documents history to compare to.
    /// - Returns: The difference needed to produce current document given an arbitrary
    /// point in the history.
    public func difference(since lhs: Set<ChangeHash>) -> [Patch] {
        difference(from: lhs, to: heads())
    }

    /// Generates patches **to** a given point in the document history.
    ///
    /// Use:
    /// ```
    /// let doc = Document()
    /// doc.difference(to: doc.heads())
    /// ```
    ///
    /// - Parameters:
    ///     - rhs: The set of heads at ending point in the documents history.
    /// - Returns: The difference needed to move current document to a previous point
    /// in the history.
    public func difference(to rhs: Set<ChangeHash>) -> [Patch] {
        difference(from: heads(), to: rhs)
    }

    /// Get the path to an object within the document.
    ///
    /// - Parameter obj: The identifier of an array, dictionary or text object.
    /// - Returns: An array of ``PathElement`` that represents the schema location of the object within the document.
    public func path(obj: ObjId) throws -> [PathElement] {
        try lock {
            let elems = try self.doc.wrapErrors { try $0.path(obj: obj.bytes) }
            return elems.map { PathElement.fromFfi($0) }
        }
    }

    /// Returns the binary encoding of the changes since the last call to this method.
    ///
    /// - Returns: Encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``.
    public func encodeNewChanges() -> Data {
        lock {
            self.doc.wrapErrors { Data($0.encodeNewChanges()) }
        }
    }

    /// Encode and return any changes made to the document between now and the point in time you specify.
    ///
    /// - Parameter heads: The set of ``ChangeHash`` that represents a point of time in the history the document.
    /// - Returns: Encoded changes suitable for sending over the network and
    /// applying to another document using ``applyEncodedChanges(encoded:)``.
    public func encodeChangesSince(heads: Set<ChangeHash>) throws -> Data {
        try lock {
            try self.doc.wrapErrors {
                try Data($0.encodeChangesSince(heads: heads.map(\.bytes)))
            }
        }
    }

    /// Apply encoded changes to the document.
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
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
            try self.doc.wrapErrors {
                try $0.applyEncodedChanges(changes: Array(encoded))
            }
        }
    }

    /// Apply encoded changes to this document, returning patches that represent the changes made to the document.
    ///
    /// - Parameter encoded: The encoded changes to apply.
    /// - Returns: An array of ``Patch`` that represent the changes applied.
    ///
    /// The input to this function can be anything returned by ``save()``,
    /// ``encodeNewChanges()``, ``encodeChangesSince(heads:)`` or any
    /// concatenation of those.
    public func applyEncodedChangesWithPatches(encoded: Data) throws -> [Patch] {
        try lock {
            sendObjectWillChange()
            defer { sendObjectDidChange() }
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

// Observable Object conformance for Document

#if canImport(Combine)
import Combine
import OSLog

extension Document: ObservableObject {
    fileprivate func sendObjectWillChange() {
        // DEBUGGING / DIAGNOSTICS CODE to show where object changes are being initiated
//        #if canImport(os)
//        if #available(macOS 11, iOS 14, *) {
//            let logger = Logger(subsystem: "Automerge", category: "AutomergeText")
//            logger.trace("Document \(String(describing: self)) sending ObjectWillChange")
//            let callStacks = Thread.callStackSymbols
//            if callStacks.count > 5 {
//                for callStackFrame in callStacks[0 ... 5] {
//                    logger.trace(" - \(callStackFrame)")
//                }
//            } else {
//                for callStackFrame in callStacks {
//                    logger.trace(" - \(callStackFrame)")
//                }
//            }
//        }
//        #endif
        objectWillChange.send()
    }

    fileprivate func sendObjectDidChange() {
        objectDidChangeSubject.send()
    }
}
#else
fileprivate extension Document {
    func sendObjectWillChange() {}
    func sendObjectDidChange() {}
}
#endif
