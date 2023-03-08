import Automerge
import XCTest

class PathTestCase: XCTestCase {
    func testPath() {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let path = try! doc.path(obj: nestedMap)
        XCTAssertEqual(
            path,
            [
                PathElement(
                    obj: ObjId.ROOT,
                    prop: .Key("list")
                ),
                PathElement(
                    obj: list,
                    prop: .Index(0)
                ),
            ]
        )
    }
}
