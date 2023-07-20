# ``Automerge/Document``

## Topics

### Creating or loading a document

- ``init(logLevel:)``
- ``init(_:logLevel:)``

### Inspecting Documents

- ``actor``
- ``ActorId``
- ``objectType(obj:)``
- ``path(obj:)``
- ``lookupPath(path:)``

### Reading maps

- ``get(obj:key:)``
- ``getAll(obj:key:)``
- ``keys(obj:)``
- ``mapEntries(obj:)``
- ``length(obj:)``

### Updating maps

- ``put(obj:key:value:)``
- ``putObject(obj:key:ty:)``
- ``delete(obj:key:)`` 

### Reading lists

- ``get(obj:index:)``
- ``getAll(obj:index:)``
- ``values(obj:)``
- ``length(obj:)``

### Updating lists

- ``insert(obj:index:value:)``
- ``insertObject(obj:index:ty:)``
- ``put(obj:index:value:)``
- ``putObject(obj:index:ty:)``
- ``delete(obj:index:)``
- ``splice(obj:start:delete:values:)``

### Reading Text

- ``text(obj:)``
- ``length(obj:)``
- ``marks(obj:)``

### Updating Text values

- ``spliceText(obj:start:delete:value:)``
- ``mark(obj:start:end:expand:name:value:)``

### Updating counters

- ``increment(obj:key:by:)``
- ``increment(obj:index:by:)``

### Reading a document's history

- ``heads()``

### Reading historical map values

- ``getAt(obj:key:heads:)``
- ``getAllAt(obj:key:heads:)``
- ``keysAt(obj:heads:)``
- ``valuesAt(obj:heads:)``
- ``mapEntriesAt(obj:heads:)``
- ``lengthAt(obj:heads:)``

### Reading historical list values

- ``getAt(obj:index:heads:)``
- ``getAllAt(obj:index:heads:)``
- ``valuesAt(obj:heads:)``
- ``lengthAt(obj:heads:)``

### Reading historical text values

- ``textAt(obj:heads:)``
- ``lengthAt(obj:heads:)``
- ``marksAt(obj:heads:)``

### Saving, forking, and merging documents

- ``save()``
- ``encodeNewChanges()``
- ``encodeChangesSince(heads:)``
- ``applyEncodedChanges(encoded:)``
- ``applyEncodedChangesWithPatches(encoded:)``
- ``fork()``
- ``forkAt(heads:)``
- ``merge(other:)``
- ``mergeWithPatches(other:)``

### Syncing documents

- ``generateSyncMessage(state:)``
- ``receiveSyncMessage(state:message:)``
- ``receiveSyncMessageWithPatches(state:message:)``
