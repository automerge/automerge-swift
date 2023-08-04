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

    func testCounterMergingWithPut() throws {
        XCTExpectFailure(
            "Test failure illustrating put doesn't merge the same as increment",
            options: XCTExpectedFailure.Options()
        )
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))

        let doc2 = doc1.fork()

        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(3))
        _ = doc1.save()
        try doc2.put(obj: ObjId.ROOT, key: "counter", value: .Counter(-1))
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
}
