# Supporting a pre-release branch

This package needs access to binary targets built with updated Rust libraries, but also coordinated with the associated generated Swift file `AutomergeUniffi/automerge.swift`.
The pattern most conducive to supporting a pre-release sets up a dependency on a branch, with the branch containing tagged points where the binary content can be hosted from a GitHub pre-release.

To support an alpha pre-release with binary target content hosted on GitHub, we create separate, short-liveded branch from `main`.
For the `0.5` pre-releases, the branch is `alpha0.5.0`, forked from main.

The `Package.swift` file in those branches refers to GitHub hosted pre-releases that also host the built Rust code as an XCFramework.
For example, at one point, the binary target in the `alpha0.5.0` branch read:

```swift
    FFIbinaryTarget = .binaryTarget(
        name: "automergeFFI",
        url: "https://github.com/automerge/automerge-swift/releases/download/0.5.0-alpha3/automergeFFI.xcframework.zip",
        checksum: "f9e96b1b76c1a4e273a3b968e82c24bf77fd00fc21b0120b462ece4c0022fddb"
    )
```

All commits in the pre-release branch are first applied on the `main` branch.
During new release development, the `main` branch may only be functional with a local build of the XCFramework.

When a full release is made and relevant tags are set, the alpha branches are considered dead, but left in place for clearer history consistency.

## Using the pre-release branch

To use a pre-release branch, have your Package.swift or Xcode project depend on alpha branch. 
For example, to use the pre-release of the 0.5:

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
