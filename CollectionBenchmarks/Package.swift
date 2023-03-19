// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "AutomergeCollectionBenchmarks",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections-benchmark", from: "0.0.1"),
        .package(path: "../"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "CollectionBenchmarks",
            dependencies: [
                .product(name: "Automerge", package: "automerge-swifter"),
                .product(
                    name: "CollectionsBenchmark",
                    package: "swift-collections-benchmark"
                ),
            ]
        ),
    ]
)
