import Automerge
import XCTest
#if canImport(Combine)
import Combine
#endif

/// The object graphs most likely to form reference cycles: documents and their forks, observers, and
/// the bound types that hold on to a document. Each object must be freed once the test lets go of it.
final class MemoryLeakTests: XCTestCase {
    func testDocumentsAndForksAreFreed() throws {
        let doc = Document()
        try doc.put(obj: .ROOT, key: "key", value: .String("value"))
        let fork = doc.fork()
        try fork.put(obj: .ROOT, key: "other", value: .Int(1))
        try doc.merge(other: fork)
        let historical = try doc.forkAt(heads: fork.heads())
        let reloaded = try Document(doc.save())
        for instance in [doc, fork, historical, reloaded] {
            trackForMemoryLeak(instance: instance)
        }
    }

    func testSyncedDocumentsAreFreed() throws {
        let doc1 = Document()
        let doc2 = Document()
        try doc1.put(obj: .ROOT, key: "key", value: .String("value"))
        let (state1, state2) = (SyncState(), SyncState())
        while let message = doc1.generateSyncMessage(state: state1) {
            try doc2.receiveSyncMessage(state: state2, message: message)
            guard let reply = doc2.generateSyncMessage(state: state2) else { break }
            try doc1.receiveSyncMessage(state: state1, message: reply)
        }
        trackForMemoryLeak(instance: doc1)
        trackForMemoryLeak(instance: doc2)
    }

    // While a Counter or AutomergeText is bound, each change to the document starts a task that
    // compares the document's value with the bound one, and the task holds the document and the bound
    // instance until it finishes. So they're freed shortly after the last reference goes, rather than
    // immediately.

    func testBoundCounterIsFreed() throws {
        try assertEventuallyFreed {
            let doc = Document()
            try doc.put(obj: .ROOT, key: "count", value: .Counter(0))
            let counter = Counter()
            try counter.bind(doc: doc, path: ".count")
            counter.value += 1
            XCTAssertEqual(try doc.get(obj: .ROOT, key: "count"), .Scalar(.Counter(1)))
            return [doc, counter]
        }
    }

    func testBoundTextIsFreed() throws {
        try assertEventuallyFreed {
            let doc = Document()
            let textId = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)
            let text = AutomergeText()
            try text.bind(doc: doc, id: textId)
            text.value = "hello"
            try doc.spliceText(obj: textId, start: 5, delete: 0, value: "!")
            XCTAssertEqual(text.value, "hello!")
            return [doc, text]
        }
    }

    /// Asserts that every object `makeObjects` returns is freed within `timeout` of the closure returning.
    private func assertEventuallyFreed(
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ makeObjects: () throws -> [AnyObject]
    ) throws {
        let references = try makeObjects().map { WeakReference($0) }
        let deadline = Date().addingTimeInterval(timeout)
        while references.contains(where: { $0.object != nil }), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
        }
        for reference in references where reference.object != nil {
            XCTFail("\(reference.description) was never freed", file: file, line: line)
        }
    }

    #if canImport(Combine)
    func testObservedDocumentIsFreedAfterCancelling() throws {
        let doc = Document()
        var changes = 0
        let subscription = doc.objectWillChange.sink { _ in changes += 1 }
        try doc.put(obj: .ROOT, key: "key", value: .String("value"))
        XCTAssertGreaterThan(changes, 0)
        subscription.cancel()
        trackForMemoryLeak(instance: doc)
    }
    #endif
}

private final class WeakReference {
    weak var object: AnyObject?
    let description: String

    init(_ object: AnyObject) {
        self.object = object
        description = String(describing: type(of: object))
    }
}
