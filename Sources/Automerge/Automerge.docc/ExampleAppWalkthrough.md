# Example App Walkthrough

A guided tour of MeetingNotes, an iOS and macOS SwiftUI app that uses Automerge for syncing and collaboration.

## Overview

The source for the MeetingNotes app is [available on Github](https://github.com/automerge/MeetingNotes).
The Document-based SwiftUI app illustrates storing and loading a `Codable` model into Automerge, and integrating that with the SwiftUI document-based app model.
The app also illustrates the seamless file merging capabilities, and interactive peer-to-peer syncing of updates in near real time. 

## Title here

### Using Automerge in a Document-based app

- defining a type
- creating a file wrapper for on-disk storage
- providing a ReferenceFileDocument

### Encoding and Decoding the model

- automerge encoder, decoder
- considerations and types

### Integrating with SwiftUI Controls and Views

- MeetingNotesDocumentView
- EditableAgendaItemView

### Merging the contents of a copy

- the merge

### Network Sync

- Sync coordination with a Document-based app
- Bonjour browser, listener
- network connection and sync protocol
- actively syncing
