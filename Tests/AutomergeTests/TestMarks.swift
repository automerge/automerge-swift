@testable import Automerge
import XCTest

class MarksTestCase: XCTestCase {
    func testCrudMarks() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: ObjType.Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello marks")
        try! doc.mark(
            obj: text,
            start: 0,
            end: 5,
            expand: ExpandMark.none,
            name: "bold",
            value: ScalarValue.Boolean(true)
        )
        let marks = try! doc.marks(obj: text)
        let expectedMarks = [
            Mark(start: 0, end: 5, name: "bold", value: ScalarValue.Boolean(true)),
        ]
        XCTAssertEqual(marks, expectedMarks)

        // save the heads to use later in marksAt
        let heads = doc.heads()

        // Now remove the mark
        try! doc.mark(obj: text, start: 0, end: 5, expand: ExpandMark.none, name: "bold", value: ScalarValue.Null)
        let marksAfterDelete = try! doc.marks(obj: text)
        XCTAssertEqual(marksAfterDelete.count, 0)

        // Now check that marksAt still returns the marks
        let marksAt = try! doc.marksAt(obj: text, heads: heads)
        XCTAssertEqual(marksAt, expectedMarks)
    }

    func testMarkPatches() {
        let doc = Document()
        let text = try! doc.putObject(obj: ObjId.ROOT, key: "text", ty: ObjType.Text)
        try! doc.spliceText(obj: text, start: 0, delete: 0, value: "Hello marks")

        // Make the marks on a fork so we can see the marks in patches when we merge
        let fork = doc.fork()
        try! fork.mark(
            obj: text,
            start: 0,
            end: 5,
            expand: ExpandMark.none,
            name: "bold",
            value: ScalarValue.Boolean(true)
        )
        let patches = try! doc.mergeWithPatches(other: fork)
        let expectedMarks = [
            Mark(start: 0, end: 5, name: "bold", value: ScalarValue.Boolean(true)),
        ]
        XCTAssertEqual(patches, [Patch(
            action: .Marks(text, expectedMarks),
            path: [PathElement(obj: ObjId.ROOT, prop: .Key("text"))]
        )])

        // Now splice some text in the fork and make sure the splice patch contains the marks
        try! fork.spliceText(obj: text, start: 4, delete: 0, value: "oo")
        let patchesAfterSplice = try! doc.mergeWithPatches(other: fork)
        XCTAssertEqual(patchesAfterSplice, [Patch(
            action: .SpliceText(obj: text, index: 4, value: "oo", marks: ["bold": .Scalar(.Boolean(true))]),
            path: [PathElement(obj: ObjId.ROOT, prop: .Key("text"))]
        )])
    }

    func testMarksAtIndex() throws {
        let doc = Document()
        let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello World!")
        try doc.mark(obj: textId, start: 2, end: 5, expand: .both, name: "italic", value: .Boolean(true))
        try doc.mark(obj: textId, start: 1, end: 5, expand: .both, name: "bold", value: .Boolean(true))

        let marks = try doc.marksAt(obj: textId, position: .index(2))

        XCTAssertEqual(marks, [
            Mark(start: 2, end: 2, name: "bold", value: .Boolean(true)),
            Mark(start: 2, end: 2, name: "italic", value: .Boolean(true)),
        ])
    }

    func testMarksAtCursor() throws {
        let doc = Document()
        let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello World!")
        try doc.mark(obj: textId, start: 2, end: 5, expand: .both, name: "italic", value: .Boolean(true))
        try doc.mark(obj: textId, start: 1, end: 5, expand: .both, name: "bold", value: .Boolean(true))

        let cursor = try doc.cursor(obj: textId, position: 2)
        let marks = try doc.marksAt(obj: textId, position: .cursor(cursor))

        XCTAssertEqual(marks, [
            Mark(start: 2, end: 2, name: "bold", value: .Boolean(true)),
            Mark(start: 2, end: 2, name: "italic", value: .Boolean(true)),
        ])
    }

    func testMarksAtCursorFromAnotherDocumentThrows() throws {
        let doc = Document()
        let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")

        let otherDoc = Document()
        let otherTextId = try otherDoc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try otherDoc.spliceText(obj: otherTextId, start: 0, delete: 0, value: "Hello World!")
        let foreignCursor = try otherDoc.cursor(obj: otherTextId, position: 8)

        // Previously a Rust panic, surfaced as an internal UniFFI error rather than a DocError.
        XCTAssertThrowsError(try doc.marksAt(obj: textId, position: .cursor(foreignCursor))) { error in
            XCTAssertTrue(error is DocError, "expected DocError, got \(error)")
        }
    }

    func testMarksAtCursorWithHeadsBeforeCursorExistedThrows() throws {
        let doc = Document()
        let textId = try doc.putObject(obj: ObjId.ROOT, key: "text", ty: .Text)
        try doc.spliceText(obj: textId, start: 0, delete: 0, value: "Hello")
        let headsBeforeCursor = doc.heads()

        try doc.spliceText(obj: textId, start: 5, delete: 0, value: " World!")
        let cursor = try doc.cursor(obj: textId, position: 8)

        XCTAssertThrowsError(
            try doc.marksAt(obj: textId, position: .cursor(cursor), heads: headsBeforeCursor)
        ) { error in
            XCTAssertTrue(error is DocError, "expected DocError, got \(error)")
        }
    }
}
