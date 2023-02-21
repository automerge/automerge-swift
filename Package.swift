// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "Automerge",
  platforms: [.iOS(.v13), .macOS(.v10_15)],
  products: [
    .library(name: "Automerge", targets: ["Automerge"])
  ],
  dependencies: [.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0")],
  targets: [
    // These comments were copied from https://github.com/y-crdt/y-uniffi/blob/7cd55266c11c424afa3ae5b3edae6e9f70d9a6bb/lib/Package.swift
    // which was written by Joseph Heck and  Aidar Nugmanoff and licensed
    // under the MIT license. There is also an elaboration of the problems
    // we are solving at
    // https://rhonabwy.com/2023/02/10/creating-an-xcframework/

    // ---
    // Copied Comments
    // ---
    // If you're getting the error 'does not contain expected binary artifact',
    // then the filename of the xcframework doesn't match the name module that's
    // exposed within it.
    // There's a *tight* coupling to the module name (case sensitive!!) and the
    // name of the XCFramework. Annoying, yeah - but there it is.

    // In addition to the name of the framework, the binary target name in
    // Package.swift MUST be the same as the exported module. Without it, you'll
    // get the same error. And there's some detail that if you use a compressed,
    // remote framework and forgot to compress it using ditto with the option
    // '--keepParent', then it'll expand into a different name, and again
    // - wham - the same "does not contain the expected binary" error.
    .binaryTarget(
      name: "automergeFFI",
      path: "./automergeFFI.xcframework.zip"
    ),
    .target(
      name: "AutomergeUniffi",
      dependencies: ["automergeFFI"],
      path: "./AutomergeUniffi"
    ),
    .target(
      name: "Automerge",
      dependencies: ["AutomergeUniffi"]
    ),
    .testTarget(
      name: "AutomergeTests",
      dependencies: ["Automerge"]
    ),
  ]
)
