# ``Automerge/Document``

## Topics

### Creating or loading a document
- ``init()``
- ``init(_:)``

### Creating and modifying values
- ``put(obj:key:value:)``
- ``put(obj:index:value:)``
- ``putObject(obj:key:ty:)``
- ``putObject(obj:index:ty:)``
- ``insertObject(obj:index:ty:)``
- ``increment(obj:key:by:)``
- ``increment(obj:index:by:)``
- ``delete(obj:key:)`` 
- ``delete(obj:index:)``
- ``splice(obj:start:delete:values:)``
- ``spliceText(obj:start:delete:value:)``

### Reading 
- ``get(obj:key:)``
- ``get(obj:index:)``
- ``getAll(obj:key:)``
- ``getAll(obj:index:)``
- ``keys(obj:)``
- ``values(obj:)``
- ``mapEntries(obj:)``
- ``length(obj:)``
- ``text(obj:)``
- ``heads()``

### Reading old values

- ``getAt(obj:key:heads:)``
- ``getAt(obj:index:heads:)``
- ``getAllAt(obj:key:heads:)``
- ``getAllAt(obj:index:heads:)``
- ``keysAt(obj:heads:)``
- ``valuesAt(obj:heads:)``
- ``mapEntriesAt(obj:heads:)``
- ``lengthAt(obj:heads:)``
- ``textAt(obj:heads:)``

### Saving, syncing, forking, and merging

- ``save()``
- ``encodeNewChanges()``
- ``encodeChangesSince(heads:)``
- ``applyEncodedChanges(encoded:)``
- ``applyEncodedChangesWithPatches(encoded:)``
- ``generateSyncMessage(state:)``
- ``receiveSyncMessage(state:message:)``
- ``receiveSyncMessageWithPatches(state:message:)``
- ``fork()``
- ``forkAt(heads:)``
- ``merge(other:)``
- ``mergeWithPatches(other:)``
