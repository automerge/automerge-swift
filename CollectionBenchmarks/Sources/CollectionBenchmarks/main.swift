import Automerge
import CollectionsBenchmark
import Foundation

// NOTE(heckj): collections-benchmark implementations can be a bit hard to understand
// from the opaque inputs and structure of the code.
//
// When the benchmarks are running, each run has a "size" associated with it,
// and that flows to the inputs that the task provides to your closure. The
// collections benchmarks are _always_ 2D dimensional in nature - some value you choose over
// "size" of the collection.
//
// It's worthwhile to look at existing benchmarks that Karoy created for
// https://github.com/apple/swift-collections and build from those as bases:
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Sources/Benchmarks/SetBenchmarks.swift
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Sources/Benchmarks/OrderedSetBenchmarks.swift
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Sources/Benchmarks/DictionaryBenchmarks.swift
//
// There are 4 different default
// 'input generators' registered and immediately available:
//
// [Int.self](https://github.com/apple/swift-collections-benchmark/blob/main/Sources/CollectionsBenchmark/Benchmark/Benchmark.swift#L24-L26)
// [[Int].self](https://github.com/apple/swift-collections-benchmark/blob/main/Sources/CollectionsBenchmark/Benchmark/Benchmark.swift#L27-L29)
// [([Int], [Int]).self](https://github.com/apple/swift-collections-benchmark/blob/main/Sources/CollectionsBenchmark/Benchmark/Benchmark.swift#L30-L32)
// Insertions.self
//
// The first three result in an array of length 'size' with integers, in shuffled order.
// The last one is a set of array of random numbers where each number is within the
// range 0...i where i is the index of the element order. It's useful for
// testing random insertions.
//
// You can create your own input generators for more custom interactions or
// patterns that you wish to explore. To do so, use `benchmark.registerInputGenerator(for:)`.
// The for: variable defines the type that you're returning to the benchmark, and the function
// takes a trailing closure that is provided the size (of type `Int`) to the closure, and expects
// the type you defined in the `for:` parameter to be returned for that instance of size.
//
// For example, the definition of the `[Int].self` generator is:
//
// ```swift
// registerInputGenerator(for: [Int].self) { size in
//     (0 ..< size).shuffled()
// }
// ```
// The above generator creates a range of values from 0 to the size provided and returns
// them as an array of integers, shuffled.

var benchmark = Benchmark(title: "Automerge")

let stringCharacters = "a bcdef ghijk lmnop qrstu vwxyz ABCD EFGHI JKLMN OPQRS TUVWX YZ😀😎🤓⚁ ♛⛺︎🕰️⏰⏲️ ⏱️🧭".map { char in
    String(char)
}

// benchmark returns type of [String], but is essentially a large array of random characters.
benchmark.registerInputGenerator(for: [String].self) { size in
    (0 ..< size)
        .map { _ in
            stringCharacters.randomElement() ?? " "
        }
}

benchmark.addSimple(
    title: "Document text append",
    input: [String].self
) { input in
    let doc = Automerge.Document()
    let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

    var stringLength = doc.length(obj: text)
    for strChar in input {
        try! doc.spliceText(obj: text, start: stringLength, delete: 0, value: strChar)
        stringLength = doc.length(obj: text)
    }
    // precondition(stringLength == input.count) // NOT VALID - difference in UTF-8 codepoints and how strings represent
    // lengths
    blackHole(doc)
}

benchmark.addSimple(
    title: "Document text append and read",
    input: [String].self
) { input in
    let doc = Automerge.Document()
    let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

    var stringLength = doc.length(obj: text)
    for strChar in input {
        try! doc.spliceText(obj: text, start: stringLength, delete: 0, value: strChar)
        stringLength = doc.length(obj: text)
    }
    let resultingString = try! doc.text(obj: text)
    // precondition(stringLength == input.count) // NOT VALID - difference in UTF-8 codepoints and how strings represent
    // lengths
    blackHole(resultingString)
}

// Execute the benchmark tool with the above definitions.
benchmark.main()
