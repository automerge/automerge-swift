import Automerge
import XCTest

class GetAtTests: XCTestCase {

  func testGetAtInMap() {
    let doc = Document()
    try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("one"))

    let heads = doc.heads()

    try! doc.put(obj: ObjId.ROOT, key: "key", value: .String("two"))

    let result = try! doc.getAt(obj: ObjId.ROOT, key: "key", heads: heads)
    XCTAssertEqual(result!, .Scalar(.String("one")))
  }

  func testGetAtInList() {
    let doc = Document()
    let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)

    try! doc.insert(obj: list, index: 0, value: .String("one"))

    let heads = doc.heads()

    try! doc.put(obj: list, index: 0, value: .String("two"))

    let result = try! doc.getAt(obj: list, index: 0, heads: heads)
    XCTAssertEqual(result!, .Scalar(.String("one")))
  }
}
