# Modeling Data with Automerge

Summary sentence of article.

## Overview

Overview here

### Document-based Model

The central data type of Automerge is a ``Document`` which presents a data model somewhat similar to JSON, with string keyed maps and sequences which can be nested within one another. 
Unlike JSON a ``Document`` is a CRDT which means it can be merged with any other ``Document`` in a manner which preserves user intent as much as possible. 
This means that when you have multiple users (or even just multiple devices for one user) working on the same data you can synchronise their changes without necessarily needing a central server.

Being able to merge changes is not much use without some way to transfer changes to other peers. 
You can send the entire document to other devices (and this will be compact and often a good workflow), but Automerge also provides a sync protocol for efficiently getting in sync and staying in sync, which may be more appropriate for real-time collaborative applications and/or applications with very large data sets.

As a developer then you will likely have two concerns:

1. Creating, modifying, and reading data in a ``Document``
2. Saving, loading, and synchronising documents with other devices

We'll get to those in a second, but first let's introduce the data model.

> Note: This library provides a fairly low level interface to Automerge documents. 
There are no mappings from complex swift datatypes like structs or classees to the structure of the Automerge document. 
It is intended that such higher level wrappers be built on top of this one as separate libraries.

### Automerge Document Primitives

Automerge documents are composed of "objects" - which are composite data structures like a map or a list - and primitive values like booleans and numbers. 
Objects have an ``ObjId``, which is used to refer to them when making changes to them. 
Every Automerge document starts with the "root" object, which is a map identified by ``ObjId/ROOT``. 
The data model (which is represeented in this library by the ``Value`` enum), is the following:

* Objects (``ObjType``):
    * Maps (``ObjType/Map``): string keyed maps
    * Lists (``ObjType/List``): sequences of other Automerge values
    * Text (``ObjType/Text``): sequences of unicode characters
* Primitive values (``ScalarValue``)
    * byte arrays (``ScalarValue/Bytes(_:)``)
    * strings (``ScalarValue/String(_:)``)
    * unsigned integers (``ScalarValue/Uint(_:)``)
    * signed integers (``ScalarValue/Int(_:)``)
    * floating point numbers (``ScalarValue/F64(_:)``)
    * counters (``ScalarValue/Counter(_:)``)
    * timestamps (``ScalarValue/Timestamp(_:)``)
    * booleans (``ScalarValue/Boolean(_:)``)
    * null (``ScalarValue/Null``)

### Creating, Reading and Writing a document

Most operations you perform on a document require that you identify a property of an object. 
This is either a key of a map, or an index in a sequence. 
This is represented by overloaded functions which accept either a `key:` parameter or an `index:` parameter. 
For example, ``Document/get(obj:key:)`` to get a value out of a map and ``Document/get(obj:index:)`` to get a value out of a list. 

Methods which insert an object into the document are separate to those which insert primitive values (see ``Document/put(obj:key:value:)`` vs ``Document/putObject(obj:key:ty:)``). 
This is because methods which insert an object return the ``ObjId`` of the newly created object which can then be used to modify the contents of the new object. 
See the documentation of ``Document`` for more details on the individual methods.

### Heads and change hashes

An Automerge document is a little like a git repository in that it is composed of a graph of changes which are identified by a hash. 
This means that like a git repository a point in the history of an Automerge document can be referenced by its hash. _unlike_ a git repository an Automerge document can have multiple heads for a given point in time, representing a merge of concurrent changes. 

From time to time you may want to refer to a particular point in the document history - to read values as at that point, or to get the changes since that time. 
``Document/heads()`` can be used to obtain the current heads of the document, and there are families of methods on document which accept `Array[ChangeHash]` (which is returned by ``Document/heads()``).

### Getting notified of remote changes

When you apply changes received from a remote document (or merged from a separate local document) you may need to know what changed as a result of those changes so that you can update your UI. 
Any document method which accepts remote changes has a `*WithPatches` variant which returns an array of ``Patch``es, representing the change.

### Saving, loading, and syncing

An Automerge document can be saved using ``Document/save()``. 
This will produce a compressed encoding of the document which is extremely efficient and which can be loaded using ``Document/init(_:logLevel:)``. 
In many cases you know that the other end already has some set of changes and you just want to send "new" changes. 
You can obtain these changes using ``Document/encodeNewChanges()`` and ``Document/encodeChangesSince(heads:)``. 
On the other end of the wire you can apply changes using ``Document/applyEncodedChanges(encoded:)``.

As well as these options Automerge also offers a sync protocol. 
The sync protocol is intended to be run over a reliable in-order connection between two peers. 
To use the sync protocol you instantiate a ``SyncState`` representing the peer you are connecting with and then generate messages to send to them using ``Document/generateSyncMessage(state:)`` and receive messages from them using ``Document/receiveSyncMessage(state:message:)``.


