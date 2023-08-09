# Five Minute Quick Start

A quick-start guide on how to use Automerge for your iOS or macOS app. 

## Overview

Use an Automerge document to store and merge changes to the types you sync between apps.
You can store individuals values or entire models within Automerge.
You can store and retrieve any model that conforms to the [Codable protocol](https://developer.apple.com/documentation/swift/codable) into an Automerge document. 

For example, the following code illustrates the model `ColorList` that we use in this quick start.
```swift
struct ColorList: Codable {
    var colors: [String]
}
```

See <doc:ModelingData> for more details of the types that Automerge stores, and how they are exposed to Swift. 

### Creating a Document

Create an Automerge document to store the model.
The following example creates a new Automerge ``Document`` instance and uses ``AutomergeEncoder`` to store an instance of the model into the document:

```swift
import Automerge
let doc = Document()
let encoder = AutomergeEncoder(doc: doc)

var myColors = ColorList(colors: ["blue", "red"])
try encoder.encode(myColors)
```

These bytes represent the entire model, and its history of updates.

### Making Changes

As you make changes to your model, you can store those changes into the Automerge document by encoding the updated model:

```swift
myColors.colors.append("green")
try encoder.encode(myColors)

print(myColors.colors)
// ["blue", "red", "green"]
```

You can do this once with all your updates, or repeatedly with many updates.
Automerge treats all the changes you make as happening concurrently up until you save the document using ``Document/save()``.
Saving the document compacts all the recent concurrent changes.

See the article <doc:ChangesAndHistory> for more information about tracking changes and more compact ways to synchronise document updates. 


### Saving the Document

In addition to compacting changes to an Automerge document, ``Document/save()`` returns the entire document as a series of bytes (`Data`) that you can store locally or send over a network:
```
let bytesToStore = doc.save()
```

### Forking and Merging Documents

Use ``Document/init(_:logLevel:)`` to load the bytes of an Automerge document, which creates a copy of the document:

```swift
let doc2 = try Document(bytesToStore)
```

You can also use the ``Document/fork()`` to make a copy of the document in memory, without having the store and re-load the bytes:

```swift
let doc3 = doc.fork()
```

With the copy of the document, use ``AutomergeDecoder`` to create an instance of your stored model:

```swift
let doc2decoder = AutomergeDecoder(doc: doc2)
var copyOfColorList = try doc2decoder.decode(ColorList.self)
```

You can then make changes to your model and encode those changes into the Automerge document.

```swift
copyOfColorList.colors.removeFirst()
let doc2encoder = AutomergeEncoder(doc: doc2)
try doc2encoder.encode(copyOfColorList)
```

Use the ``Document/merge(other:)`` to merge changes made in the second document back into the first:

```swift
try doc.merge(doc2)
```

Use `AutomergeDecoder` to update your model from the Automerge document:
```swift
let decoder = AutomergeDecoder(doc: doc)
myColors = try decoder.decode(ColorList.self)

print(myColors.colors)
// ["red", "green"]
```
