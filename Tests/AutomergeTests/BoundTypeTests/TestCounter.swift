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
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))

        let doc2 = doc1.fork()

        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(3))
        _ = doc1.save()
        try doc2.put(obj: ObjId.ROOT, key: "counter", value: .Counter(-1))
        _ = doc2.save()

        let counter1 = try doc1.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter1 == Value.Scalar(.Counter(3)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter1!) != \(Value.Scalar(.Counter(3)))]"
        )
        let counter2 = try doc2.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter2 == Value.Scalar(.Counter(-1)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter2!) != \(Value.Scalar(.Counter(-1)))]"
        )

        try doc1.merge(other: doc2)

        let counter3 = try doc1.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter3 == Value.Scalar(.Counter(2)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter3!) != \(Value.Scalar(.Counter(2)))]"
        )
        let counter4 = try doc2.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter4 == Value.Scalar(.Counter(-1)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter4!) != \(Value.Scalar(.Counter(-1)))]"
        )

        try doc2.merge(other: doc1)

        let counter5 = try doc1.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter5 == Value.Scalar(.Counter(2)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter5!) != \(Value.Scalar(.Counter(2)))]"
        )

        let counter6 = try doc2.get(obj: ObjId.ROOT, key: "counter")
        assertNonFatal(
            counter6 == Value.Scalar(.Counter(2)),
            "Test failure illustrating put doesn't merge the same as increment [\(counter6!) != \(Value.Scalar(.Counter(2)))]"
        )
    }
}

private extension XCTestCase {
    func assertNonFatal(_ condition: Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
        guard !condition else { return }
        print("\(message) at \(file):\(line)")
    }
}
