// swift-tools-version:5.6

import Foundation
import PackageDescription

var globalSwiftSettings: [PackageDescription.SwiftSetting] = []
#if swift(>=5.7)
// Only enable these additional checker settings if the environment variable
// `LOCAL_BUILD` is set. Previous value of `CI` was a poor choice because iOS
// apps in GitHub Actions would trigger this as unsafe flags and fail builds
// when using a released library.
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    globalSwiftSettings.append(.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]))
    /*
     Summation from https://www.donnywals.com/enabling-concurrency-warnings-in-xcode-14/
     Set `strict-concurrency` to `targeted` to enforce Sendable and actor-isolation
     checks in your code. This explicitly verifies that `Sendable` constraints are
     met when you mark one of your types as `Sendable`.

     This mode is essentially a bit of a hybrid between the behavior that's intended
     in Swift 6, and the default in Swift 5.7. Use this mode to have a bit of
     checking on your code that uses Swift concurrency without too many warnings
     and / or errors in your current codebase.

     Set `strict-concurrency` to `complete` to get the full suite of concurrency
     constraints, essentially as they will work in Swift 6.
     */
}
#endif

// When we move to Swift 5.8 tools version, the above can be collapsed into:
//
// if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
//     globalSwiftSettings.append(.enableExperimentalFeature("StrictConcurrency"))
// }

let FFIbinaryTarget: PackageDescription.Target
// If the environment variable `LOCAL_BUILD` is set to any value, the packages uses
// a local reference to the XCFramework file (built from `./scripts/build-xcframework.sh`)
// rather than the previous released version.
//
// The script `./scripts/build-xcframework.sh` _does_ expect that you have Rust
// installed locally in order to function.
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    // We are using a local file reference to an XCFramework, which is functional
    // on the tags for this package because the XCFramework.zip file is committed with
    // those specific release points. This does, however, cause a few awkward issues,
    // in particular it means that swift-docc-plugin doesn't operate correctly as the
    // process to retrieve the symbols from this and the XCFramework fails within
    // Swift Package Manager. Building documentation within Xcode works perfectly fine,
    // but if you're attempting to generate HTML documentation, use the script
    // `./scripts/build-ghpages-docs.sh`.
    FFIbinaryTarget = .binaryTarget(
        name: "automergeFFI",
        path: "./automergeFFI.xcframework.zip"
    )
} else {
    FFIbinaryTarget = .binaryTarget(
        name: "automergeFFI",
        url: "https://github.com/automerge/automerge-swift/releases/download/0.5.15/automergeFFI.xcframework.zip",
        checksum: "d6fc0a66264491e88f1a0e06651e6b258fa5d7c79c763b7e026b0337c62ee74e"
    )
}

let package = Package(
    name: "Automerge",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "Automerge", targets: ["Automerge", "AutomergeUtilities"]),
    ],
    targets: [
        FFIbinaryTarget,
        .target(
            name: "AutomergeUniffi",
            dependencies: [
                // On Apple platforms, this links the core Rust library through XCFramework.
                // On other platforms (such as WASM), end users will need to build the library
                // themselves and link it through the "swift build -Xlinker path/to/libuniffi_automerge.a"
                // for example: cargo build --manifest-path rust/Cargo.toml --target wasm32-wasi --release
                .target(name: "automergeFFI", condition: .when(platforms: [
                    .iOS, .macOS, .macCatalyst, .tvOS, .watchOS,
                ])),
                // The dependency on _CAutomergeUniffi gives the WebAssembly linker a place to link in
                // the automergeFFI target when the XCFramework binary target isn't available.
                .target(name: "_CAutomergeUniffi", condition: .when(platforms: [.wasi, .linux])),
            ],
            path: "./AutomergeUniffi"
        ),
        .systemLibrary(name: "_CAutomergeUniffi"),
        .target(
            name: "Automerge",
            dependencies: ["AutomergeUniffi"],
            swiftSettings: globalSwiftSettings
        ),
        .target(
            name: "AutomergeUtilities",
            dependencies: ["Automerge"],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "AutomergeTests",
            dependencies: ["Automerge", "AutomergeUtilities"],
            exclude: ["Fixtures"]
        ),
    ]
)
