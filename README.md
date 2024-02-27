# Automerge-swift

An Automerge implementation for swift.

This is a low-level library with few concessions to ergonomics, meant to interact directly with the low-level Automerge API.
Additional API that is more ergonomic is being added into the repository as this project evolves.

[Automerge-Swift API Documentation](https://automerge.org/automerge-swift/documentation/automerge/) is available on the [Automerge site](https://automerge.org/).
A command-line demonstration application ([contaaacts](https://github.com/automerge/contaaacts)) is available that shows using the lower level API.

Note: There was an earlier Swift language bindings for Automerge here at automerge/automerge-swift.
The repository was [renamed and archived](https://github.com/automerge/automerge-swift-archived), but is available if you are looking for it.

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
