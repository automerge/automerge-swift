#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import Automerge
import XCTest

class MemoryLeakTests: XCTestCase {
    @MainActor func testMemoryLeakOnSyncTwoDocs() {
        let doc1 = Document()
        trackForMemoryLeak(instance: doc1)
        let syncState1 = SyncState()

        let doc2 = Document()
        trackForMemoryLeak(instance: doc2)
        let syncState2 = SyncState()

        try! doc1.put(obj: ObjId.ROOT, key: "key1", value: .String("value1"))
        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))

        sync(doc1, syncState1, doc2, syncState2)

        for doc in [doc1, doc2] {
            XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key1")!, .Scalar(.String("value1")))
            XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key2")!, .Scalar(.String("value2")))
        }

        XCTAssertNotNil(syncState1.theirHeads)
    }

    @MainActor func testEncodeDoesntLeak() throws {
        let doc = Document()
        trackForMemoryLeak(instance: doc)

        struct SimpleStruct: Codable, Equatable {
            let name: String
            let notes: AutomergeText
        }

        let automergeEncoder = AutomergeEncoder(doc: doc)
        let automergeDecoder = AutomergeDecoder(doc: doc)

        let sample = SimpleStruct(
            name: "henry",
            notes: AutomergeText("Something wicked this way comes.")
        )

        let pathToTry: [AnyCodingKey] = [
            AnyCodingKey("example"),
            AnyCodingKey(0),
        ]
        try automergeEncoder.encode(sample, at: pathToTry)

        XCTAssertNotNil(try doc.get(obj: ObjId.ROOT, key: "example"))
        let foo = try doc.lookupPath(path: ".example.[0]")
        XCTAssertNotNil(foo)

        let decodedStruct = try automergeDecoder.decode(SimpleStruct.self, from: pathToTry)
        XCTAssertEqual(decodedStruct, sample)
    }
}
#endif
