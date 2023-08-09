# Modeling Data with Automerge

Model data in a document to share and synchronize it.

## Overview

The central data type of Automerge is a ``Document`` which presents a data model similar to a JSON document. 
The structure is composed of arrays and string keyed maps, nested within one another. 
Unlike JSON, a `Document` is backed by a set of nested CRDTs. 
Because of this, a `Document` can be merged with any other `Document` in a manner which preserves user intent as much as possible.

### Document-based Model

Any type that supports the [Codable](https://developer.apple.com/documentation/swift/codable) protocol can be stored and retrieved from a Document using the ``AutomergeEncoder`` and ``AutomergeDecoder``.
This encoder and decoder pair do the work to establish schema within your `Document`, as well as store and load the content into your `Codable` types.
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

The `Document` class provides low-level methods to read and write values into an Automerge document.
The data within an Automerge document is composed of objects, represented by the enumeration ``Value``.
Objects that contain other objects are composed of an identifier: ``ObjId``, and the type: ``ObjType``.
Like JSON, Automerge includes objects that contain other objects: arrays (``ObjType/List``) and dictionaries (``ObjType/Map``).
Also like JSON, dictionaries in Automerge are keyed only by Strings.

Automerge goes further than JSON in representing a few types.
For example, Automerge includes a special type ``ObjType/Text`` to represent a concurrently editable string, separate from a singular value update of a string, represented by ``ScalarValue/String(_:)``.
The `Text` object type represents the value of the string as a list of UTF-8 characters.
This special type encodes and decodes from the type ``AutomergeText``.
When serialized by `AutomergeDecoder` or `AutomergeEncoder`, the type ``AutomergeText`` represents an ``ObjType/Text`` object, and handles updates into the Automerge document.

### Automerge Document Primitives

Objects within an Automerge document that don't contain other objects are made up of the primitive types for Automerge, represented by the enumeration ``ScalarValue``.
Automerge maintains more type tracking than JSON, representing a number of different types internally.
The `AutomergeEncoder` and `AutomergeDecoder` convert existing Swift types into and out of Automerge primitives.

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

`Bytes` scalar values are a buffer of bytes, represented in Swift by `Data`.

`Timestamp` is a specific date/time location.
The ``ScalarValue/Timestamp(_:)`` representation uses an `Int64` value to represent the number of milliseconds since epoch (UTC midnight, Jan 1, 1970).

When using `AutomergeEncoder` or `AutomergeDecoder`, these values are converted into the type `Date`.
Be aware that Swift's Date implementation represents timestamps as `Double`, so there is some less of value (sub-second) when writing into Automerge and reading a value back out. 
Be aware that Date values may not be exactly equatable because of this difference. 

`Counter` is another Automerge-specific primitive type that represents a concurrently updated counter.
To update a counter directly within an Automerge document, use the ``Document/increment(obj:key:by:)`` or ``Document/increment(obj:index:by:)`` methods. 
You can explicitly set a counter value, such as an initial value, using ``Document/put(obj:key:value:)`` or ``Document/put(obj:index:value:)``, but using these methods ignores any previously made increments or decrements.
When serialized by `AutomergeDecoder` or `AutomergeEncoder`, the type ``Counter`` represents a counter value.

When you use the `AutomergeEncoder` or `AutomergeDecoder` these follow the rules and conventions for Swift types.
For example, an Automerge document with a list of mixed Integers and Strings would not be decodable by `AutomergeDecoder`, although it is a valid Automerge document.

> Note: It's important to note that Automerge is a cross platform library, and an Automerge document's internal schema is dynamic.
Although not supported by Swift arrays, an Automerge array can contain any other kind of Automerge object or primitive within it.
Likewise dictionaries values can contain any other kind of Automerge object or primitive within it.
When you merge another Automerge document, apply updates from an Automerge, or sync with another document, those updates can change the types of values anywhere within the Automerge document.
This can potentially make the document invalid for Swift types you define and retrieve when you use `AutomergeDecoder`.

### Creating, Reading and Writing a document

If you're not using the encoder and decoder, you need to establish container objects yourself, and add and remove values within them.
The methods are `Document` that support this require that you identify the relevant property for an object.
This is either the parameter `key`, represented by a `String`, in the case of dictionaries, or the parameter `index`, represented by `UInt64`.
For example, use ``Document/get(obj:key:)`` to get a value out of a dictionary and ``Document/get(obj:index:)`` to get a value out of an array. 

Methods that insert an object into the document are separate to those which insert primitive values. For example, ``Document/put(obj:key:value:)`` puts a value into a dictionary, while ``Document/putObject(obj:key:ty:)`` puts an object of the type you specify into the dictionary.
The methods which insert an object return an ``ObjId`` of the newly created object, which you use to modify the contents of the new object. 
See the documentation for ``Document`` for more detail on the individual methods.

### Saving and loading Documents

An Automerge document can be saved using ``Document/save()``. 
This will produce a compressed encoding of the document which is extremely efficient and which can be loaded using ``Document/init(_:logLevel:)``.

Automerge is intentionally agnostic to how you transfer, store, or load the bytes that make up an Automerge document, or updates between documents.
