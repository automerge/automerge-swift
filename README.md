# Automerge-swifter

An Automerge implementation for swift.

This is a low-level library with few concessions to ergonomics, meant to interact directly with the low-level Automerge API.
Additional API that is more ergonomic is being added into the repository as this project evolves.

[Automerge-Swifter API Documentation](https://automerge.org/automerge-swifter/documentation/automerge/) is available on the [Automerge site](https://automerge.org/).
A command-line demonstration application ([contaaacts](https://github.com/automerge/contaaacts)) is available that shows using the lower level API.

## Quickstart

Add a dependency in `Package.swift`, as the following example shows:

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "https://github.com/automerge/automerge-swifter.git", from: "0.1.1")
    ],
    targets: [
        .executableTarget(
            ...
            dependencies: [.product(name: "Automerge", package: "automerge-swifter")],
            ...
        )
    ]
)
```

Now you can create a document and do all sorts of Automerge things with it

```swift
let doc = Document()
let list = try! doc.putObject(obj: ObjId.ROOT, key: "colours", ty: .List)
try! doc.insert(obj: list, index: 0, .String("blue"))
try! doc.insert(obj: list, index: 1, .String("red"))

let doc2 = doc.fork()
try! doc2.insert(obj: list, index: 0, .String("green"))

try! doc.delete(obj: list, index: 0)

try! doc.merge(doc2) // `doc` now contains {"colours": ["green", "red"]}
```

For more details on the API, see the [Automerge-swifter API documentation](https://automerge.org/automerge-swifter/documentation/automerge/) and the articles within.
