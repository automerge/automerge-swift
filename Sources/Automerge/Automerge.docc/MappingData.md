# Synchronizing Automerge Documents

Conveniently synchronize any two documents.

## Overview

You can track the changes to documents yourself, using `heads()` to track points in time in documents, generating changes to apply using the methods``Document/encodeNewChanges()`` and ``Document/encodeChangesSince(heads:)``, and applying the changes with the method ``Document/applyEncodedChanges(encoded:)``.
To make synchronization between two documents easier, Automerge provides a pair of methods that determine and track the changes needed to synchronize any two documents.
Using ``SyncState``, these methods keep the size of changes needed to synchronize to a minimum.

### Mapping Your Types into Automerge


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

- <doc:AutomergeType>

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
