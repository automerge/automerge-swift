import Automerge
import XCTest

class ValuesTestCase: XCTestCase {
    func testValues() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key1", value: "one")
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)

        XCTAssertEqual(
            try! doc.values(obj: ObjId.ROOT), [.Scalar("one"), .Object(list, .List)]
        )
    }

    func testValuesAt() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key1", value: "one")
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)

        let heads = doc.heads()

        try! doc.put(obj: ObjId.ROOT, key: "key2", value: "two")

        XCTAssertEqual(
            try! doc.valuesAt(obj: ObjId.ROOT, heads: heads),
            [.Scalar("one"), .Object(list, .List)]
        )
    }
}
