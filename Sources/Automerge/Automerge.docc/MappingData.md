# Storing and loading your types in Automerge documents

Conveniently read or write Codable types in Automerge documents.

## Overview

A type that conforms to the [Codable](https://developer.apple.com/documentation/swift/codable) protocol can be stored and retrieved from a Document using ``AutomergeEncoder`` and ``AutomergeDecoder``.
This pair of classes creates and validates schema within your ``Document``, as well as store and load the content into your `Codable` types.
The following snippet creates a new Automerge document, and an encoder to write into that document:

```swift
import Automerge
let doc = Document()
let automergeEncoder = AutomergeEncoder(doc: doc)
```

A new document is empty, containing no data or schema. 
When you encode into the document, the default behavior establishes a document model that matches the codable representation of your type.
If the document already has a document model encoded within it, and it doesn't match the type you encode or decode, the encoder or decoder throws an error.
The following example uses the encoder created above to encode a simple struct the document:

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

The matching `AutomergeDecoder` lets you decode from an Automerge document:

```swift
let automergeDecoder = AutomergeDecoder(doc: doc)
let decodedStruct = try automergeDecoder.decode(Note.self)
print(decodedStruct)
// Note(created: 2023-08-01 23:28:38 +0000, notes: "An example string to show encoding.")
```

### Using the Encoder/Decoder

When you use the `AutomergeEncoder` or `AutomergeDecoder`, they convert your types and stored properties into either objects or the closest equivalent Automerge primitive type.
For a list of the primitive data types that Automerge supports, see <doc:ModelingData>.

While the Automerge schema is dynamic, Swift types don't support mixing different types within arrays or dictionaries. 
The encoder and decoder follows the conventions for Swift types, and throws errors if the current schema doesn't match when you use the encoder or decoder.
For example, an Automerge document with a list of mixed Integers and Strings would not be decodable by `AutomergeDecoder`, although it is a valid Automerge document.

The Automerge internal representation of `Date` is represented by a seconds timestamp. 
When you use the encoder to write a `Date` value, the Swift representation is converted to Automerge's internal type, which is number of seconds since 1970 in UTC.
Swift's Date represents timestamps as `Double`, as such there is some loss of granularity (sub-seconds are lost) when writing into Automerge and reading a value back out.
Be aware that because of this loss, `Date` values may not be directly equatable because of this difference.

This library provides two reference types for concurrently updated values: ``AutomergeText`` and ``Counter``:

- ``AutomergeText`` is a class that presents a concurrently updated String. 
`AutomergeText` maintains a reference to a document, the text's location in the document schema, presents values from Automerge directly, and writes updates directly into the Automerge document.

- ``Counter`` is a class that represents a concurrently updated counter.

> Note: It's important to note that Automerge is a cross platform library, and the Automerge document schema is dynamic.
Although not supported by Swift arrays, an Automerge array or dictionary can contain any other kind of Automerge object or primitive within it.
When you merge another Automerge document, apply updates from an Automerge, or sync with another document, those updates can change not only the values, but also the schema of the Automerge document.
This can potentially make the document invalid for the Swift types you define when you use `AutomergeDecoder`.

### Tradeoffs between the core API and using Codable to interact with Automerge

Using `AutomergeEncoder` and `AutomergeDecoder` is easy, but is not always efficient.

When you write into an Automerge document using the encoder, the `Codable` protocol recursively iterates through all of the stored properties and types, updating the Automerge document in an equivalent schema location.
This process is not necessarily fast, and the speed can be noticeable, or actively detrimental, if you are making (or receiving) rapid updates, encoding or decoding lots of data, or both.

If performance is an issue, you may find it useful to create your own classes that proxy into Automerge, so that small changes in your data model doesn't require iterating through everything.
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
