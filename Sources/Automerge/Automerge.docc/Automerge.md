# ``Automerge``

Create, Update, and Synchronize data for collaborative applications.

## Overview

Automerge makes it easier to store data for your app locally, update that data independently and asynchronously, and consistently merge updates and changes.

- **Automatic merging** Automerge is a [Conflict-Free Replicated Data Type](https://crdt.tech) (CRDT), which allows concurrent changes on different devices to be merged automatically without requiring any central server.
For more information on the conflict resolution approach, see [Managing Conflicts](https://automerge.org/docs/cookbook/conflicts/) at the [Automerge site](https://automerge.org).

- **Immutable state** An Automerge object is an immutable snapshot of the application state at a point in time. 
When you make a change, or merge in a change from elsewhere, you get a new state object reflecting that change.

- **Network-agnostic** Automerge is a pure data structure library that does not care about networks, protocols, or transports. 
It works with any connection-oriented network protocol, which could be client/server (for example using WebSockets or HTTP), server-hosted peer-to-peer (for example, over WebRTC), or entirely local peer-to-peer (for example, Bonjour).
It also works with unidirectional messaging: you can send an Automerge file as email attachment, or on a USB drive in the mail, and the recipient will be able to merge it with their version.

- **Portable** Originally developed in JavaScript, Automerge runs from a core Rust implementation that compiles to WebAssembly for use with Node.js, Electron, and modern browsers.
The Rust core exposes a C API for consumption within other languages, and is packaged as a static library using an XCFramework for use in iOS and macOS applications.
The Swift Automerge library includes supplemental code to make using Automerge more idiomatic and easier.

## Topics

### Essentials

- ``Automerge/Document``
- <doc:FiveMinuteQuickstart>
- <doc:ExampleAppWalkthrough>

### Reading and Writing Codable Types

- ``Automerge/AutomergeEncoder``
- ``Automerge/AutomergeDecoder``
- ``Automerge/SchemaStrategy``
- ``Automerge/LogVerbosity``
- ``Automerge/AnyCodingKey``

### Automerge Collaborative Types

- ``Automerge/AutomergeText``
- ``Automerge/Mark``
- ``Automerge/ExpandMark``
- ``Automerge/Counter``

### Synchronizing Documents

- <doc:Sync>
- ``Automerge/SyncState``

### Representing Objects and Values

- <doc:ModelingData>
- ``Automerge/ObjType``
- ``Automerge/ObjId``
- ``Automerge/Value``
- ``Automerge/ScalarValue``
- <doc:AddressBookExample>

### Inspecting Documents as Changes

- <doc:ChangesAndHistory>
- ``Automerge/ChangeHash``
- ``Automerge/Patch``
- ``Automerge/PatchAction``
- ``Automerge/PathElement``
- ``Automerge/Prop``
- ``Automerge/DeleteSeq``
- ``Automerge/ActorId``

### Converting Scalar Values to Local Types

- ``Automerge/ScalarValueRepresentable``

### Codable Errors

- ``Automerge/CodingKeyLookupError``
- ``Automerge/PathParseError``

### Document Errors 

- ``Automerge/DecodeSyncStateError``
- ``Automerge/DocError``
- ``Automerge/LoadError``
- ``Automerge/ReceiveSyncError``

### Type Conversion Errors

- ``Automerge/BooleanScalarConversionError``
- ``Automerge/BytesScalarConversionError``
- ``Automerge/CounterScalarConversionError``
- ``Automerge/IntScalarConversionError``
- ``Automerge/FloatingPointScalarConversionError``
- ``Automerge/StringScalarConversionError``
- ``Automerge/TimestampScalarConversionError``
- ``Automerge/UIntScalarConversionError``

