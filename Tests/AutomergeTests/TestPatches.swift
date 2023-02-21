import Automerge
import XCTest

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
        )
      ])
  }

  func testReceiveSyncMessageWithPatches() {
    let doc = Document()
    try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("value1"))

    let doc2 = doc.fork()

    //get in sync so that the next message we generate is the one which contains the next change
    let state1 = SyncState()
    let state2 = SyncState()

    sync(doc, state1, doc2, state2)

    try! doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("value2"))
    // now generate the message
    let msg = doc2.generateSyncMessage(state: state2)!

    let patches = try! doc.receiveSyncMessageWithPatches(state: state1, message: msg)

    XCTAssertEqual(
      patches,
      [
        Patch(
          action: .Put(ObjId.ROOT, .Key("key2"), .Scalar(.String("value2"))),
          path: []
        )
      ])
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
        )
      ])
  }

}
