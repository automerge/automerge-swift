import Automerge
import XCTest

class HistoryTests: XCTestCase {
    func testChangeCountsInHeads() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))
        var heads = doc.heads()
        XCTAssertEqual(heads.count, 1)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))
        heads = doc.heads()
        XCTAssertEqual(heads.count, 2)
    }

    func testChangeCountsInHeadsAndChanges() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))
        var heads = doc.heads()
        XCTAssertEqual(heads.count, 1)

        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))
        heads = doc.heads()
        XCTAssertEqual(heads.count, 2)

        let changes = doc.changes()
        XCTAssertEqual(changes.count, heads.count)
    }
}
