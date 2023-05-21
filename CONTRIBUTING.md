# Contributing

Issues for this library are tracked on GitHub: [https://github.com/automerge/automerge-swifter/issues](https://github.com/automerge/automerge-swifter/issues)

There is a hosted [Automerge Slack](https://automerge.slack.com/join/shared_invite/zt-e4p3760n-kKh7r3KRH1YwwNfiZM8ktw#/shared-invite/email) that includes the channel `#automerge-swift`. 

## Building and Developing

This package is implemented by wrapping the Rust library. 
There are two problems to solve to make this possible:

1. Writing and/or generating a bunch of code to cross the FFI bridge from Rust to Swift
2. Distributing the compiled Rust in a way that Swift understands

We use the [Uniffi](https://mozilla.github.io/uniffi-rs/) framework from Mozilla. 
Uniffi takes in an IDL file describing the FFI interface and some rust source code which implements the Rust side of the interface. 
Given this IDL Uniffi generates a swift package providing the swift side of the interface. 
However, the generated code is not very idiomatic Swift, so we wrap it in a handwritten Swift wrapper of our own. 
Finally, we distribute the compiled Rust code in the form of a binary XCFramework. 

The moving parts here then are:

* The `rust/src/automerge.udl` file which describes the FFI interface.
* The `rust/build.rs` build script, which uses Uniffi to generate the boilerplate parts of the rust side of the interface.
* The `rust/src/*`files which implement the Automerge specific parts of the rust binding.
* The `rust/uniffi-bindgen.rs` script, which uses Uniffi to output a Swift wrapper around the interface.
* The source files in `./Sources` and `./Tests` which implement the handwritten swift wrappers.
* The `./scripts/build-xcframework.sh` script, which builds the rust project and packages it into an XCFramework.
Actually, the `build-xcframework.sh` script does a bit more than this. 
It builds the rust framework, generates the swift package and copies it into `./AutomergeUniffi`, and generates the XCFramework and places it in `automergeFFI.xcframework.zip`.

The default Package.swift uses the latest, pre-compiled version of the XCFramework to make it easy to directly use this package.
If you are developing at the Rust or FFI interface level, set the environment variable `LOCAL_BUILD` to any value, and use the script `./scripts/build-xcframework.sh` to compile the Rust, regenerate the associated Swift wrappers, and recreate a local copy of the XCFramework file.
For example:

```bash
export LOCAL_BUILD=true
./scripts/build-xcframework
```

What this means is that the typical development cycle usually looks like this:

* Write a failing test in `Tests/*.swift`.
* Modify the `rust/src/automerge.udl` file to expose the additional methods or data you need from the rust side.
* In the rust project write rust code to implement the IDL. The build script generates the new code Uniffi needs and will produce compile errors until you implement the required parts. This means you just run `cargo build` in `./rust` and modify code until cargo is happy.
* Set the environment variable `LOCAL_BUILD` to `true`. 
* Run `./scripts/build-xcframework.sh` to generate the new xcframework based on the new bindings you've implemented.
* Wire up the swift side of the wrappers in `./Sources/*`.
* Run tests on the swift side with `swift test`.

## Benchmarking

The repository has two-dimensional benchmarking as a seperate project in the directory `CollectionBenchmarks`.
It uses the library [swift-collections-benchmarks](https://github.com/apple/swift-collections-benchmark) to run benchmarks that are relevant over the size of the collection.
The benchmark baselines were built on an Apple M1 MacBook Pro.

## Building the docs

The script `./scripts/preview-docs.sh` will run a web server previewing the docs. 
This does not pick up all source code changes so you may need to restart it occasionally.

## Releasing Updates

The full process of releasing updates for the library is detailed in [Release Process](./notes/release-process.md)
