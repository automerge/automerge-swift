# Importing the Automerge Type in your app

Define the automerge uniform type identifier in your app to share Automerge documents. 

## Overview

This library defines ``Automerge/UniformTypeIdentifiers/UTType/automerge``, a Uniform Type Identifier for the bytes that make up an Automerge document.
The definition is used in the ``Automerge/Document/transferRepresentation`` property of an Automerge document.
You can conform to this type when sharing Automerge documents as on disk representations.

### Defining a type for your file format

The identifier for the `automerge` type is `com.github.automerge`, and the provided type in this library conforms to the type `public.data`.
When defining a type for your app, as described in [Defining file and data types for your app](https://developer.apple.com/documentation/uniformtypeidentifiers/defining_file_and_data_types_for_your_app), you can optionally conform your app to ``Automerge/UniformTypeIdentifiers/UTType/automerge`` if you are using the bytes from ``Automerge/Document/save()`` as the on-disk representation.
If your file format wraps those bytes, then you should provide the type definition independently of the `automerge` type.

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
