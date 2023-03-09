import Automerge

@main
struct CollectionBenchmarks {
    private(set) var text = "Hello, World!"

    static func main() {
        print(CollectionBenchmarks().text)
    }
}
