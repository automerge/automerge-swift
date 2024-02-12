import Automerge
import AutomergeUtilities
import XCTest

class UtilityTests: XCTestCase {
    func testIsEmpty() throws {
        let doc = Document()
        XCTAssertTrue(try doc.isEmpty())

        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        XCTAssertFalse(try doc.isEmpty())
    }

    func testVerySimpleWalkSchema() throws {
        let doc = Document()
        let _ = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        let schema = try doc.schema()
        // print(schema.description)
        XCTAssertEqual(schema.description, "{[\"text\": T{}]}")
    }

    func testWalkSchema() throws {
        let doc = Document()
        let enc = AutomergeEncoder(doc: doc)
        try enc.encode(Samples.layered)

        let schema = try doc.schema()
        print(schema.description)
    }
}
