import Automerge
import XCTest

class LengthTestCase: XCTestCase {

  func testLength() {
    let doc = Document()
    let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
    try! doc.insert(obj: list, index: 0, value: .String("one"))
    try! doc.insert(obj: list, index: 1, value: .String("two"))

    XCTAssertEqual(try! doc.length(obj: list), 2)
  }

  func testLengthAt() {
    let doc = Document()
    let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
    try! doc.insert(obj: list, index: 0, value: .String("one"))
    try! doc.insert(obj: list, index: 1, value: .String("two"))

    let heads = doc.heads()

    try! doc.insert(obj: list, index: 2, value: .String("three"))

    XCTAssertEqual(doc.lengthAt(obj: list, heads: heads), 2)
  }
}
