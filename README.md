# Automerge-swift

The project is an [Automerge](https://automerge.org) implementation, a library of data structures for building collaboraative applications, in Swift.
Automerge is cross platform and cross-language, allowing you to provide collaboration support between browsers and native apps.

The [API Documentation](https://automerge.org/automerge-swift/documentation/automerge/) provides an overview of this library and how to use it.

[Automerge Repo (Swift)](http://github.com/automerge/automerge-repo-swift/) is a supplemental library that extends this library.
It adds pluggable network and storage support for Apple platforms for a more "batteries included" result, and is tested with the [JavaScript version of Automerge Repo](https://github.com/automerge/automerge-repo).

The open-source iOS and macOS document-based SwiftUI App [MeetingNotes](https://github.com/automerge/meetingnotes/) provides a show-case for how to use Automerge to build a live, collaborative experience.
MeetingNotes builds over both this library and the repository to provide both WebSocket and peer to peer based networking in the app.

## Quickstart

Add a dependency in `Package.swift`, as the following example shows:

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/automerge/automerge-swift.git", from: "0.5.2")
    ],
    targets: [
        .executableTarget(
            ...
            dependencies: [.product(name: "Automerge", package: "automerge-swift")],
            ...
        )
    ]
)
```

Now you can create a document and do all sorts of Automerge things with it

```swift
let doc = Document()
let list = try! doc.putObject(obj: ObjId.ROOT, key: "colours", ty: .List)
try! doc.insert(obj: list, index: 0, value: .String("blue"))
try! doc.insert(obj: list, index: 1, value: .String("red"))

let doc2 = doc.fork()
try! doc2.insert(obj: list, index: 0, value: .String("green"))

try! doc.delete(obj: list, index: 0)

try! doc.merge(other: doc2) // `doc` now contains {"colours": ["green", "red"]}
```

For more details on the API, see the [Automerge-swift API documentation](https://automerge.org/automerge-swift/documentation/automerge/) and the articles within.

> Note: There was an earlier project that provided Swift language bindings for Automerge. The repository was [renamed and archived](https://github.com/automerge/automerge-swift-archived), but is available if you are looking for it.