# Synchronizing Automerge Documents

Synchronize any Automerge documents to seamlessly share and merge changes.

## Overview

You can track the changes to documents yourself, using `heads()` to track points in time in documents, generating changes to apply using the methods``Document/encodeNewChanges()`` and ``Document/encodeChangesSince(heads:)``, and applying the changes with the method ``Document/applyEncodedChanges(encoded:)``.
To make synchronization between two documents easier, Automerge provides a pair of methods that determine and track the changes needed to synchronize any two documents.
Using ``SyncState``, these methods keep the size of changes needed to synchronize to a minimum.

### Syncing documents

Create an instance of ``SyncState``, which represents the state of a a peer document, to start the process.
Use ``Document/generateSyncMessage(state:)`` to update the initial sync state and generate an initial sync message to send to the another document.
When receiving a sync state message, use ``Document/receiveSyncMessage(state:message:)`` to apply the patches (if any) and update the sync state tracked in `SyncState`.

For example, to sync two documents, create a new instance of `SyncState` for each document.
Start the sync process by calling `generateSyncMessage(state:)` to generate an initial sync message and send this message to the other document.

On the receiving side, receive the sync message using `receiveSyncMessage(state:message:)` to receive and apply any patches and update the sync state.
When ever you receive a sync message, attempt to generate a return sync message with `generateSyncMessage(state:)`.

Repeated this process until a call to `generateSyncMessage` doesn't return any bytes for a sync message.
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
