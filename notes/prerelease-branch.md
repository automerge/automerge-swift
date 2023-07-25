# Supporting a pre-release branch

To support an alpha pre-release with binary target content hosted on GitHub, we're managing a separate, short-lived branch from `main`.
This package needs access to binary targets built with updated Rust libraries, but also coordinated with the associated generated Swift file `AutomergeUniffi/automerge.swift`.
The pattern that seems most conducive to supporting a pre-release is to set up a dependency on a branch, with the branch containing tagged points where the binary content can be hosted from a GitHub pre-release.

For the `0.5.0` release, the branch is named `alpha0.5.0`, forked from main. 
The `Package.swift` file in those branches refers to GitHub hosted pre-releases that also host the built Rust code as an XCFramework.
For example, the binary target in this branch reads:

```swift
    FFIbinaryTarget = .binaryTarget(
        name: "automergeFFI",
        url: "https://github.com/automerge/automerge-swift/releases/download/0.5.0-alpha3/automergeFFI.xcframework.zip",
        checksum: "f9e96b1b76c1a4e273a3b968e82c24bf77fd00fc21b0120b462ece4c0022fddb"
    )
```

All commits for forward updates are made onto the `main` branch - which at the moment would only be usable with a local build of the XCFramework.
Some of those commits are cherry-picked into the alpha branch for easier public consumption while I'm working on the next release.

When the `0.5.0`` release is cut, and relevant tags are set, the intention is to delete the branch and remove the GitHub pre-releases.

## Using the pre-release branch

To use this pre-release branch, have your Package.swift or Xcode project depend on alpha branch:

```swift
dependencies: [
    .package(url: "https://github.com/automerge/automerge-swift", branch: "alpha0.5.0")
]
```

with the same target dependency:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Automerge", package: "automerge-swift"),
    ]
)
```
