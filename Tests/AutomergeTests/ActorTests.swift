@testable import Automerge
import XCTest

class ActorTests: XCTestCase {
    func testDefaultActorSize() {
        let doc1 = Document()
        XCTAssertEqual(doc1.actor.bytes.count, 16)
    }
}

