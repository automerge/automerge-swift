import Automerge
import XCTest

class TextTestCase: XCTestCase {
    func testGetText() throws {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(try! doc.text(obj: text), "hello world!")
    }

    func testGetTextAt() throws {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")

        let heads = doc.heads()

        let doc2 = doc.fork()

        try doc2.spliceText(obj: text, start: 6, delete: 0, value: "wonderful ")
        try doc.spliceText(obj: text, start: 0, delete: 5, value: "Greetings")

        try doc.merge(other: doc2)

        XCTAssertEqual(try! doc.text(obj: text), "Greetings wonderful world!")
        XCTAssertEqual(try! doc.textAt(obj: text, heads: heads), "hello world!")
    }

    func testTextUpdate() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(try doc.text(obj: text), "hello world!")

        try doc.updateText(obj: text, value: "A new text entry.")
        XCTAssertEqual(try doc.text(obj: text), "A new text entry.")
    }

    func testTextCursor() throws {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")

        let heads = doc.heads()

        let c_hello = try! doc.cursorSelection(obj: text, position: 0)
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_hello), 0)

        let c_world = try! doc.cursorSelection(obj: text, position: 6)
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_world), 6)

        try doc.spliceText(obj: text, start: 6, delete: 0, value: "wonderful ")
        XCTAssertEqual(try! doc.text(obj: text), "hello wonderful world!")
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_hello), 0)
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_world), 16)

        try doc.spliceText(obj: text, start: 0, delete: 5, value: "Greetings")
        XCTAssertEqual(try! doc.text(obj: text), "Greetings wonderful world!")
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_hello), 9)
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_world), 20)
        XCTAssertEqual(try! doc.cursorPositionAt(obj: text, cursor: c_world, heads: heads), 6)

        // let's time travel with cursor
        let c_heads_world = try! doc.cursorSelectionAt(obj: text, position: 6, heads: heads)
        XCTAssertEqual(try! doc.cursorPosition(obj: text, cursor: c_heads_world), 20)
        XCTAssertEqual(c_heads_world.description, c_world.description)
    }

    func testCursorAtEndDocument() throws {
        let doc = Document(textEncoding: .graphemeCluster)
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        let c_hello = try! doc.cursorSelection(obj: text, position: doc.length(obj: text))
        try doc.spliceText(obj: text, start: doc.length(obj: text), delete: 0, value: "🏡🧑‍🧑‍🧒‍🧒")

        let position = try! doc.cursorPosition(obj: text, cursor: c_hello)
        XCTAssertEqual(position, UInt64("hello world!🏡🧑‍🧑‍🧒‍🧒".count))
    }

    func testRepeatedTextInsertion() throws {
        let characterCollection: [String] =
            "a bcdef ghijk lmnop qrstu vwxyz ABCD EFGHI JKLMN OPQRS TUVWX YZ😀😎🤓⚁ ♛⛺︎🕰️⏰⏲️ ⏱️🧭".map { char in
                String(char)
            }

        let doc = Automerge.Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        var stringLength = doc.length(obj: text)
        XCTAssertEqual(stringLength, 0)

        for _ in 0 ... 5000 {
            let stringToInsert = characterCollection.randomElement() ?? " "
            stringLength = doc.length(obj: text)
            // print("Adding '\(stringToInsert)' at \(stringLength)")
            try! doc.spliceText(obj: text, start: stringLength, delete: 0, value: stringToInsert)
            // print("Combined text: \(try doc.text(obj: text))")
        }

        // flaky assertion, don't do it :: because length is in UTF-8 codepoints, not!!! grapheme clusters.
        // XCTAssertEqual(stringLength, 5)
    }
}
