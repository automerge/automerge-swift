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
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Benchmarks/SetBenchmarks.swift
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Benchmarks/OrderedSetBenchmarks.swift
// - https://github.com/apple/swift-collections/blob/main/Benchmarks/Benchmarks/DictionaryBenchmarks.swift
//
// There are 4 different default
// 'input generators' registered and immediately available:
//
// Int.self
// [Int].self
// ([Int], [Int]).self
// Insertions.self
//
// The first three result in an array of length 'size' with integers, in shuffled order.
// The last one is a set of array of random numbers where each number is within the
// range 0...i where i is the index of the element order. It's useful for
// testing random insertions.
//
// You can create your own input generators for more custom interactions or
// patterns that you wish to explore.

var benchmark = Benchmark(title: "Automerge")

benchmark.addSimple(
    title: "Array<Int> append",
    input: [Int].self
) { input in
    var list: [Int] = []
    for i in input {
        list.append(i)
    }
    precondition(list.count == input.count)
    blackHole(list)
}

// Execute the benchmark tool with the above definitions.
benchmark.main()
