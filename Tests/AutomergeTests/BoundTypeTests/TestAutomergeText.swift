import Automerge
import XCTest

class AutomergeTextTestCase: XCTestCase {
    func testTextInitializer() throws {
        let doc = Document()
        let text = try AutomergeText("Hello World!", doc: doc, path: "text")
        XCTAssertTrue(text.isBound)
        let docValue = try doc.get(obj: ObjId.ROOT, key: "text")
        guard case let .Object(textId, .Text) = docValue else {
            XCTFail("value retrieved: \(String(describing: docValue)) isn't text")
            return
        }
        XCTAssertEqual(try! doc.text(obj: textId), "Hello World!")
    }

    func testEmojiTextInitializationWithSpliceText() throws {
        let doc = Document()
        // the schema in the document needs to exist before you can bind
        // AutomergeText
        let setuptextId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: setuptextId, start: 0, delete: 0, value: "🇬🇧👨‍👨‍👧‍👦😀")

        let text = try AutomergeText("🇬🇧👨‍👨‍👧‍👦😀", doc: doc, path: "text")
        XCTAssertTrue(text.isBound)
        let docValue = try doc.get(obj: ObjId.ROOT, key: "text")
        guard case let .Object(textId, .Text) = docValue else {
            XCTFail("value retrieved: \(String(describing: docValue)) isn't text")
            return
        }
        XCTAssertEqual(try! doc.text(obj: textId), "🇬🇧👨‍👨‍👧‍👦😀")
    }

    func testEmojiTextInitializationWithAutomergeText() throws {
        let doc = Document()
        // the schema in the document needs to exist before you can bind
        // AutomergeText
        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

        let text = try AutomergeText("🇬🇧👨‍👨‍👧‍👦😀", doc: doc, path: "text")
        XCTAssertTrue(text.isBound)
        let docValue = try doc.get(obj: ObjId.ROOT, key: "text")
        guard case let .Object(textId, .Text) = docValue else {
            XCTFail("value retrieved: \(String(describing: docValue)) isn't text")
            return
        }
        XCTAssertEqual(try! doc.text(obj: textId), "🇬🇧👨‍👨‍👧‍👦😀")
    }

    func testTextUpdating() throws {
        let doc = Document()
        // the schema in the document needs to exist before you can bind
        // AutomergeText
        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let text = try AutomergeText("🇬🇧👨‍👨‍👧‍👦😀", doc: doc, path: "text")
        XCTAssertTrue(text.isBound)
        text.value = "🇬🇧😀"

        let docValue = try doc.get(obj: ObjId.ROOT, key: "text")
        guard case let .Object(textId, .Text) = docValue else {
            XCTFail("value retrieved: \(String(describing: docValue)) isn't text")
            return
        }
        XCTAssertEqual(try! doc.text(obj: textId), "🇬🇧😀")
    }
}
