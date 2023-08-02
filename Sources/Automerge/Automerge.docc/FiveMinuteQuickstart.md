# Five Minute Quick Start

Summary sentence of article.

## Overview

Overview here

### Creating a Document

```swift
struct ColorList {
  var colors: [String]
}

import Automerge
let doc = Document
let encoder = AutomergeEncoder(doc: doc)

var myColors = ColorList(colors: ["blue", "red])
encoder.encode(myColors)
```

```
let bytesToStore = doc.save()
```


### Making Changes

```swift
myColors.colors.append("green")
encoder.encode(myColors)
```


### Forking and Merging Documents

```swift
let doc2 = doc.fork()
```

or 

```swift
let doc2 = Document(bytesToStore)
let decoder2 = AutomergeDecoder(doc: doc2)
var otherColorList = decoder2.decode(ColorList.self)

otherColorList.colors.removeFirst()
```


```swift
doc.merge(doc2)
```
