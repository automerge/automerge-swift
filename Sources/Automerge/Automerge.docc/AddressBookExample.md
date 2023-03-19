# Address Book Example

Building a CLI address book application using Automerge. 

## Overview

All the code herein can also be found in the [demo repository](https://github.com/automerge/contaaacts)

Let's imagine we're building a simple collaborative address book with a structure similar to the following JSON:

```json
{
    "contacts": [
        {
            "name": "Alice",
            "email": "alice@example.com"
        },
        {
            "name": "Bob",
            "email": "bob@example.com"
        }
    ]
}
```

We're going to build a simple CLI application called `contaaacts` for collaborating on an address book. Here's what we want to be able to do:

```bash
# create a new address book
contaaacts create ./friends

# Add a new contact
contaaacts add ./friends 'Alice' 'alice@example.com'

# List the contents of the address book
contaaacts list ./friends

# Modify a contact
contaaacts update ./friends alice --email 'alice2@example.com'

# merge with another version of the address book and output to a new file
contaaacts merge ./friends ./otherfriends ./merged

# provide a sync server for other peers to sync with on localhost:9090
contaaacts serve ./friends localhost 9090

# sync with a contaaacts server running at localhost:9090 and save the result
contaaacts sync ./friends localhost 9090
```

## Setup

We're creating a simple command line application, we'll have a single file called `Contaaacts.swift` where we parse and dispatch arguments. No error handling of any kind because this is an example. As we go through the rest of this guide we'll fill in the implementations of the handlers.

```
@main
struct Contaaacts {
    public static func main() {
        let args = CommandLine.arguments
        switch args[1] {
        case "create":
            create(filename: args[2])
        case "add":
            add(filename: args[2], name: args[4], email: args[6])
        case "list":
            list(filename: args[2])
        case "update":
            update(filename: args[2], contact: args[4], newEmail: args[6])
        case "merge":
            merge(filename1: args[2], filename2: args[3], out: args[4])
        case "serve":
            serve(filename: args[2], port: args[3])
        case "sync":
            sync(filename: args[2], server: args[3], port: args[4])
        default:
            print("unknown command")
        }
    }
}

func create(filename: String) {
}

func add(filename: String, name: String, email: String) {
}

func list(filename: String) {
}

func update(filename: String, contact: String, newEmail: String) {
}

func merge(filename1: String, filename2: String, out: String) {
}

func serve(filename: String, port: String) {
}

func sync(server: String) {
}
```

## Creating the address book 

To create an address book we just need to create an Automerge document with an empty `contacts` array in it. This is conceptually simple but there's a wrinkle, which we refer to as the "initial data" problem. Once we've explained the problem, the approach we take will make more sense.

### The "initial data" problem

Automerge documents contain "objects", which are maps, lists, or text objects. These objects have an ID (``ObjId``). Every Automerge document contains a "root" ID (``ObjId/ROOT``)which is a map, any time you create a new object in an Automerge document the new object has an ID you use to refer to it. The reason you need to know this is because the IDs which Automerge generates are used to determine how to merge documents, this means that for two documents with similar structure to merge in the way we expect, they need to share a history. 

Let's make this a bit more concrete. We are building a contact book application, the core data structure is a list of contacts under the `contacts` key in the document. The merge behaviour we want is that when two nodes concurrently add contacts to the contact book, they end up in the same sequence. In terms of the Automerge data model then, the `contacts` key is a property in the root object which contains a list object. The list has an ID - obtained by calling ``Document/putObject(obj:key:ty:)`` with ``ObjId/ROOT``, `"contacts"`, and ``ObjType/List``. For concurrent insertions into this list to merge, we want all insertions to reference the same ``ObjId`` for the list, but every time you call `putObject` you get a new object ID. What this means is that every node needs to share a basic skeleton document which already has an empty `"contacts"` list in it.

> Note: We are very much aware that this is not a good developer experience and we are thinking about ways to make this easier. See [this issue](https://github.com/automerge/automerge/issues/528)

### Generating a skeleton document

The easiest way to have every peer start from a shared history is to use the Automerge command line tools (installable by using `cargo install automerge-cli`) to generate an Automerge document from a JSON skeleton, and then including the bytes of this document as a resource in the application bundle.

```
# generate the skeleton  document
echo '{"contacts": []}' | automerge import > skeleton
```

You can verify the structure of the document by doing `automerge export skeleton`

We bundle the `skeleton` as a resource in the application, see the demo repository for details.

### Implementing `create`

Now that we have the skeleton document, implementing `"create"` is quite simple, we just output the contents of the bundled resource.

```
func create(filename: String) {
    let skeletonUrl = Bundle.module.url(forResource: "skeleton", withExtension: "")!
    let data = try! Data(contentsOf: skeletonUrl)
    let output = URL(fileURLWithPath: filename)
    try! data.write(to: output)
}
```

## Adding a contact

To add a contact we need to load the contents of the address book, then insert an ``ObjType/Map`` into the `contacts` list. Like so:

```
func add(filename: String, name: String, email: String) {

    // Load the data from the filesyste
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: filename))
    let document = try! Document(bytes)
    
    // Find the contacts list in the document
    let contacts: ObjId
    switch try! document.get(obj: ObjId.ROOT, key: "contacts")! {
    case .Object(let id, _):
        contacts = id
    default:
        fatalError("contacts was not a list")
    }

    // Insert a new map for the new contact at the end of the contacts list
    let lastIndex = try! document.length(obj: contacts)
    let newContact = try! document.insertObject(obj: contacts, index: lastIndex, ty: .Map)
// Set the name to a text field
    let nameText = try! document.putObject(obj: newContact, key: "name", ty: .Text)
    try! document.spliceText(obj: nameText, start:0, delete:0, value: name)

    // Set the email to a text field
    let emailText = try! document.putObject(obj: newContact, key: "email", ty: .Text)
    try! document.spliceText(obj: emailText, start:0, delete:0, value: email)

    // now save the document to the filesystem
    let savedBytes = document.save()
    let data = Data(bytes: savedBytes, count:savedBytes.count)
    let output = URL(fileURLWithPath: filename)
    try! data.write(to: output)
}
```

Note that we are using text objects to represent the name and email fields. Automerge does have a primitive string type (``ScalarValue/String(_:)``) but it's generally best to use text. There's very little extra cost to a text object and text objects support concurrent edits.

## Listing contacts

To list contacts we iterate over each value in the contacts list, printing them out.

```
func list(filename: String) {
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: filename))
    let document = try! Document(bytes)
    let contacts: ObjId
    switch try! document.get(obj: ObjId.ROOT, key: "contacts")! {
    case .Object(let id, _):
        contacts = id
    default:
        fatalError("contacts was not a list")
    }

    for value in try! document.values(obj: contacts) {
        switch value {
        case .Object(let contact, .Map):
            let nameId: ObjId
            switch try! document.get(obj: contact, key: "name")! {
            case .Object(let id, .Text):
                nameId = id
            default:
                fatalError("contact name was not a text object")
            }

            let emailId: ObjId
            switch try! document.get(obj: contact, key: "email")! {
            case .Object(let id, .Text):
                emailId = id
            default:
                fatalError("contact email was not a text object")
            }

            let name = try! document.text(obj: nameId)
            let email = try! document.text(obj: emailId)
            print("\(name): \(email)")
        default:
            fatalError("unexpected value in contacts")
        }
    }
}
```

## Updating a contact

Here we load the document, loop over the contacts in the `contacts` list, and if we find a matching name we update the email.

```
func update(filename: String, contact: String, newEmail: String) {
    let bytes = try! Data(contentsOf: URL(fileURLWithPath: filename))
    let document = try! Document(bytes)
    let contacts: ObjId
    switch try! document.get(obj: ObjId.ROOT, key: "contacts")! {
    case .Object(let id, _):
        contacts = id
    default:
        fatalError("contacts was not a list")
    }

    var found = false
    for value in try! document.values(obj:contacts) {
        switch value {
        case .Object(let contactId, .Map):
            let nameId: ObjId
            switch try! document.get(obj: contactId, key: "name")! {
            case .Object(let id, .Text):
                nameId = id
            default:
                fatalError("contact name was not a text object")
            }

            let name = try! document.text(obj: nameId)
            if name == contact.trimmingCharacters(in: .whitespacesAndNewlines) {
                found = true
                let newEmailId = try! document.putObject(obj: contactId, key: "email", ty: .Text)
                try! document.spliceText(obj:newEmailId, start:0, delete:0, value: newEmail)
                break;
            }
        default:
            continue
        } }
    if !found {
        fatalError("contact \(contact) not found")
    }

    // now save the document to the filesystem
    let savedBytes = document.save()
    let data = Data(bytes: savedBytes, count:savedBytes.count)
    let output = URL(fileURLWithPath: filename)
    try! data.write(to: output)
}
```

## Merging address books

```
func merge(filename1: String, filename2: String, out: String) {
    let leftBytes = try! Data(contentsOf: URL(fileURLWithPath: filename1))
    let left = try! Document(leftBytes)

    let rightBytes = try! Data(contentsOf: URL(fileURLWithPath: filename2))
    let right = try! Document(rightBytes)

    try! left.merge(other: right)
    let savedBytes = left.save()
    let data = Data(bytes: savedBytes, count:savedBytes.count)
    let output = URL(fileURLWithPath: out)
    try! data.write(to: output)
}
```

## Sync

There's quite a bit of ceremony involved in network programming in Swift, so we don't repeat the code here, see the demo for the gory details.
