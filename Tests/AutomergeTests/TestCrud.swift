import Automerge
import XCTest

class CrudTests: XCTestCase {
    func testCreateAndPutGetInRoot() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("value"))
        XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "key")!, .Scalar(.String("value")))
    }

    func testMapCrud() {
        let doc = Document()
        let map = try! doc.putObject(obj: ObjId.ROOT, key: "map", ty: .Map)
        try! doc.put(obj: map, key: "nested", value: .String("nested"))
        XCTAssertEqual(try! doc.get(obj: map, key: "nested")!, .Scalar(.String("nested")))

        try! doc.delete(obj: map, key: "nested")
        XCTAssertEqual(try! doc.get(obj: map, key: "nested"), nil)
    }

    func testTextCrud() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(try! doc.text(obj: text), "hello world!")
    }

    func testListCrud() {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        try! doc.insert(obj: list, index: 0, value: .String("elem1"))
        XCTAssertEqual(try! doc.get(obj: list, index: 0)!, .Scalar(.String("elem1")))

        let nested = try! doc.insertObject(obj: list, index: 1, ty: .Map)
        try! doc.put(obj: nested, key: "nested", value: .String("nested"))
        XCTAssertEqual(try! doc.get(obj: nested, key: "nested"), .Scalar(.String("nested")))

        try! doc.delete(obj: list, index: 1)
        XCTAssertEqual(try! doc.get(obj: list, index: 1), nil)
    }
}
