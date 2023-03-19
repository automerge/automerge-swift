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

    func testRepeatedTextInsertion() throws {
        let characterCollection: [String] =
            "a bcdef ghijk lmnop qrstu vwxyz ABCD EFGHI JKLMN OPQRS TUVWX YZ😀😎🤓⚁ ♛⛺︎🕰️⏰⏲️ ⏱️🧭".map { char in
                String(char)
            }

        let doc = Automerge.Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        var stringLength = doc.length(obj: text)
        XCTAssertEqual(stringLength, 0)

        for _ in 0 ... 5000 {
            let stringToInsert = characterCollection.randomElement() ?? " "
            stringLength = doc.length(obj: text)
            print("Adding '\(stringToInsert)' at \(stringLength)")
            try! doc.spliceText(obj: text, start: stringLength, delete: 0, value: stringToInsert)
            print("Combined text: \(try! doc.text(obj: text))")
        }

        // flaky assertion, don't do it :: because length is in UTF-8 codepoints, not!!! grapheme clusters.
        // XCTAssertEqual(stringLength, 5)
    }
}
