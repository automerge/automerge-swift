// swift-tools-version:5.6

import PackageDescription
import Foundation

var globalSwiftSettings: [PackageDescription.SwiftSetting] = []
#if swift(>=5.7)
// Only enable these additional checker settings if the environment variable `CI` is set.
// (Typically set through GitHub actions)
if ProcessInfo.processInfo.environment["CI"] != nil {
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
            url: "https://github.com/automerge/automerge-swifter/releases/download/0.1.1/automergeFFI.xcframework.zip",
            checksum: "2a73a8723c330df82d24ab0e27a7964b68b6b966878335bedae9f46491618f61"
    )
}

let package = Package(
    name: "Automerge",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "Automerge", targets: ["Automerge"]),
    ],
    targets: [
        FFIbinaryTarget,
        .target(
            name: "AutomergeUniffi",
            dependencies: ["automergeFFI"],
            path: "./AutomergeUniffi"
        ),
        .target(
            name: "Automerge",
            dependencies: ["AutomergeUniffi"],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "AutomergeTests",
            dependencies: ["Automerge"]
        ),
    ]
)
