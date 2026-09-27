import Automerge
import XCTest

final class TestLoadWithTextEncoding: XCTestCase {
    func testLoadKeepsUTF16Positions() throws {
        let doc = Document(textEncoding: .utf16)
        let text = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🇩🇰 Æbler. Pærer.")
        // The flag is 4 UTF-16 code units, so "Æbler. " spans 5..<12.
        try doc.mark(obj: text, start: 5, end: 12, expand: .none, name: "note", value: .String("n"))

        let loaded = try Document(doc.save(), textEncoding: .utf16)
        XCTAssertEqual(loaded.textEncoding, .utf16)
        let mark = try XCTUnwrap(loaded.marks(obj: text).first { $0.name == "note" })
        XCTAssertEqual(mark.start, 5)
        XCTAssertEqual(mark.end, 12)

        try loaded.spliceText(obj: text, start: 5, delete: 0, value: "Røde ")
        let moved = try XCTUnwrap(loaded.marks(obj: text).first { $0.name == "note" })
        XCTAssertEqual(moved.start, 10)
        XCTAssertEqual(moved.end, 17)
    }

    func testLoadWithoutEncodingUsesDefault() throws {
        let doc = Document(textEncoding: .utf16)
        _ = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)
        let loaded = try Document(doc.save())
        XCTAssertEqual(loaded.textEncoding, .unicodeScalar)
    }
}
