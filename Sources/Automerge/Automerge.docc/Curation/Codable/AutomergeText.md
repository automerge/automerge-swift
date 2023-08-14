# ``Automerge/AutomergeText``

## Overview

AutomergeText is a reference type that points to a ``ObjType/Text`` object within an Automerge document.
Use ``AutomergeDecoder`` to return this type within your data model.

You can create an initialize a Text object by creating an instance, then calling ``bind(doc:path:)`` with the location to link it into an Automerge document.
You can also use the ``init(doc:objId:)`` initializer to get an instance directly.

You don't need to decode new instances to get updated values for Text objects within an Automerge document after syncing or merging. 
Use the ``value`` property to get the latest value from the Automerge document, or set an updated value using the same property.
Use ``textBinding()`` to vend an instance of `Binding<String>` to use with SwiftUI text input controls.

## Topics

### Creating AutomergeText

- ``init(_:)``
- ``init(_:doc:path:)``
- ``init(doc:objId:)``

### Linking a new AutomergeText into an Automerge Document

- ``bind(doc:path:)``

### Retrieving a binding for the text

- ``textBinding()``

### Inspecting an AutomergeText instance

- ``isBound``
- ``value``

### Encoding and Decoding AutomergeText

- ``encode(to:)``
- ``init(from:)``
