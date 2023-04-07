import Automerge
import XCTest

class ObjectTypeTestCase: XCTestCase {
    func testRootObjectType() {
        let doc = Document()
        XCTAssertEqual(doc.objectType(obj: ObjId.ROOT), .Map)
    }

    func testCheckingListObjectType() {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        XCTAssertEqual(doc.objectType(obj: list), .List)
    }

    func testCheckingMapObjectType() {
        let doc = Document()
        let map = try! doc.putObject(obj: ObjId.ROOT, key: "map", ty: .Map)
        XCTAssertEqual(doc.objectType(obj: map), .Map)
    }

    func testCheckingTextObjectType() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "map", ty: .Text)
        XCTAssertEqual(doc.objectType(obj: text), .Text)
    }
}
