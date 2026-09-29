@testable import Automerge
import XCTest

class ObjIdTests: XCTestCase {
    struct UnexpectedValue: Error {}

    // Creates a text object in a document whose actor sorts after the actor of a fork, then merges an
    // edit from that fork. Merging adds the fork's actor ahead of the original one, which changes the
    // actor index the document encodes into its object IDs for the original actor.
    func objIdsBeforeAndAfterActorIndexShift(
        opsBeforeObject: Int = 0
    ) throws -> (before: ObjId, after: ObjId, doc: Document) {
        let doc = Document()
        doc.actor = try XCTUnwrap(ActorId(data: Data(repeating: 0xFF, count: 16)))
        for i in 0 ..< opsBeforeObject {
            try doc.put(obj: .ROOT, key: "filler", value: .Int(Int64(i)))
        }
        let before = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)

        let fork = doc.fork()
        fork.actor = try XCTUnwrap(ActorId(data: Data(repeating: 0x00, count: 16)))
        try fork.spliceText(obj: before, start: 0, delete: 0, value: "hello")
        try doc.merge(other: fork)

        let value = try XCTUnwrap(doc.get(obj: .ROOT, key: "text"))
        guard case let .Object(after, .Text) = value else {
            XCTFail("expected a text object at the key 'text', got \(value)")
            throw UnexpectedValue()
        }
        return (before, after, doc)
    }

    func testSameObjectIsEqualAfterActorIndexChanges() throws {
        let (before, after, doc) = try objIdsBeforeAndAfterActorIndexShift()

        // Confirm the scenario actually changed the encoded bytes, so the assertions below mean something.
        XCTAssertNotEqual(before.bytes, after.bytes)

        XCTAssertEqual(before, after)
        XCTAssertEqual(before.hashValue, after.hashValue)
        XCTAssertTrue(Set([before]).contains(after))
        XCTAssertEqual([before: "text"][after], "text")
        XCTAssertEqual(try doc.text(obj: before), try doc.text(obj: after))
    }

    func testSameObjectIsEqualWithMultiByteCounter() throws {
        // Enough operations before the object that its counter needs a multi-byte uLEB128 encoding.
        let (before, after, _) = try objIdsBeforeAndAfterActorIndexShift(opsBeforeObject: 300)

        XCTAssertNotEqual(before.bytes, after.bytes)
        XCTAssertEqual(before, after)
        XCTAssertEqual(before.hashValue, after.hashValue)
    }

    func testDifferentObjectsAreNotEqual() throws {
        let doc = Document()
        let first = try doc.putObject(obj: .ROOT, key: "first", ty: .Map)
        let second = try doc.putObject(obj: .ROOT, key: "second", ty: .Map)
        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(first, ObjId.ROOT)

        // Same counter, different actors.
        let otherDoc = Document()
        let otherFirst = try otherDoc.putObject(obj: .ROOT, key: "first", ty: .Map)
        XCTAssertNotEqual(first, otherFirst)

        XCTAssertEqual(ObjId.ROOT, ObjId.ROOT)
        XCTAssertEqual(Set([first, second, otherFirst, ObjId.ROOT]).count, 4)
    }
}
