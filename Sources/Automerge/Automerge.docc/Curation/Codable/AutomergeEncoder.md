# ``Automerge/AutomergeEncoder``

## Overview

Use `AutomergeEncoder` to encode your data into an Automerge document.

The following example illustrates encoding `ColorList`, a type that conforms to `Codable`, into an Automerge document:
```swift
struct ColorList: Codable {
    var colors: [String]
}

let doc = Document()
let encoder = AutomergeEncoder(doc: doc)

var myColors = ColorList(colors: ["blue", "red"])
try encoder.encode(myColors)
```

To support cross-platform usage, when provided a optional type to encode, the encoder writes a
``ScalarValue/Null`` into the Document as opposed to not creating the relevant entry in a map or list.

## Topics

### Creating an Encoder

- ``init(doc:strategy:cautiousWrite:reportingLoglevel:)``
- ``SchemaStrategy``
- ``LogVerbosity``

### Encoding

- ``encode(_:)-3sde1``
- ``encode(_:)-7gbuh``
- ``encode(_:at:)``

### Inspecting an Encoder

- ``doc``
- ``schemaStrategy``
- ``cautiousWrite``
- ``logLevel``
- ``userInfo``
