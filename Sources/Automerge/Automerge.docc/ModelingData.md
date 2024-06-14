# Using the dynamic schema and core data model

Store into, and read from, an Automerge document.

## Overview

The ``Document`` class provides concurrency-safe access to the Automerge core API and low-level methods to read and write values into an Automerge document.
The dynamic data model within an Automerge document is similar to a JSON document.
Unlike JSON, a `Document` is backed by sets of nested CRDTs, which track the changes made within the data model.
By using CRDTs, a `Document` can be consistently merged with other `Document` in a manner which preserves user intent as much as possible.

### Document-based Model

The Automerge dynamic data model is composed of arrays and string-keyed maps, nested within one another, with the root of the data model a map, represented by ``ObjId/ROOT``.
The data within an Automerge document is composed of nested objects, represented by the enumeration ``Value``.
Objects that contain other objects are have a unique identifier: ``ObjId`` and a type: ``ObjType``.
Like JSON, Automerge includes objects that contain other objects: arrays (``ObjType/List``) and dictionaries (``ObjType/Map``).
Also like JSON, dictionaries in Automerge are keyed only by Strings.

Automerge goes further than JSON when representing a few types.
For example, Automerge includes a special type ``ObjType/Text`` to represent a concurrently editable string, separate from a singular value update of a string, represented by ``ScalarValue/String(_:)``.
The `Text` object type represents the value of the string as a list of unicode scalar values.

### Automerge Document Primitives

Objects within an Automerge document that don't contain other objects are made up of Automerge's primitive types, represented by the enumeration ``ScalarValue``.
Automerge maintains more type information than JSON, representing a number of different types.

| Automerge primitive | Matching Swift type |
| --- | --- |
| null (``ScalarValue/Null``) | `nil` |
| booleans (``ScalarValue/Boolean(_:)``) | `Bool` |
| unsigned integers (``ScalarValue/Uint(_:)``)  | `UInt` |
| signed integers (``ScalarValue/Int(_:)``) | `Int` |
| floating point numbers (``ScalarValue/F64(_:)``) | `Double` |
| strings (``ScalarValue/String(_:)``) | `String` |
| byte arrays (``ScalarValue/Bytes(_:)``) | `Data` |
| timestamps (``ScalarValue/Timestamp(_:)``) | `Date` |
| counters (``ScalarValue/Counter(_:)``) | ``Counter`` |

`Bytes` scalar values are a buffer of bytes, represented in Swift by `Data`.

`Timestamp` is a specific date/time location.
The ``ScalarValue/Timestamp(_:)`` representation uses an `Int64` value to represent the number of seconds since epoch (UTC midnight, Jan 1, 1970).

### Creating and updating the schema within an Automerge document

When using the low level API, you are responsible for creating the nested objects that make up the schema.
The top-level of an Automerge document, represented by ``ObjId/ROOT`` is an object of type ``ObjType/Map``.

When interacting with a ``ObjType/Map`` object, use ``Document/putObject(obj:key:ty:)`` to nest another object.
When you want to add a nested object into a ``ObjType/List``, use ``Document/putObject(obj:index:ty:)``.
The methods that insert an object return an ``ObjId`` of the newly created object, which you use to modify the contents of the new object. 

Automerge supports a special type for collaborative string editing, represented by ``ObjType/Text``.
Use ``Document/updateText(obj:value:)`` or ``Document/spliceText(obj:start:delete:value:)`` to update the text.
Automerge text also supports metadata about the text, represented by ``Mark``.
Use ``Document/mark(obj:start:end:expand:name:value:)`` to set or update a mark across a range of text.

`Counter` is another Automerge-specific primitive type that represents a concurrently updated counter.
To update a counter directly within an Automerge document, use the ``Document/increment(obj:key:by:)`` or ``Document/increment(obj:index:by:)`` methods. 
You can explicitly set a counter value, such as an initial value, using ``Document/put(obj:key:value:)`` or ``Document/put(obj:index:value:)``, but using these methods ignores any previously or concurrently made increments or decrements.

The Automerge-swift package provides a custom encoder and decoder that lets you establish schema that matches to types that conform to Codable.
You can use the encoder to create the nested object schema in an Automerge document.
For more information on using Codable types with the custom encoder and decoder, see <doc:MappingData>.

### Reading from a document

The core API requires you to know what kind of object you're reading from and use the relevant API.
For maps, you'll need the parameter `key`, represented by a `String`.
In the case of dictionaries, or the parameter `index`, represented by `UInt64`.
Use ``Document/get(obj:key:)`` to get a value out of a dictionary and ``Document/get(obj:index:)`` to get a value out of an array. 

See the documentation for ``Document`` for more detail on the individual methods.

### Reading maps

- ``Automerge/Document/get(obj:key:)``
- ``Automerge/Document/getAll(obj:key:)``
- ``Automerge/Document/keys(obj:)``
- ``Automerge/Document/mapEntries(obj:)``
- ``Automerge/Document/length(obj:)``

### Updating maps

- ``Automerge/Document/put(obj:key:value:)``
- ``Automerge/Document/putObject(obj:key:ty:)``
- ``Automerge/Document/delete(obj:key:)`` 

### Reading lists

- ``Automerge/Document/get(obj:index:)``
- ``Automerge/Document/getAll(obj:index:)``
- ``Automerge/Document/values(obj:)``
- ``Automerge/Document/length(obj:)``

### Updating lists

- ``Automerge/Document/insert(obj:index:value:)``
- ``Automerge/Document/insertObject(obj:index:ty:)``
- ``Automerge/Document/put(obj:index:value:)``
- ``Automerge/Document/putObject(obj:index:ty:)``
- ``Automerge/Document/delete(obj:index:)``
- ``Automerge/Document/splice(obj:start:delete:values:)``

### Reading Text

- ``Automerge/Document/text(obj:)``
- ``Automerge/Document/length(obj:)``
- ``Automerge/Document/marks(obj:)``
- ``Automerge/Document/marksAt(obj:position:)``

### Updating Text values

- ``Automerge/Document/spliceText(obj:start:delete:value:)``
- ``Automerge/Document/updateText(obj:value:)``
- ``Automerge/Document/mark(obj:start:end:expand:name:value:)``

### Setting and Reading cursors

- ``Automerge/Document/cursor(obj:position:)``
- ``Automerge/Document/cursorAt(obj:position:heads:)``
- ``Automerge/Document/cursorPosition(obj:cursor:)``
- ``Automerge/Document/cursorPositionAt(obj:cursor:heads:)``

### Updating counters

- ``Automerge/Document/increment(obj:key:by:)``
- ``Automerge/Document/increment(obj:index:by:)``
