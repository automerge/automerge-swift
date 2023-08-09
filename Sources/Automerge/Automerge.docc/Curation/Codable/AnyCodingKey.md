# ``Automerge/AnyCodingKey``

## Overview

This type conforms to the `CodingKey` protocol to provide a general way to represent the path elements to a location within a document schema.
Create the path elements individually, or use the method ``AnyCodingKey/parsePath(_:)`` to convert a string into a series of path elements that can be used to identify a specific location within an Automerge document.

The following example converts the string `"example.[0].name"` to a path: 

```swift
try AnyCodingKey.parsePath("example.[0].name"))
```

The resulting path, `[example, [0], name]` represents: 
- The key 'example' in the ``ROOT`` dictionary.
  - The first (index 0) element of the list, referenced above.
    - The value or object at the key `name` in the element reference above.

Encode a type to this location with ``AutomergeEncoder/encode(_:at:)`` or decode a type from this location with ``AutomergeDecoder/decode(_:from:)``.

The same string path format is used in ``Document/lookupPath(path:)`` to look up the ``ObjId`` of a location within an Automerge document.

## Topics

### Creating an AnyCodingKey

- ``AnyCodingKey/init(_:)-lfcr``
- ``AnyCodingKey/init(_:)-6faed``
- ``AnyCodingKey/init(_:)-5azuh``
- ``AnyCodingKey/ROOT``

### Converting Automerge types into AnyCodingKey

- ``AnyCodingKey/init(_:)-uo0``
- ``AnyCodingKey/init(_:)-6lrn3``

### Parsing a string into a path of AnyCodingKey

- ``AnyCodingKey/parsePath(_:)``
