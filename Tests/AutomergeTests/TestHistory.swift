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
        
        try replicaDoc.put(obj: ObjId.ROOT, key: "key", value: .String("three"))
        XCTAssertEqual(doc.heads().count, 1)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertNotEqual(doc.heads(), replicaDoc.heads())
        
        try doc.merge(other: replicaDoc)
        XCTAssertEqual(doc.heads().count, 1)
        XCTAssertEqual(replicaDoc.heads().count, 1)
        XCTAssertEqual(doc.heads(), replicaDoc.heads())
    }

    func testChangeCountsInHeadsAndChanges() throws {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))
        print(doc.changes())
//        XCTAssertEqual(doc.changes().count, 1)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))
//        XCTAssertEqual(doc.changes().count, 1)
        print(doc.changes())

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("three"))
//        XCTAssertEqual(doc.changes().count, 1)
        print(doc.changes())

    }
}
