# ``Automerge/AutomergeDecoder``

## Overview

Use `AutomergeDecoder` to decode your data from an Automerge document.

The following example illustrates decoding `ColorList`, a type that conforms to `Codable`, into an Automerge document:
```swift
struct ColorList: Codable {
    var colors: [String]
}

let decoder = AutomergeDecoder(doc: doc)
myColors = try decoder.decode(ColorList.self)
```

## Topics

### Creating a Decoder

- ``init(doc:)``

### Decoding

- ``decode(_:)``
- ``decode(_:from:)``

### Inspecting a Decoder

- ``doc``
- ``userInfo``
