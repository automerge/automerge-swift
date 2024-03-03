# Mapping your types into Automerge documents

Conveniently read or write any types that conform to Codable with an Automerge document.

## Overview

Any type that supports the [Codable](https://developer.apple.com/documentation/swift/codable) protocol can be stored and retrieved from a Document using the ``AutomergeEncoder`` and ``AutomergeDecoder``.
This encoder and decoder pair do the work to establish schema within your ``Document``, as well as store and load the content into your `Codable` types.
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

### Using the Encoder/Decoder

The `AutomergeEncoder` and `AutomergeDecoder` convert existing Swift types that conform to `Codable` into and out of Automerge primitives types, and establish the relevant schema within an Automerge document if it doesn't already exist.
When you use the `AutomergeEncoder` or `AutomergeDecoder`, they convert your types into either objects or the closest equivalent Automerge primitive type.
For a list of the primitive data types that Automerge supports, see <doc:ModelingData>.

Note that while the Automerge schema is dynamic, swift types don't support mixing different types within arrays or dictionaries. 
The encoder and decoder follow the rules and conventions for Swift types, and will throw errors if the dynamic schema doesn't match.
For example, an Automerge document with a list of mixed Integers and Strings would not be decodable by `AutomergeDecoder`, although it is a valid Automerge document.

The Automerge internal representation of `Date` is represented by a seconds timestamp. When you using the encoder to write a `Date` value, the Swift representation is converted to Automerge's internal type.
Swift's Date implementation represents timestamps as `Double`, as such there is some loss of granularity (sub-seconds are lost) when writing into Automerge and reading a value back out.
Be aware that because of this loss, `Date` values may not be directly equatable because of this difference.

This library provides two reference types for concurrently updated values: ``AutomergeText`` and ``Counter``:

- ``AutomergeText`` is a class that presents a concurrently updated String. 
It maintains its reference to a document and its location within it, and dynamically reads and writes data into Automerge as its value is updated.

- ``Counter`` is a class that represents a concurrently updated counter.

> Note: It's important to note that Automerge is a cross platform library, and an Automerge document's internal schema is dynamic.
Although not supported by Swift arrays, an Automerge array can contain any other kind of Automerge object or primitive within it.
Likewise dictionaries values can contain any other kind of Automerge object or primitive within it.
When you merge another Automerge document, apply updates from an Automerge, or sync with another document, those updates can change the types of values anywhere within the Automerge document.
This can potentially make the document invalid for Swift types you define and retrieve when you use `AutomergeDecoder`.

### Tradeoffs between the core API and using Codable to interact with Automerge

Using `AutomergeEncoder` and `AutomergeDecoder` is easy, but is not always efficient.
When you write into an Automerge document using the encoder, the way the `Codable` protocol works is by recursively iterating through all of the stored properties and types, updating the Automerge document in an equivalent schema location.
This process is not necessarily fast, and the speed can be noticeable, or actively detrimental, if you are making (or receiving) rapid updates, encoding or decoding lots of data, or both.

You may find it useful to create your own classes that read and write directly into Automerge, so that small changes in your data model don't require iterating through all of your data model.
See <doc:ModelingData> for details on the core Automerge API and the low level types and the methods in ``Document`` for reading and writing into the data model directly.

### Reading and Writing Codable Types

- ``Automerge/AutomergeEncoder``
- ``Automerge/AutomergeDecoder``
- ``Automerge/SchemaStrategy``
- ``Automerge/LogVerbosity``
- ``Automerge/AnyCodingKey``

### Collaborating with Text

- ``Automerge/AutomergeText``

### Collaborating with Text

- ``Automerge/Counter``

### Converting Scalar Values to Local Types

- ``Automerge/ScalarValueRepresentable``

### Codable Errors

- ``Automerge/CodingKeyLookupError``
- ``Automerge/PathParseError``
- ``Automerge/BindingError``
