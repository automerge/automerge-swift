@testable import Automerge
import XCTest

class CounterTestCase: XCTestCase {
    func testCounterMergingWithIncrement() throws {
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))

        let doc2 = doc1.fork()

        try doc1.increment(obj: ObjId.ROOT, key: "counter", by: 3)
        _ = doc1.save()
        try doc2.increment(obj: ObjId.ROOT, key: "counter", by: -1)
        _ = doc2.save()

        XCTAssertEqual(try doc1.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(3)))
        XCTAssertEqual(try doc2.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(-1)))

        try doc1.merge(other: doc2)

        XCTAssertEqual(try doc1.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(2)))
        XCTAssertEqual(try doc2.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(-1)))

        try doc2.merge(other: doc1)

        XCTAssertEqual(try doc1.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(2)))
        XCTAssertEqual(try doc2.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(2)))
    }

    /// Unlike concurrent increments, concurrent puts of a counter don't add up: they conflict, and the
    /// put from the actor that sorts last wins.
    func testCounterMergingWithPut() throws {
        let doc1 = Document()
        doc1.actor = try XCTUnwrap(ActorId(data: Data(repeating: 1, count: 16)))
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))

        let doc2 = doc1.fork()
        doc2.actor = try XCTUnwrap(ActorId(data: Data(repeating: 2, count: 16)))

        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(3))
        try doc2.put(obj: ObjId.ROOT, key: "counter", value: .Counter(-1))

        XCTAssertEqual(try doc1.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(3)))
        XCTAssertEqual(try doc2.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(-1)))

        try doc1.merge(other: doc2)
        try doc2.merge(other: doc1)

        for doc in [doc1, doc2] {
            XCTAssertEqual(try doc.get(obj: ObjId.ROOT, key: "counter"), Value.Scalar(.Counter(-1)))
            XCTAssertEqual(
                try doc.getAll(obj: ObjId.ROOT, key: "counter"),
                [Value.Scalar(.Counter(3)), Value.Scalar(.Counter(-1))]
            )
        }
    }
}
