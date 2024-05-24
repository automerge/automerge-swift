# Contributing

Issues for this library are tracked on GitHub: [https://github.com/automerge/automerge-swift/issues](https://github.com/automerge/automerge-swift/issues)

Feel free to [join the Automerge Discord Server](https://discord.gg/HrpnPAU5zx), which includes a channel for `#automerge-swift`, for conversation about this library or Automerge in general.

## Building and Developing

This package is implemented by wrapping the Rust library using the [Uniffi](https://mozilla.github.io/uniffi-rs/) framework from Mozilla.
The core library is compiled using Rust and exported as an XCFramework and WASM library.
For an overview of the project layout and major components, review [notes/project-layers](./notes/project-layers.md).

> NOTE: The binary in the generated XCFramework and the code in ./AutomergeUniffi are **tightly** coupled. Do not edit any code in `./AutomergeUniffi` directly. Regenerate the XCFramework if you update the rust or UDL layer, and test with the regenerated XCFramework.

The default Package.swift uses the latest, pre-compiled version of the XCFramework to make it easy to directly use this package.
If you are developing at the Rust or FFI interface level, set the environment variable `LOCAL_BUILD` to any value, and use the script `./scripts/build-xcframework.sh` to rebuild the core library.
Then run `./scripts/compress-framework.sh` to fully set up a local version of the XCFramework file.
For example:

```bash
export LOCAL_BUILD=true
./scripts/build-xcframework.sh
./scripts/compress-framework.sh
```

What this means is that the typical development cycle usually looks like this:

* Write a failing test in `Tests/*.swift`.
* Modify the `rust/src/automerge.udl` file to expose the additional methods or data you need from the rust side.
* In the rust project write rust code to implement the IDL. The build script generates the new code Uniffi needs and will produce compile errors until you implement the required parts. This means you just run `cargo build` in `./rust` and modify code until cargo is happy.
* Set the environment variable `LOCAL_BUILD` to `true`.
* Run `./scripts/build-xcframework.sh` to generate the new xcframework based on the new bindings you've implemented.
* Wire up the swift side of the wrappers in `./Sources/*`.
* Run tests on the swift side with `swift test`.

## Dependencies

The Automerge package intentionally holds no additional package dependencies, aside from the core Automerge library. Anything that requires additional package dependencies is not a good fit for this library, and should be developed in an external package/project. For example, [Automerge-repo-swift](http://github.com/automerge/automerge-repo-swift/) adds a number of other dependencies to enable platform-specific transports, storage management, etc.

The supplementary package, `AutomergeUtilities` depends ONLY on Automerge, intended for tooling primarily to assist when debugging or testing.

The core library dependencies is defined in `./rust/Cargo.toml`, and the specific Rust toolchain used to generate the XCFramework and WASM libraries is defined in the script `./scripts/build-xcframework.sh`.

## Conditional Compilation in the Automerge module

In Automerge, conditionally compile for platform specific dependencies (for example, `Combine`, `SwiftUI`, `CoreTransferrable`, `UniformTypeIdentifiers`) so that the package compiles cleanly in WASM.
This is "enforced" by a validation build that compiles the project using a Swift-WASM toolchain.

## Pull Requests

If you're intending to work on the project, please open an issue for the work you're doing, and not just a pull-request unless it is a very simple bug or typo fix.
Work on the project is discussed in the [Automerge Discord Server](https://discord.gg/HrpnPAU5zx), in the `#automerge-swift` channel (under `ports`).
If you have an interactive question, want to discuss a bit of feature development, or want to request more immediate review of something, please contact in Discord.

When adding code to the project, any features should include tests and documentation updates to match.

### Formatting, Linting, and Tests

The rust layer (`./rust/lib.rs`) is not expected to have any tests. It is expected to compile, be formatted with the `cargo fmt` command, and pass the Rust linter, `clippy`. To check
the code locally, run the following commands:

```bash
./scripts/ci/clippy.sh
./scripts/ci/rustfmt.sh
```

Tests are in Swift, as a test target defined on the primary deliverable: `Automerge`.
The source for the tests is `Tests/AutomergeTests/`.

Swift code is expected to be formatting with `swiftformat`, but commits are not gated on adherance to formatting.
As a general practice, please run `swiftformat .` to format all Swift code in the project consistently.

### Continuous Integration

In addition to the formatting and linting for the Rust code, the CI system always builds a new framework and runs the tests.
All are expected to pass before a Pull Request is merged.

## Benchmarking

The repository has two-dimensional benchmarking as a seperate project in the directory `CollectionBenchmarks`.
It uses the library [swift-collections-benchmarks](https://github.com/apple/swift-collections-benchmark) to run benchmarks that are relevant over the size of the collection.
The benchmark baselines were built on an Apple M1 MacBook Pro.

## Building the docs

The script `./scripts/preview-docs.sh` will run a web server previewing the docs.
This does not pick up all source code changes so you may need to restart the process occasionally.

Documentation is generated using DocC (part of the Swift language toolchain), with content housed in the source code, both in the Swift source and in a DocC catalog directory for each module:

* `Sources/Automerge/Automerge.docc/`
* `Sources/AutomergeUtilities/AutomergeUtilities.docc/`

Documentation is updated manually, typically as a follow-up to a point release.

## Releasing Updates

The full process of releasing updates for the library is detailed in [Release Process](./notes/release-process.md)
