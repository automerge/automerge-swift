# Meeting Notes, a Document-based SwiftUI app using Automerge.

A guided tour of MeetingNotes, a sample iOS and macOS SwiftUI app that uses Automerge for syncing and collaboration.

## Overview

The source for the MeetingNotes app is [available on Github](https://github.com/automerge/MeetingNotes).
The Document-based SwiftUI app illustrates storing and loading a `Codable` model and integrating Automerge backed models with the SwiftUI controls.
The app includes file merging capabilities and interactive peer-to-peer syncing of updates in near real time. 

### Using Automerge in a Document-based app

[MeetingNotesDocument.swift](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/MeetingNotesDocument.swift) contains most of the swift code related to being a Document-based SwiftUI app.

MeetingNotes is a document-based SwiftUI app, meaning that it defines a file type, reads and edits files stored on device, focusing on a document to store relevant information.
The file type that the MeetingNotes defines is defined in the projects Info.plist and in code as a Universal Type Identifier.
In this case, the identifier for the type the app defines is `com.github.automerge.meetingnotes`.
In the project `Info.plist` file, the app exports the type using the file extension `.meetingnotes` and conforms to the more general Uniform Type Identifiers of [`public.content`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype/3551481-content) and [`public.data`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype/3551482-data).

MeetingNotes does not use the raw bytes that an Automerge document provides. 
Instead it wraps those bytes in order to track a unique document identifier that is created with any new document.
This provides MeetingNotes with a convenient way to determine if two documents represent are intended to represent copies of the same document, or if they were generated independently.
While Automerge supports merging any two document structures, the seamless updates of changes between copies relies on the documents having a shared based history.
MeetingNotes uses the document identifier to constrain what Automerge documents it will merge or synchronize.
MeetingNotes uses the Codable struct `WrappedAutomergeDocument` attach the document identifier, and encodes the result using [CBOR encoding](https://cbor.io).
The CBOR encoding and decoding is provided by the dependency [PotentCodables](https://swiftpackageindex.com/outfoxx/PotentCodables).

To integrate with the SwiftUI document-based app structure, MeetingNotes defines `MeetingNotesDocument`, a subclass of [ReferenceFileDocument](https://developer.apple.com/documentation/swiftui/referencefiledocument).

In the new-document initializer (`init()`), MeetingNotes creates a new Automerge document along with a new document identifier to go along with this document.
The initializer goes on to create a new, empty model instance and seeds the schema of the model into Automerge using ``AutomergeEncoder``.

In the read-from-data initializer (`init(configuration: ReadConfiguration)`), MeetingNotes attempts to decode the wrapper from the bytes provided by the system, followed by initializing an Automerge document using the bytes embedded within the wrapped document.
If this process succeeds, the initializer uses ``AutomergeDecoder`` to decode an instance of the model from the Automerge document. 

The required save-the-document method (`snapshot(contentType _: UTType)`) encodes any updates from the model back into the Automerge document.
That, in turn, is used by `fileWrapper(snapshot: Document, configuration _: WriteConfiguration)` to new wrapped document with the updated bytes, and serializes that to provide the final bytes to store on device.

The Document subclass defines two additional helper methods: `storeModelUpdates()` and `getModelUpdates` to provide a convenient interface point for later updates from synchornization, merging files, or updates to from SwiftUI views.

For more information on building document-based app with SwiftUI, see [Building a Document-Based App with SwiftUI](https://developer.apple.com/documentation/swiftui/building_a_document-based_app_with_swiftui).

### Encoding and Decoding the model

The model for the app is defined in [MeetingNotesModel.swift](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/MeetingNotesModel.swift), with the top level of the model exposing a `Codable` struct that includes `title` and a list of `AgendaItem`.
`AgendaItem` is another `Codable` struct that includes it's own `title` and an instance of ``AutomergeText``.

This model illustrates the Codable encoding of both structs and arrays, as well as the special Automerge type `AutomergeText`, which dynamically reads and updates values from ``ObjType/Text`` objects within an Automerge document.
For any updates to the model _other_ than the text updates, the app needs to call `storeModelUpdates()` on the instance of `ModelNotesDocument` to use an AutomergeEncoder to write the updates back into the Automerge ``Document`` instance.    

### Integrating with SwiftUI Controls and Views

The primary content view for the app is provided by [MeetingNotesDocumentView](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/Views/MeetingNotesDocumentView.swift).
This view defines a two-column (list and detail) split view using [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview).

The view contains a reference to the `MeetingNotesDocument` as the property `document`. 
`document` is used in the view to display the overall document title as an editable field: `TextField("Meeting Title", text: $document.model.title)`.
On any updates to that field, the view calls `storeModelUpdates()` on the document and notifies the Undo manager that a change has happened.
The Undo manager isn't used to build up a queue of changes that could be reversed, instead being the means to notify the SwiftUI document-based app framework that a change _has_ occured, so that it can mark the document as dirty.
In the macOS app, this provides a visual affordance to let the person using the app know that the document has been updated and can be saved. In the iOS app, this automatically saves the document.

This main document view also provides a list of each of the `AgendaItem` instances from our model, includes a button to add new, emtpy item, and a contextual menu option to delete an item.

The detail view is provided by [EditableAgendaItemView](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/Views/EditableAgendaItemView.swift).
Like the main document view, it maintains a reference to `MeetingNotesDocument` as the property `document` to write changes back into the Automerge document, and maintains its own `@State` value for the agenda item's title.
The view is also passed a unique, stable identifier for each agenda item, which is used to handle selection from the list view, using `id()` to identify the detail view with it's ID. 

The state of the view is set up using `.onAppear()` and is refreshed when the view sees an update to the Document's objectWillChange publisher.
When the @State value of `agendaTitle` changes, the view writes an updated value back to the Automerge document if the values of the state and document differ.

The discussion property of the agenda item is linked to a binding provided by ``AutomergeText/textBinding()``, the reference to the text instance looked up from the model using the agenda item's identifier.
Each keystroke that updates the discussion is immediately written back to the Automerge document.
By using the `Binding<String>` vended from `AutomergeText` the app directly reads and updates the view from changes to the Automerge document without having to necessarily rebuild the entire view.

Any changes to other parts of model cycle through the encoding and decoding of the entire model from the Automerge document.
While reasonably quick, it isn't quick enough to keep up with concurrent typing of two syncing instances.
By using the reference type of `AutomergeText`, the app gets a notable performance increase when collaboratively editing the `discussion` property of an agenda item while live-syncing with another peer.

### Merging the contents of a copy

The main app view includes a toolbar button displaying [MergeView.swift](https://github.com/automerge/MeetingNotes/blob/main/MeetingNotes/Views/MergeView.swift).
`MergeView` provides a button that uses [`fileImporter`](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:)) to attempt to load another instance of the MeetingNotes document type from device storage.
This button illustrates how to seamlessly merge in updates from a copy made of the original document.

Upon loading the document, it calls the helper method `mergeDocument` on `MeetingNotesDocument` to decode the document identifier, and if identical to the current document, merges any updates using ``Document/merge(other:)``.


### Network Sync

- Sync coordination with a Document-based app
- Bonjour browser, listener
- network connection and sync protocol
- actively syncing
