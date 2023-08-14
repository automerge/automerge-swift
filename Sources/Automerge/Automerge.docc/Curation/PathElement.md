# ``Automerge/PathElement``

## Overview

PathElement is a unique location identifer within an Automerge document. 
An individual element is made up of the property `obj` (an ``ObjId``) and `prop` (a ``Prop``).
An array of `PathElement` provides an Automerge document specific path to tracing to a specific schema location.

An array of `PathElement` is returned by ``Document/path(obj:)``.
Use `stringPath()` on an array of `PathElement` to convert it into a String.
The format of this string is matched to the method ``Document/lookupPath(path:)`` to look up the ``ObjId`` within the Automerge document.

The following code snippet illustrates getting an array of `PathElement` and converting it into a String:
```swift
let doc = Document()
let exampleList = try doc.putObject(obj: ObjId.ROOT, key: "example", ty: .List)
let listItem = try doc.insertObject(obj: exampleList, index: 0, ty: .Map)

let path = try doc.path(obj: listItem)
let stringFromPath = path.stringPath()

print(stringFromPath)
// .example.[0]
```

## Topics

### Inspecting a Path Element

- ``PathElement/obj``
- ``PathElement/prop``
