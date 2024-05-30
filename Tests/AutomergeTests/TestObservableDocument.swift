import Automerge
import Combine
import XCTest

class ObservableDocumentTestCase: XCTestCase {
    func testCountingUpdatesReceivedWhileUpdatingDocument() throws {
        let doc = Document()

        var countOfUpdates = 0
        let collection = doc.objectWillChange.sink {
            countOfUpdates += 1
        }

        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        XCTAssertEqual(countOfUpdates, 1)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(countOfUpdates, 2)
        XCTAssertEqual(try! doc.text(obj: text), "hello world!")
        XCTAssertEqual(countOfUpdates, 2)
        XCTAssertNotNil(collection)
    }

    func testObjectWillChangeCallEnabledPriorToChange() async throws {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)

        // In earlier Automerge code, this test could crash, not fail - because
        // the objectWillChange call was invoked from within the synchronous DispatchQueue
        // which didn't allow simultaneous access to the document while it was in play.
        //
        // As such, this test verifies that you _can_ do that, and that the heads captured
        // in the sink (outside of debounce or other temporal delays) are different from the
        // heads _after_ the change.
        var stashedHeads: Set<ChangeHash> = []
        let collection = doc.objectWillChange.sink {
            stashedHeads = doc.heads()
        }
        XCTAssertNotNil(collection)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertNotEqual(doc.heads(), stashedHeads)
    }
}
