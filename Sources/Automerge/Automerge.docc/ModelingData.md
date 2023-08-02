# Modeling Data with Automerge

Model data in a document to share and synchronize it.

## Overview

The central data type of Automerge is a ``Document`` which presents a data model similar to a JSON document. 
The structure is composed of arrays and string keyed maps, nested within one another. 
Unlike JSON, a `Document` is backed by a set of nested CRDTs. 
Because of this, a `Document` can be merged with any other `Document` in a manner which preserves user intent as much as possible.

### Document-based Model

Any type that supports the [Codable](https://developer.apple.com/documentation/swift/codable) protocol can be stored and retrieved from a Document using the ``AutomergeEncoder`` and ``AutomergeDecoder``.
This encoder and decoder pair do the work to establish schema within your `Document`, as well as store and load the content into your Codable types.
For example, you can create a new Automerge document, and an encoder to write into that document:

```swift
import Automerge
let doc = Document()
let automergeEncoder = AutomergeEncoder(doc: doc)
```

A new document is empty, containing no data or schema. 
When you encode into the document, the default behavior of the encoder establishes the document model.
If the document already has a document model encoded within it, and it doesn't match the type you encode or decode, the encoder or decoder throws an error.
The following example creates a simple struct and encodes it into a new document:

```swift
struct Note: Codable, Equatable {
    let created: Date
    var notes: String
}

let sample = Note(
    created: Date.now,
    notes: "An example string to show encoding."
)
print(sample)
// Note(created: 2023-08-01 23:28:38 +0000, notes: "An example string to show encoding.")

try automergeEncoder.encode(sample)
```

Akin to using a JSON encoder and decoder, there is a matching `AutomergeDecoder` that allows you to decode from an Automerge document:

```swift
let automergeDecoder = AutomergeDecoder(doc: doc)
let decodedStruct = try automergeDecoder.decode(Note.self)
print(decodedStruct)
// Note(created: 2023-08-01 23:28:38 +0000, notes: "An example string to show encoding.")
```

The `Document` class also provides low-level methods to read and write values into an Automerge document.
The data within an Automerge document is composed of objects, represented by the enumeration ``Value``.
Objects that contain other objects are composed of an identifier: ``ObjId``, and the type: ``ObjType``.
Like JSON, there are arrays (``ObjType/List``) and dictionaries (``ObjType/Map``).
Also like JSON, Dictionaries within Automerge are keyed only by Strings.
Unlike JSON, there is a special type ``ObjType/Text`` to represent a concurrently editable string, represented internally as a list of UTF-8 characters.
This special type encodes and decodes from the type ``AutomergeText``.

### Automerge Document Primitives

Objects that don't contain other objects map to Automerge's primitive types, represented by the enumeration ``ScalarValue``.
Automerge internally represents more discrete types than JSON.
The AutomergeEncoder and AutomergeDecoder convert existing types into Automerge primitives.

| Automerge primitive | Matching Swift type |
| --- | --- |
| null (``ScalarValue/Null``) | `nil` |
| booleans (``ScalarValue/Boolean(_:)``) | `Bool` |
| unsigned integers (``ScalarValue/Uint(_:)``)  | `UInt` |
| signed integers (``ScalarValue/Int(_:)``) | `Int` |
| floating point numbers (``ScalarValue/F64(_:)``) | `Double` |
| strings (``ScalarValue/String(_:)``) | `String` |
| byte arrays (``ScalarValue/Bytes(_:)``) | `Data` |
| timestamps (``ScalarValue/Timestamp(_:)``) | `Date` |
| counters (``ScalarValue/Counter(_:)``) | ``Counter`` |

`Counter` is another special type that is used to represent a concurrently updated counter that increments and decrements integer values, as opposed to a integer value that is set discretely.

It's important to note that Automerge is a cross platform library, and an Automerge document's internal schema is dynamic.
Although not supported by Swift arrays, an Automerge array can contain any other kind of Automerge object or primitive within it.
Likewise dictionaries values can contain any other kind of Automerge object or primitive within it.
When you use the `AutomergeEncoder` or `AutomergeDecoder` these follow the rules and conventions for Swift types.
For example, an Automerge document with a list of mixed Integers and Strings would not be decodable by `AutomergeDecoder`, although it is a valid Automerge document.

### Creating, Reading and Writing a document

If you're not using the encoder and decoder, you need to establish container objects yourself, and add and remove values within them.
The methods are `Document` that support this require that you identify the relevant property for an object.
This is either the parameter `key`, represented by a `String`, in the case of dictionaries, or the parameter `index`, represented by `UInt64`.
For example, use ``Document/get(obj:key:)`` to get a value out of a dictionary and ``Document/get(obj:index:)`` to get a value out of an array. 

Methods that insert an object into the document are separate to those which insert primitive values. For example, ``Document/put(obj:key:value:)`` puts a value into a dictionary, while ``Document/putObject(obj:key:ty:)`` puts an object of the type you specify into the dictionary.
The methods which insert an object return an ``ObjId`` of the newly created object, which you use to modify the contents of the new object. 
See the documentation of ``Document`` for more details on the individual methods.

### Heads and change hashes

An Automerge document is a little like a git repository in that it is composed of a graph of changes, each identified by a hash. 
Like a git repository, a point in the history of an Automerge document can be referenced by its hash. 
_Unlike_ a git repository, an Automerge document can have multiple heads for a given point in time, representing a merge of concurrent changes. 

From time to time you may want to refer to a particular point in the document history. 
For example, you may want to read values as at that point in time, or get the changes since that time.
Use ``Document/heads()`` to obtain the current heads of the document, which returns a set of ``ChangeHash``. 
`Document` includes families of methods that accept `[ChangeHash]` to retrieve values or objects from that point in time.

Unlike git, Automerge does not track additional metadata about the changes over time, such as who contributed any change, or at what time the change was initially created. 

### Syncing documents

Automerge provides methods to synchronize documents, passing compact messages between two peers to bring them up to date with each other's changes.
To sync two documents, create a ``SyncState`` to represent the peer document you are connecting to, and
generate messages to send to them using ``Document/generateSyncMessage(state:)``.
Receive sync messages from that same peer and update the sync state using ``Document/receiveSyncMessage(state:message:)``.
Repeatedly call, in order, `generateSyncMessage` and receive updates with `receiveSyncMessage` until a call to `generateSyncMessage` doesn't return any bytes for a sync message.
At that point, the two documents are fully in sync.

### Getting notified of what changed

When you apply changes received from a remote document (or merged from a separate local document) you may want to know what changed within the `Document`, for example to update an app's user interface.
To get this detail, use ``Document/receiveSyncMessageWithPatches(state:message:)``, which operates like `Document/receiveSyncMessage(state:message:)`, and additionally returns an array of patches, represented by the type ``Patch``.

You can inspect a patch to see what action was applied using the ``Patch/action`` property (represented by the enumeration ``PatchAction``), and the path to the element (``Patch/path``) within the document that was updated, represented by ``PathElement``, which in turn includes ``Prop`` and ``ObjId``.
`Prop` is an enumeration that represents either a key to a dictionary and it's value, or the index location within an array.

### Saving and loading Documents

An Automerge document can be saved using ``Document/save()``. 
This will produce a compressed encoding of the document which is extremely efficient and which can be loaded using ``Document/init(_:logLevel:)``. 
In many cases you know that the other end already has some set of changes and you just want to send "new" changes. 
You can obtain these changes using ``Document/encodeNewChanges()`` and ``Document/encodeChangesSince(heads:)``. 
On the other end of the wire you can apply changes using ``Document/applyEncodedChanges(encoded:)``.

Automerge leaves the process of how you transfer, store, or load those bytes up to you.



