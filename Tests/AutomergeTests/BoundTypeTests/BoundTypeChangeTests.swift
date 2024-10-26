#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
@testable import Automerge
import XCTest

class BoundTypeChangeTests: XCTestCase {
    func testTextChangeNotification() async throws {
        let doc1 = Document()
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

    func testLocalizedTextChangeNotification() async throws {
        let doc1 = Document()
        try doc1.put(obj: ObjId.ROOT, key: "counter", value: .Counter(0))
        let counter = try Counter(0, doc: doc1, path: "counter")
        let text1 = try AutomergeText("hello", doc: doc1, path: "text1")

        let textChangeNotification =
            expectation(description: "text1 should send an objectWillChange signal on an update to the document")
        var alreadyFulfilled = false
        let text_change = text1.objectWillChange.sink { _ in
            if !alreadyFulfilled {
                textChangeNotification.fulfill()
                alreadyFulfilled = true
            }
        }
        XCTAssertNotNil(text_change)
        let counter_change = counter.objectWillChange.sink { _ in
            XCTFail("No change notification should occur for counter while Text is updated")
        }
        XCTAssertNotNil(counter_change)
        let txt1ObjId = try XCTUnwrap(text1.objId)
        try doc1.updateText(obj: txt1ObjId, value: "Hello World!")

        await fulfillment(of: [textChangeNotification], timeout: 1.0, enforceOrder: false)
    }
}
#endif
