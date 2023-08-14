# ``Automerge/ObjId``

## Overview

An object identifier represents a unique object within an Automerge document.
Use ``Document/lookupPath(path:)`` to look up an existing object id.

More frequently, methods that add objects to an Automerge Document return an the object Id that references the object added. For example ``Document/putObject(obj:key:ty:)`` adds an object into an existing dictionary, and ``Document/putObject(obj:index:ty:)`` adds an object into an existing list.

## Topics

### Built-in Object Ids

- ``ROOT``
    
