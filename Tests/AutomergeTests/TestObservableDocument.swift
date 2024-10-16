#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
import Automerge
import Combine
import XCTest

class ObservableDocumentTestCase: XCTestCase {
    func testCountingUpdatesReceivedWhileUpdatingDocument() throws {
        let doc = Document()

        var countOfWillChangeUpdates = 0
        let willChangeHandle = doc.objectWillChange.sink {
            countOfWillChangeUpdates += 1
        }

        var countOfDidChangeUpdates = 0
        let didChangeHandle = doc.objectDidChange.sink {
            countOfDidChangeUpdates += 1
        }

        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        XCTAssertEqual(countOfWillChangeUpdates, 1)
        XCTAssertEqual(countOfDidChangeUpdates, 1)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertEqual(countOfWillChangeUpdates, 2)
        XCTAssertEqual(countOfDidChangeUpdates, 2)
        XCTAssertEqual(try! doc.text(obj: text), "hello world!")
        XCTAssertEqual(countOfWillChangeUpdates, 2)
        XCTAssertEqual(countOfDidChangeUpdates, 2)
        XCTAssertNotNil(willChangeHandle)
        XCTAssertNotNil(didChangeHandle)
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
        let willChangeHandle = doc.objectWillChange.sink {
            stashedHeads = doc.heads()
        }
        XCTAssertNotNil(willChangeHandle)

        let didChangeHandle = doc.objectDidChange.sink {
            _ = doc.heads()
        }
        XCTAssertNotNil(didChangeHandle)

        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hello world!")
        XCTAssertNotEqual(doc.heads(), stashedHeads)
    }
}
#endif
