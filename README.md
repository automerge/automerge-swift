# Automerge-swifter

An Automerge implementation for swift.

This is a reasonably low-level library with relatively few concessions to ergonomics, nicer APIs should be built on top of this work.

This is also a first draft I (@alexjg) am not particularly familiar with Swift so I expect many things are weird or wrong. Please tell me what those things are!

Docs available [here](https://automerge.org/automerge-swifter/documentation/automerge/)

A demo app [here](https://github.com/automerge/contaaacts)

## Quickstart

Add a dependency in `Package.swift` (note the use of the `.product(..)` dependency for the target, this is because our repository name does not match the product name, or something like that, [see here](https://forums.swift.org/t/why-does-spm-use-github-repo-name-and-not-package-swift-name/55085/3))

```swift
let package = Package(
    ...
    dependencies: [
        ...
        .package(url: "git@github.com:automerge/automerge-swifter.git", from: "0.0.1")
    ],
    targets: [
        .executableTarget(
            ...
            dependencies: [.product(name: "Automerge", package: "automerge-swifter")],
            ...)
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

## Building and developing

This package is implemented by wrapping the Rust library. There are two problems
to solve to make this possible:

1. Writing and/or generating a bunch of code to cross the FFI bridge from Rust to
   swift
2. Distributing the compiled Rust in a way that swift understands

We use the [Uniffi](https://mozilla.github.io/uniffi-rs/) framework from Mozilla. Uniffi takes in an IDL file describing the FFI interface and some rust source code which implements the Rust side of the interface. Given this IDL Uniffi generates a swift package providing the swift side of the interface. However, the generated code is not very idiomatic swift, so we wrap it in a handwritten swift side wrapper of our own. Finally, we have to actually distribute the rust code as a binary XCFramework. 

The moving parts here then are:

* The `rust/src/automerge.udl` file which describes the FFI interface
* The `rust/build.rs` build script, which uses Uniffi to generate the boilerplate parts of the rust side of the interface
* The `rust/src/*`files which implement the Automerge specific parts of the rust binding
* The `rust/uniffi-bindgen.rs` script, which uses Uniffi to output a Swift wrapper around the interface
* The source files in `./Sources` and `./Tests` which implement the handwritten swift wrappers
* The `./scripts/build-xcframework.sh` script, which builds the rust project and packages it into an XCFramework

Actually, the `build-xcframework.sh` script does a bit more than this. It builds the rust framework, then generates the swift package and copies it into `./AutomergeUniffi`, then also generates the XCFramework and places it in `automergeFFI.xcframework.zip`.

What this means is that the typical development cycle usually looks like this:

* Write a failing test in `Tests/*.swift`
* Modify the `rust/src/automerge.udl` file to expose the additional methods or data you need from the rust side
* In the rust project write rust code to implement the IDL. The build script generates the new code Uniffi needs and will produce compile errors until you implement the required parts. This means you just run `cargo build` in `./rust` and modify code until cargo is happy
* Run `./scripts/build-xcframework.sh` to generate the new xcframework based on the new bindings you've implemented
* Wire up the swift side of the wrappers in `./Sources/*`
* Run tests on the swift side with `swift test`

### Building the docs

The script `./scripts/preview-docs.sh` will run a web server previewing the docs. This won't pick up all source code changes so you may need to restart it occasionally (I have not figured out which changes it does and does not pick up on).

### Releasing

Swift package manager requires that the built artifacts for the `binaryTarget` we are distributing are part of the repository. It's kind of awkward to have build artifacts in the repository though. To avoid this we only put the build artifacts (specifically, the `AutomergeFFI.xcframework.zip` file and the `AutomergeUniffi` folder which are produced by `scripts/build-xcframework.sh`) in the repository for tagged releases and otherwise we `.gitignore` them. This is a bit of a hack, feel free to suggest better alternatives.

Creating a release then requires doing the following things:

* Checkout a new branch
* Run `scripts/build-xcframework.sh`
* Add a commit containing `AutomergeFFI.xcframework.zip` and `AutomergeUniffi` to the index
* Tag the branch with a version - e.g. `git tag 0.0.1`
* Push the tag to the remote
