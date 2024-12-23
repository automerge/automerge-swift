import Automerge
import XCTest

class WasmIntegriy: XCTestCase {
    func testTextValueEncodingBetweenPlatforms() throws {
        let doc = Document()
        let textId = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)

        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "🇬🇧")
        try doc.spliceText(obj: textId, start: UInt64("🇬🇧".unicodeScalars.count), delete: 0, value: "a")
        let content = try doc.text(obj: textId)

        XCTAssertEqual(content, "🇬🇧a")
    }
}
