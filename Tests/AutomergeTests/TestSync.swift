import Automerge
import XCTest

class SyncTests: XCTestCase {
    @MainActor func testSyncTwoDocs() {
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
}

func sync(_ doc1: Document, _ sync1: SyncState, _ doc2: Document, _ sync2: SyncState) {
    var quiet = false
    while !quiet {
        quiet = true

        if let msg = doc1.generateSyncMessage(state: sync1) {
            quiet = false
            try! doc2.receiveSyncMessage(state: sync2, message: msg)
        }

        if let msg = doc2.generateSyncMessage(state: sync2) {
            quiet = false
            try! doc1.receiveSyncMessage(state: sync1, message: msg)
        }
    }
}
