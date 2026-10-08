@testable import Automerge
import XCTest

/// Asserts that an expression throws the document error for the wrong object type.
private func assertThrowsWrongObjectType<T>(
    _ expression: @autoclosure () throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertThrowsError(try expression(), file: file, line: line) { error in
        guard let docError = error as? DocError, case .WrongObjectType = docError.inner else {
            return XCTFail("Expected WrongObjectType, got \(error)", file: file, line: line)
        }
    }
}

class GetTextElementsTestCase: XCTestCase {
    func testGetTextElements() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "hé😀")

        XCTAssertEqual(try doc.get(obj: text, index: 0), .Scalar(.String("h")))
        XCTAssertEqual(try doc.get(obj: text, index: 1), .Scalar(.String("é")))
        XCTAssertEqual(try doc.get(obj: text, index: 2), .Scalar(.String("😀")))
        XCTAssertNil(try doc.get(obj: text, index: 3))
        XCTAssertEqual(try doc.getAll(obj: text, index: 2), [.Scalar(.String("😀"))])
    }

    func testGetTextElementsCountInTheTextEncoding() throws {
        let doc = Document(textEncoding: .utf16)
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "a😀b")

        XCTAssertEqual(try doc.get(obj: text, index: 0), .Scalar(.String("a")))
        // Both halves of the surrogate pair return the whole character.
        XCTAssertEqual(try doc.get(obj: text, index: 1), .Scalar(.String("😀")))
        XCTAssertEqual(try doc.get(obj: text, index: 2), .Scalar(.String("😀")))
        XCTAssertEqual(try doc.get(obj: text, index: 3), .Scalar(.String("b")))
        XCTAssertNil(try doc.get(obj: text, index: 4))
    }

    func testGetTextElementsAtHeads() throws {
        let doc = Document()
        let text = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: text, start: 0, delete: 0, value: "abc")
        let heads = doc.heads()
        try doc.spliceText(obj: text, start: 0, delete: 1, value: "x")

        XCTAssertEqual(try doc.get(obj: text, index: 0), .Scalar(.String("x")))
        XCTAssertEqual(try doc.getAt(obj: text, index: 0, heads: heads), .Scalar(.String("a")))
        XCTAssertEqual(try doc.getAllAt(obj: text, index: 0, heads: heads), [.Scalar(.String("a"))])
    }

    func testGetByIndexStillRefusesMaps() throws {
        let doc = Document()
        let map = try doc.putObject(obj: ObjId.ROOT, key: "map", ty: .Map)
        try doc.put(obj: map, key: "a", value: .String("b"))
        let heads = doc.heads()

        assertThrowsWrongObjectType(try doc.get(obj: map, index: 0))
        assertThrowsWrongObjectType(try doc.getAll(obj: map, index: 0))
        assertThrowsWrongObjectType(try doc.getAt(obj: map, index: 0, heads: heads))
        assertThrowsWrongObjectType(try doc.getAllAt(obj: map, index: 0, heads: heads))
    }
}
