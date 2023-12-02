@testable import Automerge
import XCTest

extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02hhx", $0) }.joined()
    }
}

class PatchesTestCase: XCTestCase {
    func testMergeReturningPatches() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("value1"))

        let doc2 = doc.fork()
        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))

        let patches = try! doc.mergeWithPatches(other: doc2)

        XCTAssertEqual(
            patches,
            [
                Patch(
                    action: .Put(ObjId.ROOT, .Key("key2"), .Scalar(.String("value2"))),
                    path: []
                ),
            ]
        )
    }

    func testReceiveSyncMessageWithPatches() throws {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("value1"))

        // create a second, identical, document
        let doc2 = doc.fork()

        // get in sync so that the next message we generate is the one which contains the next change
        let state1 = SyncState()
        let state2 = SyncState()

        sync(doc, state1, doc2, state2)
        let doc1_serialized = doc.save()
        let doc2_serialized = doc2.save()
        XCTAssertEqual(doc1_serialized, doc2_serialized)

        let msg_before_update = doc2.generateSyncMessage(state: state2)

        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))
        // now generate the message
        let optional_msg = doc2.generateSyncMessage(state: state2)
        XCTAssertNotEqual(msg_before_update, optional_msg)

        // The important thing to verify is that the message isn't nil - which
        // indicates that there are changes pending. With this single change
        // scenario, there's a roughly 1:100 chance that the sync message _will not_
        // include the patches to bring everything up to speed, since it's a probabilistic
        // scenario (bloom filter under the covers)
        XCTAssertNotNil(optional_msg)

        let msg = try XCTUnwrap(optional_msg)
        // print("  Sync Msg: \(msg.count) bytes: \(msg.hexEncodedString())")

        let patches = try doc.receiveSyncMessageWithPatches(state: state1, message: msg)

        let within_expected_count_values = (patches.isEmpty || patches.count == 1)
        XCTAssertTrue(within_expected_count_values)
        if patches.count == 1 {
            XCTAssertEqual(
                patches,
                [
                    Patch(
                        action: .Put(ObjId.ROOT, .Key("key2"), .Scalar(.String("value2"))),
                        path: []
                    ),
                ]
            )
        }
    }

    func testApplyEncodedChangesWithPatches() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("value1"))

        let doc2 = doc.fork()
        let heads = doc2.heads()

        try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))
        let encoded = try! doc2.encodeChangesSince(heads: heads)

        let patches = try! doc.applyEncodedChangesWithPatches(encoded: encoded)

        XCTAssertEqual(
            patches,
            [
                Patch(
                    action: .Put(ObjId.ROOT, .Key("key2"), .Scalar(.String("value2"))),
                    path: []
                ),
            ]
        )
    }
}
