import Automerge
import XCTest

class ForkAndMergeTestCase: XCTestCase {
    func testForkAndMerge() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key1", value: .String("one"))

        let doc2 = doc.fork()
        // verify the forked document has a different ActorId
        XCTAssertNotEqual(doc2.actor, doc.actor)

        try doc2.put(obj: ObjId.ROOT, key: "key2", value: .String("two"))

        try doc.put(obj: ObjId.ROOT, key: "key3", value: .String("three"))

        try doc.merge(other: doc2)

        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key1")!, .Scalar(.String("one")))
        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key2")!, .Scalar(.String("two")))
        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key3")!, .Scalar(.String("three")))
    }

    func testForkAt() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key1", value: .String("one"))
        try doc.put(obj: ObjId.ROOT, key: "key2", value: .String("two"))

        let heads = doc.heads()

        try doc.put(obj: ObjId.ROOT, key: "key2", value: .String("three"))

        let forked = try! doc.forkAt(heads: heads)

        XCTAssertEqual(try! forked.get(obj: ObjId.ROOT, key: "key1")!, .Scalar(.String("one")))
        XCTAssertEqual(try! forked.get(obj: ObjId.ROOT, key: "key2")!, .Scalar(.String("two")))
    }
}
