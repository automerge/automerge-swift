# Tracking Changes and History

Track, inspect, and synchronize the changes within Automerge documents.

## Overview

An Automerge document is a little like a git repository in that it is composed of a graph of changes, each identified by a hash. 
Like a git repository, a point in the history of an Automerge document can be referenced by its hash. 
_Unlike_ a git repository, an Automerge document can have multiple heads for a given point in time, representing a merge of concurrent changes. 

### Heads and change hashes

From time to time you may want to refer to a particular point in the document history. 
For example, you may want to read values as at that point in time, or get the changes since that time.
Use ``Document/heads()`` to obtain the current heads of the document, which returns a set of ``ChangeHash``. 
`Document` includes families of methods that accept `[ChangeHash]` to retrieve values or objects from that point in time.

Unlike git, Automerge does not track additional metadata about the changes over time, such as who contributed any change, or at what time the change was initially created. 

### Forking and Merging

You can create a fork a document using ``Document/fork()``, or ``Document/forkAt(heads:)`` to get a fork of the document at a specific point in time.
Likewise, you can merge one Document into another using ``Document/merge(other:)``, which applies any changes from the other document.

When working with multiple documents, it is important that the documents source with the same shared history, or merges (or sync) may have unpredictable, although consistent, results.
To take full advantage of Automerge's capabilities, work from forks of a single document rather than creating separate Documents, even with the same schema.

### Syncing documents

You can track the changes to documents yourself, using `heads()` to track points in time between documents and sharing the set of changes with the methods``Document/encodeNewChanges()`` and ``Document/encodeChangesSince(heads:)``.
Apply these changes to the receiving document with the ``Document/applyEncodedChanges(encoded:)``.
Use the ``Document/applyEncodedChangesWithPatches(encoded:)`` to apply the changes and get an array of ``Patch`` that represents the detail of what changed.

To make synchronization between two documents easier, Automerge provides a pair of methods that handle tracking the changes and keeping the size of changes needed to synchronize to a minimum.
Use instances of ``SyncState``, which represents the state of a a peer document, along with ``Document/generateSyncMessage(state:)`` and ``Document/receiveSyncMessage(state:message:)`` to synchronize two documents. 
For example, to sync two documents, create a new instance of ``SyncState``, and
generate an initial sync message to send using ``Document/generateSyncMessage(state:)``.
On the receiving side, create another instance of ``SyncState`` and receive the sync message using ``Document/receiveSyncMessage(state:message:)``.
Repeatedly call, in order, `generateSyncMessage` and receive updates with `receiveSyncMessage` until a call to `generateSyncMessage` doesn't return any bytes for a sync message.
At that point, the two documents are fully in sync.

The following code illustrates this process with two instances of `Document` in memory:

```swift
let doc1 = Document()

// ... make changes independently to doc1

let doc2 = doc1.fork()

// ... make changes independently to doc2

let syncState1 = SyncState()
let syncState2 = SyncState()
var quiet = false
while !quiet {
    quiet = true

    if let msg = doc1.generateSyncMessage(state: sync1) {
        quiet = false
        try! doc2.receiveSyncMessage(state: sync2, message: msg)
    }

    if let msg = doc2.generateSyncMessage(state: sync2) {
        quiet = false
        try! doc1.receiveSyncMessage(state: sync1, message: msg)
    }
}
```

### Getting notified of what changed

When you apply changes received from a remote document (or merged from a separate local document) you may want to know what changed within the `Document`, for example to update an app's user interface.
To get this detail, use ``Document/receiveSyncMessageWithPatches(state:message:)``, which operates like `Document/receiveSyncMessage(state:message:)`, and additionally returns an array of patches, represented by the type ``Patch``.

Inspect a patch to see what action Automerge applied by inspecting the ``Patch/action`` property (represented by the enumeration ``PatchAction``).
The property ``Patch/path`` represents the path through the document schema to the element that was updated, represented by an array of ``PathElement``.
`PathElement` has an object Id (``PathElement/obj``) property and a ``PathElement/prop`` property.
`Prop` is an enumeration that represents either a key to a dictionary and it's value, or the index location within an array.
