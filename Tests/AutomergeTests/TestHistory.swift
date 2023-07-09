import Automerge
import XCTest

class HistoryTests: XCTestCase {
    func testHeadsDuringChanges() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))
        XCTAssertEqual(doc.heads().count, 1)

        try doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))
        XCTAssertEqual(doc.heads().count, 1)

        let replicaDoc = doc.fork()
        XCTAssertEqual(doc.heads().count, 1)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertEqual(doc.heads(), replicaDoc.heads())

        try doc.put(obj: ObjId.ROOT, key: "newkey", value: .String("beta"))
        try replicaDoc.put(obj: ObjId.ROOT, key: "newkey", value: .String("alpha"))
        XCTAssertEqual(doc.heads().count, 1)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertNotEqual(doc.heads(), replicaDoc.heads())

        // The number of ChangeHash values returned from heads() is the
        // number of concurrent changes to the document that it's aware of.

        // In a linear document, the number of heads is 1.
        try doc.merge(other: replicaDoc)
        XCTAssertEqual(doc.heads().count, 2)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertNotEqual(doc.heads(), replicaDoc.heads())
    }

    func testChangeCountsInHeadsAndChanges() throws {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))
        XCTAssertEqual(doc.changes().count, 1)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))
        XCTAssertEqual(doc.changes().count, 2)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("three"))
        XCTAssertEqual(doc.changes().count, 3)

        let replicaDoc = doc.fork()
        XCTAssertEqual(doc.heads(), replicaDoc.heads())
        XCTAssertEqual(doc.changes(), replicaDoc.changes())
    }
}
