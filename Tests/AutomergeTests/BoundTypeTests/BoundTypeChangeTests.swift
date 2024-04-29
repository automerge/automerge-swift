@testable import Automerge
import XCTest

class BoundTypeChangeTests: XCTestCase {
    func testTextChangeNotification() async throws {
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))
        let text1 = try AutomergeText("hello", doc: doc1, path: "text1")

        let textChangeNotification =
            expectation(description: "text1 should send an objectWillChange signal on an update to the document")
        var alreadyFulfilled = false
        let xx = text1.objectWillChange.sink { _ in
            if !alreadyFulfilled {
                textChangeNotification.fulfill()
                alreadyFulfilled = true
            }
        }
        XCTAssertNotNil(xx)
        let txt1ObjId = try XCTUnwrap(text1.objId)
        try doc1.updateText(obj: txt1ObjId, value: "Hello World!")

        await fulfillment(of: [textChangeNotification], timeout: 1.0, enforceOrder: false)
    }
}
