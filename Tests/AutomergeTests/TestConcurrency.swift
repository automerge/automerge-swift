// Dispatch isn't available on WASI, where Document runs without its internal queue.
#if !os(WASI)
import Automerge
import Foundation
import XCTest
#if canImport(Combine)
import Combine
#endif

// Document and SyncState are marked @unchecked Sendable and serialize access internally. These tests
// use them from many threads at once and check that no update is lost. Running them under
// ThreadSanitizer (`swift test --sanitize=thread`) also checks the Swift side for data races.
private let threadCount = 8
private let iterationsPerThread = 200

class ConcurrencyTests: XCTestCase {
    struct ConcurrentWorkDidNotFinish: Error {}

    /// Runs `body` on `iterations` threads at once.
    ///
    /// Waits with a timeout, so a locking regression fails the test instead of hanging the test run. On
    /// timeout it throws, so the caller stops before touching shared objects whose lock a stuck worker may
    /// still hold.
    func performConcurrently(
        iterations: Int = threadCount,
        timeout: TimeInterval = 30,
        _ body: @escaping @Sendable (Int) -> Void
    ) throws {
        let finished = XCTestExpectation(description: "concurrent work finished")
        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: body)
            finished.fulfill()
        }
        let result = XCTWaiter.wait(for: [finished], timeout: timeout)
        guard result == .completed else {
            XCTFail("concurrent work did not finish within \(timeout) seconds (\(result))")
            throw ConcurrentWorkDidNotFinish()
        }
    }

    func testConcurrentMutationsAreNotLost() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "count", value: .Counter(0))
        let list = try doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let peer = doc.fork()

        let errors = ErrorCollector()
        try performConcurrently { thread in
            for i in 0 ..< iterationsPerThread {
                do {
                    try doc.increment(obj: ObjId.ROOT, key: "count", by: 1)
                    try doc.insert(obj: list, index: 0, value: .Int(Int64(thread * iterationsPerThread + i)))
                    try doc.spliceText(obj: text, start: 0, delete: 0, value: "x")
                    _ = try doc.get(obj: ObjId.ROOT, key: "count")
                    _ = doc.length(obj: list)
                    _ = try doc.text(obj: text)
                    if i % 50 == 0 {
                        _ = doc.save()
                        _ = doc.generateSyncMessage(state: SyncState())
                        try peer.merge(other: doc)
                    }
                } catch {
                    errors.append(error)
                }
            }
        }

        XCTAssertEqual(errors.all.count, 0, "\(errors.all)")
        let total = threadCount * iterationsPerThread
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "count"), .Scalar(.Counter(Int64(total))))
        XCTAssertEqual(doc.length(obj: list), UInt64(total))
        XCTAssertEqual(try doc.text(obj: text), String(repeating: "x", count: total))

        // Every inserted value is present exactly once.
        let values = try (0 ..< UInt64(total)).map { index -> Int64 in
            guard case let .Scalar(.Int(value)) = try XCTUnwrap(doc.get(obj: list, index: index)) else {
                XCTFail("unexpected value at index \(index)")
                return -1
            }
            return value
        }
        XCTAssertEqual(Set(values), Set(0 ..< Int64(total)))

        // The saved document round-trips with everything in it.
        let reloaded = try Document(doc.save())
        XCTAssertEqual(reloaded.heads(), doc.heads())
        XCTAssertEqual(reloaded.length(obj: list), UInt64(total))

        // The peer that was merged into from the worker threads ends up with the same document.
        try peer.merge(other: doc)
        XCTAssertEqual(peer.heads(), doc.heads())
        XCTAssertEqual(try peer.get(obj: ObjId.ROOT, key: "count"), .Scalar(.Counter(Int64(total))))
        XCTAssertEqual(peer.length(obj: list), UInt64(total))
        let peerValues = try (0 ..< UInt64(total)).map { try peer.get(obj: list, index: $0) }
        let docValues = try (0 ..< UInt64(total)).map { try doc.get(obj: list, index: $0) }
        XCTAssertEqual(peerValues, docValues)
        XCTAssertEqual(try peer.text(obj: text), try doc.text(obj: text))
    }

    func testConcurrentUseOfSharedSyncState() throws {
        let doc1 = Document()
        for i in 0 ..< 100 {
            try doc1.put(obj: ObjId.ROOT, key: "key\(i)", value: .Int(Int64(i)))
        }
        let sharedState = SyncState()

        try performConcurrently { _ in
            for _ in 0 ..< 50 {
                if let message = doc1.generateSyncMessage(state: sharedState) {
                    try? Document().receiveSyncMessage(state: SyncState(), message: message)
                }
                _ = sharedState.encode()
                _ = sharedState.theirHeads
            }
        }

        // The shared state is still usable for a real sync afterwards.
        sharedState.reset()
        let doc2 = Document()
        sync(doc1, sharedState, doc2, SyncState())
        XCTAssertEqual(doc2.keys(obj: ObjId.ROOT).count, 100)
    }

    #if canImport(Combine)
    func testConcurrentMutationsWithObserversDoNotDeadlock() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "count", value: .Counter(0))

        let willChangeCount = CallCounter()
        let didChangeCount = CallCounter()
        let willChange = doc.objectWillChange.sink {
            // Read from the document inside the notification, as SwiftUI views do.
            _ = doc.heads()
            willChangeCount.increment()
        }
        let didChange = doc.objectDidChange.sink {
            _ = try? doc.get(obj: ObjId.ROOT, key: "count")
            didChangeCount.increment()
        }

        try performConcurrently { _ in
            for _ in 0 ..< iterationsPerThread {
                try? doc.increment(obj: ObjId.ROOT, key: "count", by: 1)
            }
        }

        let total = threadCount * iterationsPerThread
        XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "count"), .Scalar(.Counter(Int64(total))))
        XCTAssertEqual(willChangeCount.value, total)
        XCTAssertEqual(didChangeCount.value, total)
        withExtendedLifetime((willChange, didChange)) {}
    }
    #endif
}

private final class ErrorCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var errors: [Error] = []

    func append(_ error: Error) {
        lock.lock()
        defer { lock.unlock() }
        errors.append(error)
    }

    var all: [Error] {
        lock.lock()
        defer { lock.unlock() }
        return errors
    }
}

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        count += 1
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }
}
#endif
