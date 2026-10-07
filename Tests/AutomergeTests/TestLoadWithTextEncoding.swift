import Automerge
import XCTest

final class TestLoadWithTextEncoding: XCTestCase {
    let encodings: [TextEncoding] = [.unicodeScalar, .utf8, .utf16, .graphemeCluster]

    /// Creates a document whose text has characters of different widths in every encoding, and a mark over "Æbler".
    func makeDocument(_ encoding: TextEncoding) throws -> (Document, ObjId) {
        let doc = Document(textEncoding: encoding)
        let text = try doc.putObject(obj: .ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "🇩🇰 Æbler. Pærer.")
        let start = UInt64(doc.length(obj: text)) - UInt64(width("Æbler. Pærer.", encoding))
        try doc.mark(
            obj: text,
            start: start,
            end: start + UInt64(width("Æbler", encoding)),
            expand: .none,
            name: "note",
            value: .String("n")
        )
        return (doc, text)
    }

    func width(_ string: String, _ encoding: TextEncoding) -> Int {
        switch encoding {
        case .utf8: return string.utf8.count
        case .utf16: return string.utf16.count
        case .unicodeScalar: return string.unicodeScalars.count
        case .graphemeCluster: return string.count
        }
    }

    func testLoadKeepsEachEncoding() throws {
        for encoding in encodings {
            let (doc, text) = try makeDocument(encoding)
            let loaded = try Document(doc.save(), textEncoding: encoding)
            XCTAssertEqual(loaded.textEncoding, encoding)
            XCTAssertEqual(loaded.length(obj: text), doc.length(obj: text), "\(encoding)")
            XCTAssertEqual(try loaded.marks(obj: text), try doc.marks(obj: text), "\(encoding)")
        }
    }

    func testLoadedUTF16PositionsMatchNSString() throws {
        let (doc, text) = try makeDocument(.utf16)
        let loaded = try Document(doc.save(), textEncoding: .utf16)
        let string = try NSString(string: loaded.text(obj: text))
        let mark = try XCTUnwrap(loaded.marks(obj: text).first { $0.name == "note" })
        let range = NSRange(location: Int(mark.start), length: Int(mark.end - mark.start))
        XCTAssertEqual(string.substring(with: range), "Æbler")

        // An edit at a UTF-16 position moves the mark by the inserted text's UTF-16 length.
        try loaded.spliceText(obj: text, start: mark.start, delete: 0, value: "Røde ")
        let moved = try XCTUnwrap(loaded.marks(obj: text).first { $0.name == "note" })
        XCTAssertEqual(moved.start, mark.start + 5)
        XCTAssertEqual(moved.end, mark.end + 5)
    }

    func testLoadWithoutEncodingUsesTheDefault() throws {
        let (doc, text) = try makeDocument(.utf16)
        let loaded = try Document(doc.save())
        XCTAssertEqual(loaded.textEncoding, .unicodeScalar)
        // The flag is four UTF-16 code units but two Unicode scalars.
        XCTAssertEqual(doc.length(obj: text) - loaded.length(obj: text), 2)
    }

    func testForksKeepTheEncoding() throws {
        for encoding in encodings {
            let (doc, text) = try makeDocument(encoding)
            let heads = doc.heads()
            try doc.spliceText(obj: text, start: 0, delete: 0, value: "🇸🇪 ")

            let fork = doc.fork()
            XCTAssertEqual(fork.textEncoding, encoding)
            XCTAssertEqual(fork.length(obj: text), doc.length(obj: text), "\(encoding)")

            let forkAt = try doc.forkAt(heads: heads)
            XCTAssertEqual(forkAt.textEncoding, encoding)
            XCTAssertEqual(try forkAt.marks(obj: text), try doc.marksAt(obj: text, heads: heads), "\(encoding)")
            XCTAssertEqual(forkAt.heads(), heads)
            XCTAssertNotEqual(forkAt.actor, doc.actor)
        }
    }
}
