import Automerge
import XCTest

class IncrementTestCase: XCTestCase {

  func testIncrementInMap() {
    let doc = Document()
    try! doc.put(obj: ObjId.ROOT, key: "counter", value: .Counter(1))

    let doc2 = doc.fork()
    try! doc2.increment(obj: ObjId.ROOT, key: "counter", by: 1)

    try! doc.increment(obj: ObjId.ROOT, key: "counter", by: 3)

    try! doc.merge(other: doc2)

    XCTAssertEqual(try! doc.get(obj: ObjId.ROOT, key: "counter")!, .Scalar(.Counter(5)))
  }

  func testIncrementInList() {
    let doc = Document()
    let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
    try! doc.insert(obj: list, index: 0, value: .Counter(1))

    let doc2 = doc.fork()
    try! doc2.increment(obj: list, index: 0, by: 1)

    try! doc.increment(obj: list, index: 0, by: 3)

    try! doc.merge(other: doc2)

    XCTAssertEqual(try! doc.get(obj: list, index: 0)!, .Scalar(.Counter(5)))
  }
}
