import Automerge
import XCTest

class ForkAndMergeTestCase: XCTestCase {
    func testForkAndMerge() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key1", value: "one")

        let doc2 = doc.fork()
        // verify the forked document has a different ActorId
        XCTAssertNotEqual(doc2.actor, doc.actor)

        try doc2.put(obj: ObjId.ROOT, key: "key2", value: "two")

        try doc.put(obj: ObjId.ROOT, key: "key3", value: "three")

        try doc.merge(other: doc2)

        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key1")!, .Scalar("one"))
        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key2")!, .Scalar("two"))
        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key3")!, .Scalar("three"))
    }

    func testForkAt() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key1", value: "one")
        try doc.put(obj: ObjId.ROOT, key: "key2", value: "two")

        let heads = doc.heads()

        try doc.put(obj: ObjId.ROOT, key: "key2", value: "three")

        let forked = try! doc.forkAt(heads: heads)

        XCTAssertEqual(try! forked.get(obj: ObjId.ROOT, key: "key1")!, .Scalar("one"))
        XCTAssertEqual(try! forked.get(obj: ObjId.ROOT, key: "key2")!, .Scalar("two"))
    }
}
