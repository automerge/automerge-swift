import Automerge
import XCTest

class SpliceTestCase: XCTestCase {

  func testSplice() {
    let doc = Document()
    let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
    try! doc.insert(obj: list, index: 0, value: .Uint(1))
    try! doc.insert(obj: list, index: 1, value: .Uint(2))
    try! doc.insert(obj: list, index: 2, value: .Uint(3))
    try! doc.splice(obj: list, start: 1, delete: 1, values: [.Uint(4), .Uint(5)])

    var result: [Value] = []
    for i in (0 as UInt64)...3 {
      result.append(try! doc.get(obj: list, index: i)!)
    }
    XCTAssertEqual(
      result, [.Scalar(.Uint(1)), .Scalar(.Uint(4)), .Scalar(.Uint(5)), .Scalar(.Uint(3))])
  }
}
