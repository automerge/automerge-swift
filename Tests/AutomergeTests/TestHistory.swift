import Automerge
import XCTest

class HistoryTests: XCTestCase {
    func testHeadsDuringChanges() throws {
        let doc = Document()
        try doc.put(obj: ObjId.ROOT, key: "key", value: "one")
        XCTAssertEqual(doc.heads().count, 1)

        try doc.put(obj: ObjId.ROOT, key: "key", value: "two")
        XCTAssertEqual(doc.heads().count, 1)

        let replicaDoc = doc.fork()
        XCTAssertEqual(doc.heads().count, 1)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertEqual(doc.heads(), replicaDoc.heads())

        try doc.put(obj: ObjId.ROOT, key: "newkey", value: "beta")
        try replicaDoc.put(obj: ObjId.ROOT, key: "newkey", value: "alpha")
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
        try! doc.put(obj: ObjId.ROOT, key: "key", value: "one")
        XCTAssertEqual(doc.getHistory().count, 1)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: "two")
        XCTAssertEqual(doc.getHistory().count, 2)

        let replicaDoc = doc.fork()
        XCTAssertEqual(doc.heads(), replicaDoc.heads())
        XCTAssertEqual(doc.getHistory(), replicaDoc.getHistory())

        try! doc.put(obj: ObjId.ROOT, key: "key", value: "three")
        XCTAssertEqual(doc.getHistory().count, 3)
        XCTAssertEqual(replicaDoc.getHistory().count, 2)

        try doc.put(obj: ObjId.ROOT, key: "newkey", value: "beta")
        try replicaDoc.put(obj: ObjId.ROOT, key: "newkey", value: "alpha")
        XCTAssertEqual(doc.getHistory().count, 4)
        XCTAssertEqual(replicaDoc.getHistory().count, 3)

        try doc.merge(other: replicaDoc)
        XCTAssertEqual(doc.getHistory().count, 5)
        XCTAssertEqual(replicaDoc.getHistory().count, 3)
    }
}
