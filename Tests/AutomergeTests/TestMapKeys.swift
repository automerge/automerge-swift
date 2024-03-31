import Automerge
import XCTest

class MapKeysTests: XCTestCase {
    func testMapKeys() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key1", value: "one")
        try! doc.put(obj: ObjId.ROOT, key: "key2", value: "two")

        let keys = doc.keys(obj: ObjId.ROOT)
        XCTAssertEqual(keys, ["key1", "key2"])
    }

    func testMapKeysAt() {
        let doc = Document()
        try! doc.put(obj: ObjId.ROOT, key: "key1", value: "one")
        try! doc.put(obj: ObjId.ROOT, key: "key2", value: "two")

        let heads = doc.heads()

        try! doc.put(obj: ObjId.ROOT, key: "key3", value: "two")
        let keys = doc.keysAt(obj: ObjId.ROOT, heads: heads)
        XCTAssertEqual(keys, ["key1", "key2"])
    }
}
