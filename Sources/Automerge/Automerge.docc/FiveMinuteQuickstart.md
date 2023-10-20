# Five Minute Quick Start

A quick-start guide on how to use Automerge for your iOS or macOS app. 

## Overview

Use an Automerge document to store and merge changes to the data.
You can store individuals values or entire models within Automerge.
Encode and decide any model that conforms to the [Codable protocol](https://developer.apple.com/documentation/swift/codable) into an Automerge document. 

For example, the following code illustrates the model `ColorList`, that conforms to `Codable`, for this quick start:

```swift
struct ColorList: Codable {
    var colors: [String]
}
```

See <doc:ModelingData> for more details on the types that Automerge stores and how the library exposes those types in Swift. 

### Add Automerge-swift as a dependency

If you're working with a Swift package, add Automerge-swift as a dependency to Package.swift:

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/automerge/automerge-swift.git", from: "0.5.2")
    ],
    targets: [
        .executableTarget(
            ...
            dependencies: [.product(name: "Automerge", package: "automerge-swift")],
            ...
        )
    ]
)
```

If you're working with an Xcode project, search for the swift package using the repository URL
`github.com/automerge/automerge-swift` to add it as a dependency to iOS, macOS, or macCatalyst targets.

### Creating a Document

The following example creates a new Automerge ``Document`` instance and uses ``AutomergeEncoder`` to store an instance of the `ColorList` model into it:

```swift
import Automerge
let doc = Document()
let encoder = AutomergeEncoder(doc: doc)

var myColors = ColorList(colors: ["blue", "red"])
try encoder.encode(myColors)
```

### Making Changes

As you make changes, store them into the Automerge document by encoding the updated model:

```swift
myColors.colors.append("green")
try encoder.encode(myColors)

print(myColors.colors)
// ["blue", "red", "green"]
```

Automerge treats the changes you make as concurrent up until you save the document using ``Document/save()``.
Saving the document compacts all the recent concurrent changes.

See <doc:ChangesAndHistory> for more information about tracking changes and a more compact way to synchronise document updates. 

### Saving the Document

In addition to compacting changes to an Automerge document, ``Document/save()`` returns the entire document as a series of bytes (`Data`) that you can store locally or send over a network:
```
let bytesToStore = doc.save()
```

These bytes represent the entire document model stored in `Document` and its history of updates.

### Forking and Merging Documents

Use ``Document/init(_:logLevel:)`` to load the bytes of an Automerge document, to create a copy of the document:

```swift
let doc2 = try Document(bytesToStore)
```

You can also use the ``Document/fork()`` to make a copy of the document in memory, without needing to store and re-load the bytes:

```swift
let doc3 = doc.fork()
```

With a copy of the document, create an instance of ``AutomergeDecoder`` to retrieve and decode an instance of your model:

```swift
let doc2decoder = AutomergeDecoder(doc: doc2)
var copyOfColorList = try doc2decoder.decode(ColorList.self)
```

You can then make changes to your model and encode those changes into the Automerge document to store the updates.

```swift
copyOfColorList.colors.removeFirst()
let doc2encoder = AutomergeEncoder(doc: doc2)
try doc2encoder.encode(copyOfColorList)
```

Use the ``Document/merge(other:)`` to merge changes made in the copy of the document back into the initial document:

```swift
try doc.merge(doc2)
```

Create an instance of `AutomergeDecoder` to decode and retrieve an instance of your model that reflects the updates stored in the Automerge document:

```swift
let decoder = AutomergeDecoder(doc: doc)
myColors = try decoder.decode(ColorList.self)

print(myColors.colors)
// ["red", "green"]
```
