@testable import Automerge
import XCTest

final class Document_PathTests: XCTestCase {
    func testLookupPath() throws {
        let doc = Document()
        let list = try! doc.putObject(obj: ObjId.ROOT, key: "list", ty: .List)
        let nestedMap = try! doc.insertObject(obj: list, index: 0, ty: .Map)
        let deeplyNestedText = try! doc.putObject(obj: nestedMap, key: "notes", ty: .Text)

        let result = try XCTUnwrap(doc.lookupPath(path: ""))
        XCTAssertEqual(result, ObjId.ROOT)

        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: "")))
        XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: ".")))
        XCTAssertNil(try doc.lookupPath(path: "a"))
        XCTAssertNil(try doc.lookupPath(path: "a."))
        XCTAssertEqual(try doc.lookupPath(path: "list"), list)
        XCTAssertEqual(try doc.lookupPath(path: ".list"), list)
        XCTAssertNil(try doc.lookupPath(path: "list.[1]"))

        XCTAssertThrowsError(try doc.lookupPath(path: ".list.[5]"), "Index Out of Bounds should throw an error")
        // The top level object isn't a list - so an index lookup should fail with an error
        XCTAssertThrowsError(try doc.lookupPath(path: "[1].a"))

        // XCTAssertEqual(ObjId.ROOT, try XCTUnwrap(doc.lookupPath(path: "1.a")))
        // threw error "DocError(inner: AutomergeUniffi.DocError.WrongObjectType(message: "WrongObjectType"))"
        XCTAssertEqual(try doc.lookupPath(path: "list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath(path: ".list.[0]"), nestedMap)
        XCTAssertEqual(try doc.lookupPath(path: "list.[0].notes"), deeplyNestedText)
        XCTAssertEqual(try doc.lookupPath(path: ".list.[0].notes"), deeplyNestedText)
    }
}
