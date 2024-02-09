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
}
