import Automerge
import XCTest

class MapEntriesTests: XCTestCase {

  func testMapEntries() {
    let doc = Document()
    try! doc.put(obj: ObjId.ROOT, key: "key1", value: .String("one"))
    try! doc.put(obj: ObjId.ROOT, key: "key2", value: .Uint(1))

    let result = try! doc.mapEntries(obj: ObjId.ROOT)
    XCTAssert(
      result.elementsEqual(
        [("key1", .Scalar(.String("one"))), ("key2", .Scalar(.Uint(1)))], by: ==))
  }

  func testMapEntriesAt() {
    let doc = Document()
    try! doc.put(obj: ObjId.ROOT, key: "key1", value: .String("one"))
    try! doc.put(obj: ObjId.ROOT, key: "key2", value: .Uint(1))

    let heads = doc.heads()

    try! doc.put(obj: ObjId.ROOT, key: "key3", value: .Uint(1))

    let result = try! doc.mapEntriesAt(obj: ObjId.ROOT, heads: heads)
    XCTAssert(
      result.elementsEqual(
        [("key1", .Scalar(.String("one"))), ("key2", .Scalar(.Uint(1)))], by: ==))
  }
}
