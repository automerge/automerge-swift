import Automerge
import XCTest

class TextTestCase: XCTestCase {
    func testGetText() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(try! doc.text(obj: text), "hello world!")
    }

    func testGetTextAt() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")

        let heads = doc.heads()

        let doc2 = doc.fork()

        try! doc2.spliceText(obj: text, start: 6, delete: 0, value: "wonderful ")
        try! doc.spliceText(obj: text, start: 0, delete: 5, value: "Greetings")

        try! doc.merge(other: doc2)

        XCTAssertEqual(try! doc.text(obj: text), "Greetings wonderful world!")
        XCTAssertEqual(try! doc.textAt(obj: text, heads: heads), "hello world!")
    }
}
