import Automerge
import Foundation
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

    func testObjIdsStayEqualWhenAMergeMovesTheirActor() throws {
        // The fork's actor sorts before the document's, so merging it moves the document's actor
        // in its list of actors. An object made before the merge must keep an equal ID.
        let doc = Document()
        doc.actor = ActorId(data: Data(repeating: 0xFF, count: 16))!
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

        let fork = doc.fork()
        fork.actor = ActorId(data: Data(repeating: 0x00, count: 16))!
        try fork.spliceText(obj: text, start: 0, delete: 0, value: "hello")
        let patches = try doc.mergeWithPatches(other: fork)

        guard case let .Object(textAfterMerge, .Text) = try doc.get(obj: ObjId.ROOT, key: "text") else {
            return XCTFail("Expected the text object")
        }
        XCTAssertEqual(textAfterMerge, text)
        XCTAssertEqual(textAfterMerge.hashValue, text.hashValue)
        XCTAssertEqual(Set([text, textAfterMerge]).count, 1)
        XCTAssertEqual(patches.map(\.action), [.SpliceText(obj: text, index: 0, value: "hello", marks: [:])])

        // The ID from before the merge still finds the object in both documents.
        XCTAssertEqual(try doc.text(obj: text), "hello")
        XCTAssertEqual(try fork.text(obj: text), "hello")
    }
}
