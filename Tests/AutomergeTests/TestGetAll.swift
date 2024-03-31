import Automerge
import XCTest

class GetAllTestCase: XCTestCase {
    func testGetAllInMap() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: "value1")

        let doc2 = doc.fork()
        try! doc2.put(obj: ObjId.ROOT, key: "key", value: "value2")
        try! doc.put(obj: ObjId.ROOT, key: "key", value: "value3")

        try! doc.merge(other: doc2)

        let values = try! doc.getAll(obj: ObjId.ROOT, key: "key")
        XCTAssertEqual(values, Set([.Scalar("value2"), .Scalar("value3")]))
    }

    func testGetAllInList() {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        try! doc.insert(obj: list, index: 0, value: "value1")

        let doc2 = doc.fork()
        try! doc2.put(obj: list, index: 0, value: "value2")
        try! doc.put(obj: list, index: 0, value: "value3")

        try! doc.merge(other: doc2)

        let values = try! doc.getAll(obj: list, index: 0)
        XCTAssertEqual(values, Set([.Scalar("value2"), .Scalar("value3")]))
    }

    func testGetAllAtInMap() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key", value: "value1")

        let doc2 = doc.fork()
        try! doc2.put(obj: ObjId.ROOT, key: "key", value: "value2")
        try! doc.put(obj: ObjId.ROOT, key: "key", value: "value3")

        try! doc.merge(other: doc2)

        let heads = doc.heads()

        try! doc.put(obj: ObjId.ROOT, key: "key", value: "value4")

        let values = try! doc.getAllAt(obj: ObjId.ROOT, key: "key", heads: heads)
        XCTAssertEqual(values, Set([.Scalar("value2"), .Scalar("value3")]))
    }

    func testGetAllAtInList() {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        try! doc.insert(obj: list, index: 0, value: "value1")

        let doc2 = doc.fork()
        try! doc2.put(obj: list, index: 0, value: "value2")
        try! doc.put(obj: list, index: 0, value: "value3")

        try! doc.merge(other: doc2)

        let heads = doc.heads()

        try! doc.put(obj: list, index: 0, value: "value4")

        let values = try! doc.getAllAt(obj: list, index: 0, heads: heads)
        XCTAssertEqual(values, Set([.Scalar("value2"), .Scalar("value3")]))
    }
}
