# Saving, loading, and sharing Automerge documents as Data

Define the Automerge uniform type identifier in your app to share Automerge documents. 

## Overview

This library defines the Uniform Type Identifier ``Automerge/UniformTypeIdentifiers/UTType/automerge``  for the bytes that make up an Automerge document.
This type is used in the ``Automerge/Document/transferRepresentation`` property of an Automerge document, to conform Automerge documents to the [Transferable protocol](https://developer.apple.com/documentation/coretransferable/transferable).

### Defining a type for your file format

The identifier for the `automerge` type is `com.github.automerge`, and the provided type conforms to the type `public.data`.
When defining a type for your app, as described in [Defining file and data types for your app](https://developer.apple.com/documentation/uniformtypeidentifiers/defining_file_and_data_types_for_your_app), you may conform your own app's type to ``Automerge/UniformTypeIdentifiers/UTType/automerge`` if you are using the bytes from ``Automerge/Document/save()`` as the on-disk representation.
If your file format wraps those bytes, then provide your own type definition that does not conform to the `automerge` type.

If you use the `automerge` type directly, define the type as an imported type within the `Info.plist` file for your app.
The details are most easily updated in the Imported Type Definitions panel of the Info panel for your app's target in Xcode.

- term Description: `Automerge document`
- term Identifier: `com.github.automerge`
- term Conforms To: `public.data`
- term Reference URL: `https://automerge.org/`

If you are editing the `Info.plist` file directly, the following stanza reflects a single imported type declaration declaring this type:

```plist
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.data</string>
        </array>
        <key>UTTypeDescription</key>
        <string>Automerge document</string>
        <key>UTTypeIcons</key>
        <dict/>
            <key>UTTypeIdentifier</key>
            <string>com.github.automerge</string>
            <key>UTTypeReferenceURL</key>
            <string>https://automerge.org/</string>
            <key>UTTypeTagSpecification</key>
        <dict/>
    </dict>
</array>
```

### Saving and loading Documents

Use ``Document/save()`` to generate `Data` that represents a compacted version of the Automerge document.
Calling `save` collapses concurrent changes applied since the last save, or when the document was loaded.
The compressed encoding of the document which is efficient and can be used to initialize an Automerge document with ``Document/init(_:logLevel:)``.

The Automerge core library is intentionally agnostic to how you transfer, store, or load the bytes that make up an Automerge document, or updates between documents.

