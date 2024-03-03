# ``Automerge``

Create, Update, and Synchronize data for collaborative applications.

## Overview

Automerge makes it easier to store data for your app locally, update that data independently and asynchronously, and consistently merge updates and changes.

- **Seamless, consistent merging** Automerge is a [Conflict-Free Replicated Data Type](https://crdt.tech) (CRDT), which allows concurrent changes on different devices to be merged automatically without requiring any central server.
For more information on the conflict resolution approach, see [Managing Conflicts](https://automerge.org/docs/cookbook/conflicts/) at the [Automerge site](https://automerge.org).

- **Immutable state** Automerge provides an immutable snapshot of the application state at a point in time.
As you make changes to a Automerge document, or merge in changes from elsewhere, the document collects and organizes those changes. 
Read <doc:ChangesAndHistory> for more information about accessing that history.

- **Network-agnostic** Automerge is a pure data structure library that does not care about networks, protocols, or transports.

- **Portable** Originally developed in JavaScript, Automerge uses [a core library written](http://github.com/automerge/automerge) in the Rust language.
Automerge runs on Node.js, Electron, and modern browsers using the core library compiled to WebAssembly.
The Rust library exposes a C API for use with other languages. 
The core is packaged as a static library within an XCFramework for use on Apple platforms.

### API Layers

- The lowest layer lets you interact with the Automerge document, its history, and the dynamic data schema stored within a document.
For more information on the core API layer, read <doc:ModelingData> and <doc:ChangesAndHistory>, and the methods exposed on ``Automerge/Document``.

- At a higher layer, this package provides a custom encoder and decoder that you can use to map Codable data types into the dynamic Automerge schema.
For more information on the Codable layer, read <doc:MappingData> 

- This package provides Transferrable conformation for Automerge documents and defines Uniform Type Identifiers that you can use in your app to load, save, or share Automerge documents. 
Read <doc:AutomergeDataType> for more information on the data types and saving an Automerge document directly.

- A separate module, `AutomergeUtilities`, provides additional utility methods to assist with debugging your app when using Automerge, and convenience methods to walk and parse an Automerge document's internal schema.

Read <doc:FiveMinuteQuickstart> to get a quick taste of how to use Automerge, or [Meeting Notes, a Document-based SwiftUI app using Automerge](https://automerge.org/MeetingNotes/documentation/meetingnotes/appwalkthrough/) for a walk-through that illustrates how to use Automerge within a demonstration app.

## Topics

### Essentials

- ``Automerge/Document``
- <doc:FiveMinuteQuickstart>
- <doc:AutomergeDataType>

### Reading and Writing Codable Types

- <doc:MappingData>
- ``Automerge/AutomergeEncoder``
- ``Automerge/AutomergeDecoder``
- ``Automerge/SchemaStrategy``
- ``Automerge/LogVerbosity``
- ``Automerge/AnyCodingKey``

### Representing Objects and Values in a Document

- <doc:ModelingData>
- ``Automerge/ObjType``
- ``Automerge/ObjId``
- ``Automerge/Value``
- ``Automerge/ScalarValue``
- <doc:AddressBookExample>

### Collaborating with Text

- ``Automerge/AutomergeText``
- ``Automerge/Cursor``
- ``Automerge/Mark``
- ``Automerge/ExpandMark``

### Collaborating with Counters

- ``Automerge/Counter``

### Synchronizing Documents

- <doc:Sync>
- ``Automerge/SyncState``

### Inspecting Document History and Changes

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
- ``Automerge/BindingError``

### Document Errors 

- ``Automerge/DecodeSyncStateError``
- ``Automerge/DocError``
- ``Automerge/LoadError``
- ``Automerge/ReceiveSyncError``

### Type Conversion Errors

- ``Automerge/BooleanScalarConversionError``
- ``Automerge/BytesScalarConversionError``
- ``Automerge/IntScalarConversionError``
- ``Automerge/FloatingPointScalarConversionError``
- ``Automerge/StringScalarConversionError``
- ``Automerge/TimestampScalarConversionError``
- ``Automerge/UIntScalarConversionError``

