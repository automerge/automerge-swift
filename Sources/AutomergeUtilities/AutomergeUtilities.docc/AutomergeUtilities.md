# ``AutomergeUtilities``

Extensions to the Automerge to support testing and introspection

## Overview

Automerge Utilities extends Automerge's `Document` type to make it easier to parse the dynamic, internal Automerge schema and types.

## Topics

### Inspecting Automerge documents

- ``Automerge/Document/isEmpty()``
- ``Automerge/Document/schema()``
- ``AutomergeUtilities/AutomergeValue``

### Parsing the contents of an Automerge document

- ``Automerge/Document/parseToSchema(_:from:)``

### Comparing the contents of Automerge documents

- ``Automerge/Document/equivalentContents(_:)``

### Debugging Methods

- ``Automerge/Document/walk()``
