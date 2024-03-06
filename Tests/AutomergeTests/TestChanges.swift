import Automerge
import XCTest

class ChangeSetTests: XCTestCase {
    func testHeadsForNewDoc() {
        let doc = Document()

        // verify new document has an empty set of changes
        let heads = doc.heads()
        XCTAssertTrue(heads.isEmpty)
    }

    func testIncrChangesForNewDoc() throws {
        let doc = Document()

        // verify new document has an empty set of changes
        let updates = try doc.encodeChangesSince(heads: Set<ChangeHash>())
        XCTAssertTrue(updates.isEmpty)
    }

    func testIncrementalLoadEmptySet() throws {
        let doc = Document()
        let bytes = doc.save()
        try doc.applyEncodedChanges(encoded: Data())

        let heads = doc.heads()
        XCTAssertTrue(heads.isEmpty)

        // verify no-op
        let data = doc.save()
        XCTAssertEqual(bytes, data)
        print(data.hexEncodedString())
    }
}
