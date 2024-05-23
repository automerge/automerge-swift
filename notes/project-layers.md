# Project layers for Automerge-swift

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
* The `./scripts/build-xcframework.sh` script, followed by `./scripts/compress-framework.sh`, which builds the rust project and packages it into an XCFramework.
Actually, the `build-xcframework.sh` script does a bit more than this.
It builds the rust framework, generates the swift package and copies it into `./AutomergeUniffi`, and generates the XCFramework directory.
The follow-on script `./scripts/compress-framework.sh` compresses that into a zip file and places it in `automergeFFI.xcframework.zip`.

The default Package.swift uses the latest, pre-compiled version of the XCFramework to make it easy to directly use this package.
If you are developing at the Rust or FFI interface level, set the environment variable `LOCAL_BUILD` to any value, and use the script `./scripts/build-xcframework.sh` to rebuild the core library.
Then run `./scripts/compress-framework.sh` to fully set up a local version of the XCFramework file.
For example:

```bash
export LOCAL_BUILD=true
./scripts/build-xcframework.sh
./scripts/compress-framework.sh
```

> NOTE: The binary in the generated XCFramework and the code in ./AutomergeUniffi are **tightly** coupled. Do not edit any code in `./AutomergeUniffi` directly. Regenerate the XCFramework if you update the rust or UDL layer, and test with the regenerated XCFramework.

What this means is that the typical development cycle usually looks like this:

* Write a failing test in `Tests/*.swift`.
* Modify the `rust/src/automerge.udl` file to expose the additional methods or data you need from the rust side.
* In the rust project write rust code to implement the IDL. The build script generates the new code Uniffi needs and will produce compile errors until you implement the required parts. This means you just run `cargo build` in `./rust` and modify code until cargo is happy.
* Set the environment variable `LOCAL_BUILD` to `true`.
* Run `./scripts/build-xcframework.sh` to generate the new xcframework based on the new bindings you've implemented.
* Wire up the swift side of the wrappers in `./Sources/*`.
* Run tests on the swift side with `swift test`.

![Block diagram of the Automerge swift project layers](./project-layout.svg)
