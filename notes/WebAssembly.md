# WebAssembly support

This note presumes that you want to write your WebAssembly code in swift and
leverage the Automerge-swift library specifically. If you want to use Automerge in WebAssembly, use the deliverables specifically created at https://github.com/automerge/automerge and released to NPM for direct browser support.

With [pull request 92](https://github.com/automerge/automerge-swift/pull/92), the Automerge-swift repository now supports compilation into WebAssembly.
This update adds a layer of indirection to the binary targets in Package.swift to allow for Apple platforms to utilize an XCFramework to load in the rust core library, and for other platforms (for example, WASM) to link and load the core automerge library independently.

For code updates, its import to externalize the dependencies for Combine, SwiftUI, os.log, and libdispatch to work with WebAssembly. The merged pull request updated those to leverage `canImport()` to make the majority of those optional dependencies, and CI has been updated to verify that everything can be built through swift-wasm to insure we don't accidentally break that setup.

Swift-wasm with Swift package manager doesn't support invoking cargo to get the Rust library built up and linked, so the linking, in particular, is up to the person compiling this with swift-wasm. Yuta Saito created a demonstration example of this at https://github.com/kateinoigakukun/automerge-swift-wasm.

For example, the Rust core library (with the pieces needed to support Automerge-swift) can be built for wasm through Cargo using the command:

    cargo build --manifest-path rust/Cargo.toml --target wasm32-wasip1-threads --release

This builds libuniffi_automerge.a, an archive of WebAssembly that can be linked and loaded by the swift-wasm compiler. The following snippet is an example of how to pass the library to swift-wasm builder on the command line:

    swift build -Xlinker /path/to/libuniffi_automerge.a

The following snippet is an example of a `Package.swift` file that adds the linker options, asserting that the `libuniffi_automerge.a` file is in the same directory as the `Package.swift` file:

```swift
// swift-tools-version: 5.8

import PackageDescription
import Foundation

let package = Package(
    name: "Example",
    dependencies: [
        .package(url: "https://github.com/kateinoigakukun/automerge-swift", revision: "3cbe046a296ce8f4674708a8777058c5e4013400"),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [.product(name: "Automerge", package: "automerge-swift")],
            linkerSettings: [
              .unsafeFlags([URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("libuniffi_automerge.a").path]),
            ]),
    ]
)
```
